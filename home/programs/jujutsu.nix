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
        sign-on-push       = true;
        # --allow-new フラグなしで新規 bookmark を push 可（jj 0.25+）
        push-new-bookmarks = true;
        # "wip:*" prefix の commit を push ガード（誤 push の安全弁）
        private-commits    = "description(glob:'wip:*')";
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
        s   = [ "status" ];
        si  = [ "squash" "--interactive" ];
        # 直近 bookmark を @- に追従（作業 commit を進めた後に bookmark を進める頻出操作）
        tug = [ "bookmark" "move" "--from" "closest_bookmark(@-)" "--to" "@-" ];
      };

      # revset-aliases / template-aliases は識別子に () を含むため key を quote
      revset-aliases = {
        # 既定 builtin_immutable_heads() より保守的: trunk + tags + remote bookmarks のみ immutable
        "immutable_heads()" = "present(trunk()) | tags() | remote_bookmarks()";
        # 現在の作業 stack（mutable な祖先を遡る）
        "stack()"           = "ancestors(reachable(@, mutable()), 10)";
      };

      template-aliases = {
        # log の change-id を最短ユニーク prefix で表示
        "format_short_change_id(id)" = "id.shortest()";
      };
    };
  };

  # TUI: jjui (2026 時点で最も活発な jj TUI)
  home.packages = [ pkgs.jjui ];

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
