{ pkgs, lib, username, ... }:

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

    # 第三陣: nvim none-ls から呼ばれる外部 CLI
    cspell     # Spell checker (lua/plugins/lsp.lua の cspell.nvim が PATH 上の `cspell` を要求)
  ];

  # Phase 3: ~/.config 単一 symlink を解体し、git tracked な個別ディレクトリだけ symlink する。
  # fish ディレクトリは home-manager (programs.fish) 管理のため symlink 対象から除外。
  # untracked な runtime state (gh, github-copilot, yarn, broot, ...) は実 ~/.config に物理移動済。
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

    # git tracked ディレクトリのみ。fish は除外（home-manager が直接管理）。
    for d in alacritty atac btop ccstatusline cspell gh-dash ghostty git mcphub nvim tmux workmux; do
      ensure_symlink "$HOME/dotfiles/.config/$d" "$HOME/.config/$d"
    done
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

    # secret-env.fish が無ければテンプレを作成（gitignore 相当、機密のため dotfiles repo 外に配置）
    SECRET_ENV="$HOME/.config/fish/secret-env.fish"
    if [ ! -f "$SECRET_ENV" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$SECRET_ENV")"
      cat > "$SECRET_ENV" <<'EOF'
# 秘匿情報用の環境変数（dotfiles repo 外に配置）
#
# 例:
# set -x GITHUB_TOKEN "your_token_here"
# set -x OPENAI_API_KEY "your_api_key_here"
EOF
      echo "secret-env.fish template created at $SECRET_ENV"
    fi

    # Phase 3: Fisher / bobthefish の curl パイプは廃止。
    # bobthefish/z/bass は programs.fish.plugins により Nix で宣言管理される。

    # Laravel Installer（composer がある場合のみ・初回のみ）
    if command -v composer >/dev/null 2>&1 && [ ! -x "$HOME/.composer/vendor/bin/laravel" ]; then
      $DRY_RUN_CMD composer global require laravel/installer || echo "Laravel Installer の自動インストール失敗（手動で対応してください）"
    fi
  '';

  # home-manager 自身の管理を有効化。
  programs.home-manager.enable = true;

  # Step 6: direnv + nix-direnv（プロジェクト単位の devShell 自動有効化）
  # 注: direnv 2.37.1 のテストが aarch64-darwin sandbox で zsh test が hang するため
  #     `doCheck = false` で回避（出来上がるバイナリ自体は変わらない）。
  #     overrideAttrs によりバイナリキャッシュは無効化されローカルビルドになる。
  #     upstream で test が darwin で skip されるよう修正されたら以下行を削除。
  #     関連検索: https://github.com/NixOS/nixpkgs/issues?q=direnv+darwin+test
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true; # Phase 3: programs.fish 有効化に伴い自動 hook
    package = pkgs.direnv.overrideAttrs (_: { doCheck = false; });
  };

  # Phase 3: Fish 本格宣言化
  programs.fish = {
    enable = true;

    plugins = [
      { name = "bobthefish"; src = pkgs.fishPlugins.bobthefish.src; }
      { name = "z";          src = pkgs.fishPlugins.z.src; }
      { name = "bass";       src = pkgs.fishPlugins.bass.src; }
    ];

    shellAliases = {
      vim = "nvim";
      vi = "nvim";
      v = "nvim";
      ghd = "gh dash";
      lg = "lazygit";
      ls = "lsd";
      la = "lsd -a";
      ll = "lsd -al";
      sls = "sbcl --load ~/.local/share/nvim/lazy/nvlime/lisp/start-nvlime.lisp";
      wm = "workmux";
      agents = "agents.fish";
      # 旧 conf.d/multi-agent-shogun.fish から移植
      css = "tmux attach-session -t shogun";
      csm = "tmux attach-session -t multiagent";
    };

    # bobthefish theme & PATH（plugin が読まれる前に評価される必要があるため shellInit に置く）
    shellInit = ''
      set -g theme_color_scheme dracula
      set -g theme_display_git yes
      set -g theme_display_git_default_branch yes
      set -g theme_display_node yes
      set -g theme_display_date no
      set -g theme_powerline_fonts yes
      set -g theme_nerd_fonts yes
      set -g theme_newline_cursor yes
      set -g theme_newline_prompt '> '

      set -x VIRTUAL_ENV_DISABLE_PROMPT 1
      set -x LANG en_US.UTF-8

      # PATH 構築（後で Nix 系を再 prepend して最優先化）
      set PATH /opt/homebrew/bin $PATH
      set PATH $HOME/Library/Android/sdk/cmdline-tools $PATH
      set PATH $HOME/Library/Android/sdk/emulator $PATH
      set PATH $HOME/Library/Android/sdk/tools $PATH
      set PATH $HOME/Library/Android/sdk/tools/bin $PATH
      set PATH $HOME/Library/Android/sdk/platform-tools $PATH
      set PATH $HOME/bin $PATH
      set PATH $HOME/.nodebrew/current/bin $PATH
      set PATH /opt/homebrew/opt/mysql@8.0/bin $PATH
      set PATH $HOME/.composer/vendor/bin $PATH
      set PATH $HOME/.cargo/bin $PATH
      set DYLD_LIBRARY_PATH /opt/homebrew/opt/mysql@8.0/lib $DYLD_LIBRARY_PATH
      set -x ANDROID_SDK_ROOT $HOME/Library/Android/sdk
      set -x JAVA_HOME /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

      # atac
      set -x ATAC_MAIN_DIR $HOME/.config/atac
      set -x ATAC_THEME $HOME/.config/atac/settings/theme.toml
      set -x ATAC_KEY_BINDINGS $HOME/.config/atac/settings/key.toml

      # git delta & gh dash
      set -x GH_PAGER delta

      # Nix profiles を最後に prepend (= 最優先)
      for nix_path in /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin
        if test -d $nix_path; and not contains $nix_path $PATH
          set -gx PATH $nix_path $PATH
        end
      end
    '';

    # 対話シェル限定の初期化
    interactiveShellInit = ''
      # 秘匿情報読み込み
      if test -f ~/.config/fish/secret-env.fish
          source ~/.config/fish/secret-env.fish
      end

      # rbenv shim
      set -gx PATH '/Users/taktiks2/.rbenv/shims' $PATH
      set -gx RBENV_SHELL fish
      command rbenv rehash 2>/dev/null

      function rbenv
          set command $argv[1]
          set -e argv[1]
          switch "$command"
              case rehash shell
                  rbenv "sh-$command" $argv | source
              case '*'
                  command rbenv "$command" $argv
          end
      end

      # workmux completions
      if command -q workmux
          workmux completions fish | source
      end

      # Google Cloud SDK
      if test -f /Users/taktiks2/google-cloud-sdk/path.fish.inc
          . /Users/taktiks2/google-cloud-sdk/path.fish.inc
      end
    '';
  };
}
