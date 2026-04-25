{ pkgs, username, ... }:

{
  # home.username / home.homeDirectory は nix-darwin の users.users.<name> から自動解決されるため指定しない。

  # 初回設定値。home-manager のメジャー仕様変更があっても挙動を維持するための固定値。
  home.stateVersion = "25.05";

  # Step 2 第一陣: brew leaves 57 本のうち、移行確度が高い 31 本を Nix 化。
  # 仕分け根拠は docs/brew-triage.md を参照。
  home.packages = with pkgs; [
    # 検索 / ファイル操作
    ripgrep
    fd
    fzf
    bat
    lsd
    tree
    broot
    fswatch

    # Git / GitHub / 開発フロー
    gh
    delta              # brew: git-delta
    git-filter-repo
    lazygit
    lazydocker
    cocogitto

    # エディタ / マルチプレクサ
    neovim
    tmux

    # JSON / テキスト
    jq
    gnused             # brew: gnu-sed

    # ネットワーク / シェル
    wget
    bash
    bats               # brew: bats-core

    # ビジュアル / システム
    btop
    graphviz
    television

    # 言語ランタイム / ビルド
    zig
    deno
    uv
    sbcl
    cargo-binstall

    # AI / その他
    aichat
    just
  ];

  # home-manager 自身の管理を有効化。
  programs.home-manager.enable = true;
}
