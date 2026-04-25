{ pkgs, username, ... }:

{
  # home.username / home.homeDirectory は nix-darwin の users.users.<name> から自動解決されるため指定しない。

  # 初回設定値。home-manager のメジャー仕様変更があっても挙動を維持するための固定値。
  home.stateVersion = "25.05";

  # Step 1 検証パッケージ: 既存 brew と衝突しない 3 つのみ。
  # 既存 brew 版がある場合、PATH 順序により Nix 版が優先される。
  home.packages = with pkgs; [
    ripgrep
    lsd
    jq
  ];

  # home-manager 自身の管理を有効化。
  programs.home-manager.enable = true;
}
