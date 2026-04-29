{ pkgs, lib, config, ... }:

# work ホスト固有の差分。
# home/common.nix の baseline を override / extend する。

{
  # 1. brew → Nix 移行する追加パッケージ
  #    （bun は home/common.nix に統合済のためここでは指定しない）
  #    fnm は home-manager 25.11 に programs.fnm が無いため pkgs から直接配布し、
  #    fish 統合は programs.fish.interactiveShellInit で別途行う。
  home.packages = with pkgs; [
    bandwhich
    eza
    fnm
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

  # 2. fnm fish 統合（home-manager 25.11 に programs.fnm が無いため手動）。
  #    home/programs/fish.nix の interactiveShellInit に追記される（attrset merge）。
  programs.fish.interactiveShellInit = ''
    if command -q fnm
        fnm env --use-on-cd --shell fish | source
    end
  '';

  # 3. zoxide: cd jumper
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # 4. PATH から ~/.nodebrew/current/bin を除去（fnm に統一）。
  home.sessionPath = lib.mkForce [
    "/opt/homebrew/bin"
    "${config.home.homeDirectory}/Library/Android/sdk/platform-tools"
    "${config.home.homeDirectory}/Library/Android/sdk/emulator"
    "${config.home.homeDirectory}/bin"
    "/opt/homebrew/opt/mysql@8.0/bin"
    "${config.home.homeDirectory}/.composer/vendor/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.rbenv/shims"
  ];

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
