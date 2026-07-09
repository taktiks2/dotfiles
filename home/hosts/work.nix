{ pkgs, lib, config, ... }:

# work ホスト固有の差分。
# home/common.nix の baseline を override / extend する。

{
  # 追加 Nix パッケージ（bun, fnm は home/common.nix で配布済）。
  home.packages = with pkgs; [
    bandwhich
    eza
    gum
    httpie
    nushell
    p7zip
    poppler
    pv
    terminal-notifier
    vhs
    visidata
  ];

  # zoxide: cd jumper
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # /usr/local/bin: Apple Silicon Homebrew では PATH 外だが、cask の mysql-shell が
  # 公式 .pkg を /usr/local/mysql-shell/ に置き /usr/local/bin/mysqlsh を貼るため必要。
  # home/programs/fish.nix の sessionPath 補填ループが tmux 子 fish にも append し直すため、
  # ここに足すだけで反映される。
  home.sessionPath = [
    "/usr/local/bin"
  ];

  # fnm の `--use-on-cd` を本ホストでだけ有効化（home/common.nix では明示的に無効）。
  # 理由: 一部プロジェクトは flake.nix で fnm を介して Node を提供する設計のため、
  #       fish 側で .node-version の自動切替が必要。
  # 既知の副作用:
  #   - 未 install バージョンを要求するリポジトリで fnm がエラーを吐く
  #   - direnv で devShell の Node を刺している場合、fnm の PATH prepend で上書きされる
  programs.fish.interactiveShellInit = ''
    fnm env --use-on-cd --shell fish | source

    # hunk 同梱の Claude Code skill (hunk-review) を work プロファイルへ常時リンク。
    # 実体は fnm の node-versions/<ver>/ 配下にあり Node 更新でリンクが切れるため、
    # リンク切れ時のみ `hunk skill path`（node 起動で重い）を呼んで張り直す。
    # リンク正常時のコストは test 1 回分のみ。
    set -l hunk_skill_link ~/.claude-profiles/work/skills/hunk-review
    if not test -e $hunk_skill_link/SKILL.md; and command -q hunk
        set -l hunk_skill_dir (hunk skill path 2>/dev/null | path dirname)
        if test -d "$hunk_skill_dir"
            ln -sfn $hunk_skill_dir $hunk_skill_link
        end
    end
  '';

  # tmux: 業務用 lazyjira ポップアップ（prefix + J）。
  # programs.tmux.extraConfig は types.lines なので home/programs/tmux.nix の設定に連結される。
  programs.tmux.extraConfig = ''
    # lazyjira をポップアップで開く（prefix + J）
    bind J display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "lazyjira"
  '';

  # ghostty は main の programs.ghostty で十分（command/font/theme の差は
  # Nix 化後 /run/current-system/sw/bin/fish で動作するため override 不要）。

  # 社用 PC ではデフォルト identity = 社用アカウント (~/.config/git/config.local)。
  # taktiks2 所有 repo (dotfiles 等) は github-taktiks2 host alias 経由で taktiks2 identity に切替える。
  # 連携手順:
  #   1. darwin-rebuild switch  → ~/.ssh/config に Host github-taktiks2 が生成
  #                              + ~/.config/git/config に includeIf 行 + config.taktiks2 雛形が生成
  #   2. ./install.sh           → ~/.ssh/id_ed25519_taktiks2 を自動生成 (setup_ssh_keys)
  #   3. 公開鍵を taktiks2 GitHub アカに登録
  #   4. ~/.config/git/config.taktiks2 に taktiks2 identity (name/email) を手書き
  #   5. 対象 repo の remote URL を git@github-taktiks2:taktiks2/<repo>.git に切替
  #      (例: cd ~/dotfiles && git remote set-url origin git@github-taktiks2:taktiks2/dotfiles.git)
  my.git.extraIdentities.taktiks2 = {
    condition       = "hasconfig:remote.*.url:git@github-taktiks2:taktiks2/**";
    sshHostAlias    = "github-taktiks2";
    sshIdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519_taktiks2";
  };

  # このホストでだけ ignore したいパス。
  # home/programs/git.nix の programs.git.ignores と list merge される。
  programs.git.ignores = [
    ".claude/worktrees/"
    ".github/hooks/"
    "docs/.obsidian/"
    "sqls/"
    ".workmux.yaml"
  ];
}
