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

    # 第二陣 (Step 7 follow-up): brew LATER から Nix へ移行
    tbls       # DB スキーマドキュメント生成
    joshuto    # ranger 風ファイラ
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

  # Step 7 follow-up: install.sh の post-config 関数のうち、idempotent で
  # bootstrap 専用ではないものを home.activation に移譲。
  home.activation.bootstrapSideEffects = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # TPM (tmux plugin manager) を初回のみクローン
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
      echo "TPM cloned to $TPM_DIR (run 'Ctrl+s + I' inside tmux to install plugins)"
    fi

    # secret-env.fish が無ければテンプレを作成（gitignore 対象なので個人マシンごとに実体ファイル必要）
    SECRET_ENV="$HOME/dotfiles/.config/fish/secret-env.fish"
    if [ ! -f "$SECRET_ENV" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$SECRET_ENV")"
      cat > "$SECRET_ENV" <<'EOF'
# 秘匿情報用の環境変数
# このファイルは .gitignore に含まれています
#
# 例:
# set -x GITHUB_TOKEN "your_token_here"
# set -x OPENAI_API_KEY "your_api_key_here"
EOF
      echo "secret-env.fish template created at $SECRET_ENV"
    fi
  '';

  # home-manager 自身の管理を有効化。
  programs.home-manager.enable = true;

  # Step 6: direnv + nix-direnv（プロジェクト単位の devShell 自動有効化）
  # Fish 用のフックは config.fish で手動 source する（programs.fish を使わないため）。
  # 注: direnv 2.37.1 のテストが aarch64-darwin sandbox で zsh test が hang するため
  #     `doCheck = false` で回避（出来上がるバイナリ自体は変わらない）。
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = false; # 手動フック側で対応
    package = pkgs.direnv.overrideAttrs (_: { doCheck = false; });
  };
}
