{ pkgs, username, hostname, ... }:

{
  imports = [
    ../../modules/macos-defaults.nix
    ../../modules/homebrew.nix
  ];

  # Nix 自体の管理は flake 側で `determinate.darwinModules.default` + `determinateNix.enable = true`
  # により Determinate に委譲済み（nix-darwin の `nix.*` は自動で disable される）。
  # https://docs.determinate.systems/guides/nix-darwin/

  # nix-darwin 25.05 以降で必須。home-manager 等のユーザ向け機能で使用される。
  system.primaryUser = username;

  # 設定の互換性バージョン（後方互換のため固定）。
  system.stateVersion = 6;

  # Apple Silicon
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Step 1 検証用: 最小限のシステムレベルパッケージ。
  environment.systemPackages = [ ];

  networking.hostName = hostname;
  networking.computerName = "MacBook Air";

  # ユーザ定義（home-manager がホームディレクトリ解決に参照する）
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # zsh は既存ユーザ環境を尊重し、interactive shell の初期化のみ有効化。
  programs.zsh.enable = true;

  # fish を system level で有効化:
  #   - /etc/shells に Nix 版 fish が登録される（chsh で選択可能に）
  #   - /run/current-system/sw/bin/fish が公開される（Alacritty / Ghostty 等の terminal config から参照）
  # 実際のユーザ向け設定は home-manager の programs.fish 側で行う。
  programs.fish.enable = true;
}
