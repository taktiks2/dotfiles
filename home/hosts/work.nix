{ pkgs, lib, config, ... }:

# work ホスト固有の差分。
# home/common.nix の baseline を override / extend する。

{
  # 1. brew → Nix 移行する追加パッケージ
  #    （bun, fnm は home/common.nix に統合済のためここでは指定しない）
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

  # 2. zoxide: cd jumper
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # 3. PATH から ~/.nodebrew/current/bin を除去（fnm に統一）。
  #    /usr/local/bin は Apple Silicon Homebrew では PATH 外だが、
  #    cask の mysql-shell が公式 .pkg を /usr/local/mysql-shell/ に置き
  #    /usr/local/bin/mysqlsh シンボリックリンクを貼るため必要。
  #
  #    home.sessionPath は bash/zsh / sessionVariables 連動の互換用に残す。
  #    fish では home-manager 生成の hm-session-vars.fish が
  #    `set -gx PATH 'a:b:c:...'` と単一 POSIX 文字列で代入するため、
  #    fish 内 builtin の command lookup から /usr/local/bin が落ちる
  #    （特に tmux 子 fish）。そのため下の programs.fish.shellInit で
  #    fish ネイティブ list 形式に組み直す。
  home.sessionPath = lib.mkForce [
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "${config.home.homeDirectory}/Library/Android/sdk/platform-tools"
    "${config.home.homeDirectory}/Library/Android/sdk/emulator"
    "${config.home.homeDirectory}/bin"
    "/opt/homebrew/opt/mysql@8.0/bin"
    "${config.home.homeDirectory}/.composer/vendor/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.rbenv/shims"
  ];

  # 4.1 home.sessionPath を fish ネイティブ list 形式で再宣言。
  #     home/programs/fish.nix の shellInit が先に Nix profiles を最先頭に
  #     prepend するので、ここでは append (set -gx PATH $PATH $p) で
  #     Nix の最高優先を温存する。
  programs.fish.shellInit = ''
    for p in \
        /opt/homebrew/bin \
        /usr/local/bin \
        ${config.home.homeDirectory}/Library/Android/sdk/platform-tools \
        ${config.home.homeDirectory}/Library/Android/sdk/emulator \
        ${config.home.homeDirectory}/bin \
        /opt/homebrew/opt/mysql@8.0/bin \
        ${config.home.homeDirectory}/.composer/vendor/bin \
        ${config.home.homeDirectory}/.cargo/bin \
        ${config.home.homeDirectory}/.rbenv/shims
      if test -d $p; and not contains $p $PATH
        set -gx PATH $PATH $p
      end
    end
  '';

  # 5. tmux: 業務用 lazyjira ポップアップ（prefix + J）。
  #    programs.tmux.extraConfig は types.lines なので home/programs/tmux.nix の設定に連結される。
  programs.tmux.extraConfig = ''
    # lazyjira をポップアップで開く（prefix + J）
    bind J display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "lazyjira"
  '';

  # ghostty は main の programs.ghostty で十分（command/font/theme の差は
  # Nix 化後 /run/current-system/sw/bin/fish で動作するため override 不要）。

  # Phase 22: 社用 PC ではデフォルト identity = 社用アカウント (~/.config/git/config.local)。
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
