{ pkgs, lib, config, ... }:

# jj (Jujutsu): git 互換 DVCS。
# - declarative 部分は programs.jujutsu.settings (HM が ~/.config/jj/config.toml を生成、read-only symlink)
# - identity / signing key は ~/.config/jj/local.toml に分離（home/programs/git.nix の config.local と同型）
# - JJ_CONFIG をディレクトリモードにして config.toml + local.toml を辞書順マージ（後勝ち）
# - TUI = jjui (2025-2026 最有力)
# - fish 補完は jj 自身が動的補完を内包しているため HM の enableFishIntegration は廃止済（不要）

{
  programs.jujutsu = {
    enable = true;
    settings = {
      ui = {
        # 引数なしで起動した時に log を 10 件表示（標準は単に "log" 全件）
        default-command = [ "log" "--limit" "10" ];
        # delta が解釈できる git diff 形式（:color-words だと delta と非互換）
        diff-formatter  = ":git";
        # 既存 git+delta と統一（delta は非 diff 出力もそのままパススルーする）
        pager           = "delta";
        # programs.git.settings.core.editor = "nvim" と一致
        editor          = "nvim";
        # jj prev/next が --edit 相当に。stack 編集の体験が改善
        movement.edit   = true;
      };

      git = {
        # push 時のみ署名する（作業中の都度署名はスキップして割り込みを最小化）
        sign-on-push    = true;
        # "wip:*" prefix の commit を push ガード（誤 push の安全弁）
        private-commits = "description(glob:'wip:*')";
        # fetch 時に remote bookmark から ローカル bookmark を自動生成しない
        # （colocated repo で他人のブランチが一斉にローカルに落ちて lazygit/git branch が
        #  汚染されるのを防ぐ）。明示的に track したい時のみ `jj bookmark track` を使う。
        auto-local-bookmark = false;
      };

      signing = {
        # 既存 SSH 鍵（~/.ssh/id_ed25519*）を再利用、GPG 鍵管理を増やさない
        backend  = "ssh";
        # rewrite 時に署名を保持しない。push-on-sign で再署名されるので問題なし
        behavior = "drop";
        # signing.key は public 鍵パスで host ごとに異なるため local.toml 側で指定
      };

      aliases = {
        # 作業ブランチ周辺を log（trunk から @ までと、@ の子孫）
        l   = [ "log" "-r" "(trunk()..@):: | (trunk()..@)-" ];
        ll  = [ "log" "--limit" "20" ];
        r   = [ "log" "-r" "::@ & conflicts()" ];
        s   = [ "status" ];
        si  = [ "squash" "--interactive" ];
        # 直近 bookmark を @- に追従（作業 commit を進めた後に bookmark を進める頻出操作）
        tug = [ "bookmark" "move" "--from" "closest_bookmark(@-)" "--to" "@-" ];
        # @ から遡って最も近い bookmark 名を改行区切りで出力（"今どのブランチに乗っているか" 確認用）
        on  = [ "log" "-r" "heads(::@ & bookmarks())" "--no-graph" "-T" "bookmarks ++ \"\\n\"" ];
      };

      # revset-aliases / template-aliases は識別子に () を含むため key を quote
      revset-aliases = {
        # 既定 builtin_immutable_heads() より保守的: trunk + tags + remote bookmarks のみ immutable
        "immutable_heads()" = "present(trunk()) | tags() | remote_bookmarks()";
        # 現在の作業 stack（mutable な祖先を遡る）
        "stack()"           = "ancestors(reachable(@, mutable()), 10)";
        # `to` から遡って最も近い bookmark を返す。`tug` alias から参照される。
        # heads(::to & bookmarks()) = (to の祖先 ∩ bookmark) の先端
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
      };

      template-aliases = {
        # log の change-id を最短ユニーク prefix で表示
        "format_short_change_id(id)" = "id.shortest()";
      };
    };
  };

  # TUI: jjui (2026 時点で最も活発な jj TUI)
  home.packages = [ pkgs.jjui ];

  # jjui 設定（~/.config/jjui/config.toml）。programs.* モジュール非対応なので
  # xdg.configFile で declare。Lua の function setup(config) 形式ではなく、docs の
  # Minimal Example が示す TOML inline 形式 ([[actions]] + [[bindings]]) で統一して
  # 設定ファイルを 1 本にまとめる（lua = ''' ... ''' に Lua スニペットを埋め込む）。
  #
  # 設計メモ:
  # - jjui の preview commands は `jj <args>` として exec される（jjui ソース: preview.go:
  #   RunCommandImmediateWithEnv → exec.Command("jj", args...)）。シェルパイプは使えないので
  #   `jj util exec -- bash -c "..."` で bash サブプロセスを起こす。
  # - placeholder（$change_id / $file 等）は jjui 側で各 arg 文字列に対し strings.ReplaceAll で
  #   置換される（templated_args.go: TemplatedArgs）。よって bash -c の文字列内で参照できる
  #   （bash の env var として解決されるのではない）。
  # - delta は `--no-gitconfig` で git.nix 側の [delta] 既定（side-by-side / navigate / line-numbers）
  #   を完全リセットしてから、preview に必要なものだけ CLI で opt-in する。
  #   理由: delta 0.19.2 の `[delta "feature"]` 機構は paging のような string 値は反映するが、
  #   `side-by-side = false` / `navigate = false` のような boolean 偽による base 上書きが効かず
  #   side-by-side が残って preview pane が左右分割→片側だけに diff が偏る不具合を踏む。
  #   `--no-gitconfig` ならその bug を回避できる。`--side-by-side=false` も `--no-side-by-side` も
  #   delta CLI には存在しないため、base を消す以外に side-by-side を off にする手段がない。
  # - COLUMNS/LINES が preview pane サイズに set されるので幅は delta が自動追従。
  # - `d` (revisions scope) は jjui 既定の内蔵 diff viewer (revisions.diff action) を上書きして
  #   外部 delta launcher に差し替える。理由: 内蔵 viewer は `jj diff --color always --ignore-working-copy`
  #   の生出力を直接表示するだけで delta を介在させるフックが存在しないため（jjui ソース:
  #   revisions.go:showDiff → context.RunCommandImmediate → exec.Command("jj", ...)）。
  #   delta 経由で見たい場合は binding を奪うのが唯一の道。
  #   内蔵 viewer を残したくなったら `key = "ctrl+d"` 等に逃がす binding を追記する。
  xdg.configFile."jjui/config.toml".text = ''
    [preview]
    revision_command = [
      "util", "exec", "--",
      "bash", "-c",
      "jj show --color=always --git -r $change_id | delta --no-gitconfig --paging=never --line-numbers --plus-style='syntax #004466' --minus-style='syntax #660000' --plus-emph-style='syntax #0077B3' --minus-emph-style='syntax #B30000' --line-numbers-plus-style='#0077B3' --line-numbers-minus-style='#B30000'",
    ]
    file_command = [
      "util", "exec", "--",
      "bash", "-c",
      "jj diff --color=always --git -r $change_id -- $file | delta --no-gitconfig --paging=never --line-numbers --plus-style='syntax #004466' --minus-style='syntax #660000' --plus-emph-style='syntax #0077B3' --minus-emph-style='syntax #B30000' --line-numbers-plus-style='#0077B3' --line-numbers-minus-style='#B30000'",
    ]

    [[actions]]
    name = "show-diff-in-delta"
    lua = """
    local change_id = context.change_id()
    if not change_id or change_id == "" then
      flash({ text = "No revision selected", error = true })
      return
    end
    -- delta --pager に明示的に less --mouse を渡してマウススクロールを有効化。
    -- delta は内部 pager に -R/--no-init/--quit-if-one-screen は付けるが --mouse は
    -- 付けないため、ここで上書き指定する（他経路の delta は影響を受けない）。
    -- 以前は -F -X を付けていたが、いずれも jjui の TUI と相性が悪く除外:
    --   -F (quit-if-one-screen): short diff だと less が即終了 → jjui 再描画で diff が一瞬で消える
    --   -X (no-init):            alt-screen に切替えないため、d 連打で前回 diff がメイン画面の
    --                             scrollback に残り、次の diff がその下に積まれる
    exec_shell(string.format(
      "jj diff -r %q --git --color=always | delta --pager 'less -R --mouse'",
      change_id
    ))
    """

    [[bindings]]
    action = "show-diff-in-delta"
    key    = "d"
    scope  = "revisions"
    desc   = "show diff in delta"
  '';

  # JJ_CONFIG をディレクトリにすると配下の *.toml を辞書順 merge（後勝ち）。
  # config.toml (HM 生成、'c') の後に local.toml ('l') が読まれて [user]/[signing.key] を上書きする。
  home.sessionVariables.JJ_CONFIG = "${config.home.homeDirectory}/.config/jj";

  # ~/.config/jj/local.toml を冪等 bootstrap（home/programs/git.nix:bootstrapGitLocalConfig と同型）。
  # 既存ファイルがあれば上書きしない。dotfiles repo 外、git untracked。
  home.activation.bootstrapJujutsuLocalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    LOCAL_CFG="$HOME/.config/jj/local.toml"
    if [ ! -f "$LOCAL_CFG" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$LOCAL_CFG")"
      cat > "$LOCAL_CFG" <<'EOF'
# default jj identity & signing key (host-specific, out-of-repo, NOT tracked).
# JJ_CONFIG=$HOME/.config/jj （directory mode）で config.toml の後に load される。
[user]
  # name  = "your-name"
  # email = "your-email@example.com"

[signing]
  # key = "~/.ssh/id_ed25519.pub"  # 公開鍵パス。SSH backend が allowed_signers を生成
EOF
      $DRY_RUN_CMD chmod 600 "$LOCAL_CFG"
      echo "jj/local.toml template created at $LOCAL_CFG (please fill user.name / user.email / signing.key)"
    fi
  '';
}
