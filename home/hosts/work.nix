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

  # 5. alacritty: TokyoNight + 200x60 + Hack Nerd Font
  #    main の programs.alacritty は Shift+Return キーバインドのみ宣言。
  #    settings は attrset として merge されるため別キー（colors/font/window/terminal）
  #    だけを追加する（keyboard.bindings は重複させない）。
  programs.alacritty.settings = {
    colors = {
      bright = {
        black   = "#444b6a"; blue    = "#7da6ff"; cyan = "#0db9d7";
        green   = "#b9f27c"; magenta = "#bb9af7"; red  = "#ff7a93";
        white   = "#acb0d0"; yellow  = "#ff9e64";
      };
      normal = {
        black   = "#32344a"; blue    = "#7aa2f7"; cyan = "#449dab";
        green   = "#9ece6a"; magenta = "#ad8ee6"; red  = "#f7768e";
        white   = "#787c99"; yellow  = "#e0af68";
      };
      primary = {
        background = "#1a1b26";
        foreground = "#a9b1d6";
      };
    };
    font = {
      size   = 10;
      bold   = { family = "Hack Nerd Font"; style = "Bold"; };
      italic = { family = "Hack Nerd Font"; style = "Regular Italic"; };
      normal = { family = "Hack Nerd Font"; style = "Regular"; };
    };
    terminal.shell = {
      args    = [ "--login" ];
      program = "/opt/homebrew/bin/fish";
    };
    window = {
      opacity        = 1.0;
      option_as_alt  = "Both";
      dimensions     = { columns = 200; lines = 60; };
      padding        = { x = 4; y = 4; };
    };
  };

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
}
