{ pkgs, username, hostname, ... }:

{
  imports = [
    ../../modules/macos-defaults.nix
  ];

  # Determinate Nix がインストール済みのため、nix-darwin による Nix 自体の管理は無効化する。
  # https://determinate.systems/posts/nix-darwin/
  nix.enable = false;

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
}
