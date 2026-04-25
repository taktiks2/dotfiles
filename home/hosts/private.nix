{ pkgs, lib, config, username, ... }:

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

  # Step 5: dotfiles リポジトリへの symlink を home-manager で冪等管理。
  # install.sh の setup_symlinks と同じ作業を flake 側でも保証する（二重防御）。
  # 注意: ~/.config 全体を repo への symlink で運用しているため、
  #       home-manager の `xdg.configFile.*` 機構は使わず、トップレベル symlink を維持する。
  home.activation.dotfilesSymlinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ensure_symlink() {
      local target="$1"
      local link="$2"
      if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
        : # 既に正しいリンク
      elif [ -f "$link" ] && [ ! -s "$link" ]; then
        # 空ファイル: 安全に置換（外部プロセスによる自動再生成を想定）
        $DRY_RUN_CMD rm -f "$link"
        $DRY_RUN_CMD ln -s "$target" "$link"
        echo "replaced empty file with symlink: $link -> $target"
      elif [ -e "$link" ] || [ -L "$link" ]; then
        echo "WARN: $link が予期しない状態のためスキップ（手動対応要）" >&2
      else
        $DRY_RUN_CMD mkdir -p "$(dirname "$link")"
        $DRY_RUN_CMD ln -s "$target" "$link"
        echo "created symlink: $link -> $target"
      fi
    }

    ensure_symlink "$HOME/dotfiles/.config" "$HOME/.config"
    ensure_symlink "$HOME/dotfiles/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
  '';

  # home-manager 自身の管理を有効化。
  programs.home-manager.enable = true;
}
