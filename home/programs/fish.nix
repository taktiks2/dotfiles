{ pkgs, ... }:

# Phase 3: Fish 本格宣言化。Phase 9 で PATH / 環境変数を home.sessionPath / sessionVariables へ移譲。
# Phase 13 で sops 復号 secrets の interactiveShellInit 取り込みを追加。
# Phase 18 (modular split): home/taktiks2.nix から本ファイルへ抜き出し。

{
  programs.fish = {
    enable = true;

    plugins = [
      { name = "bobthefish"; src = pkgs.fishPlugins.bobthefish.src; }
      { name = "z";          src = pkgs.fishPlugins.z.src; }
      { name = "bass";       src = pkgs.fishPlugins.bass.src; }
    ];

    # rbenv は brew 管理の binary を呼びつつ、sh-rehash / sh-shell だけ source 評価する。
    # 旧 interactiveShellInit 内のインライン関数定義から宣言形へ移譲。
    # 依存: `modules/homebrew.nix` の `brews = [... "rbenv" ...]` (brew 経由で `rbenv` バイナリを供給)。
    functions = {
      rbenv = ''
        set command $argv[1]
        set -e argv[1]
        switch "$command"
            case rehash shell
                rbenv "sh-$command" $argv | source
            case '*'
                command rbenv "$command" $argv
        end
      '';
    };

    shellAliases = {
      vim = "nvim";
      vi = "nvim";
      v = "nvim";
      ghd = "gh dash";
      # lg は programs.lazygit が fish wrapper (LAZYGIT_NEW_DIR_FILE 連携) を提供するため alias は削除
      ls = "lsd";
      la = "lsd -a";
      ll = "lsd -al";
      sls = "sbcl --load ~/.local/share/nvim/lazy/nvlime/lisp/start-nvlime.lisp";
      wm = "workmux";
    };

    # Phase 9: PATH と環境変数は home.sessionPath / home.sessionVariables に移譲済。
    # shellInit には bobthefish theme と Nix profile 最優先化だけを残す。
    shellInit = ''
      # bobthefish theme（plugin が読まれる前に評価される必要があるため shellInit）
      set -g theme_color_scheme dracula
      set -g theme_display_git yes
      set -g theme_display_git_default_branch yes
      set -g theme_display_node yes
      set -g theme_display_date no
      set -g theme_powerline_fonts yes
      set -g theme_nerd_fonts yes
      set -g theme_newline_cursor yes
      set -g theme_newline_prompt '> '

      # Nix profiles を最先頭に再 prepend（= 最優先）
      for nix_path in /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin
        if test -d $nix_path; and not contains $nix_path $PATH
          set -gx PATH $nix_path $PATH
        end
      end
    '';

    # 対話シェル限定の初期化
    interactiveShellInit = ''
      # Phase 13: sops-nix で復号された secrets を環境変数に展開。
      # `home/taktiks2.nix` の sops.secrets 配下に登録した KEY を順次読み込む。
      # SAFETY:
      #   - `set -gx` は変数名を validate しないため、`sops.secrets.PATH = {}` のような
      #     設定ミスで対話シェル毎回 $PATH が破壊されうる。以下で多段防御:
      #       a. シェル環境を破壊しうる予約名は contains で skip
      #       b. POSIX 環境変数識別子のみ通す regex フィルタ
      if test -d ~/.config/sops-nix/secrets
          for f in ~/.config/sops-nix/secrets/*
              set -l key (basename $f)
              if contains -- $key PATH HOME USER SHELL PWD OLDPWD IFS LD_PRELOAD DYLD_LIBRARY_PATH DYLD_INSERT_LIBRARIES
                  continue
              end
              if not string match -rq '^[A-Za-z_][A-Za-z0-9_]*$' -- $key
                  continue
              end
              if test -r $f
                  set -gx $key (cat $f)
              end
          end
      end

      # 後方互換: 旧来の secret-env.fish も sops 移行が完了するまで併用可能。
      if test -f ~/.config/fish/secret-env.fish
          source ~/.config/fish/secret-env.fish
      end

      # rbenv 初期化 (PATH/RBENV_SHELL は home.sessionPath / sessionVariables へ移譲済)
      # rehash は新規 shim 同期のための副作用なので interactive 起動時に 1 回だけ。
      command -q rbenv; and command rbenv rehash 2>/dev/null

      # workmux completions
      if command -q workmux
          workmux completions fish | source
      end

      # Google Cloud SDK (homeDirectory 経由で username に依存しない)
      if test -f $HOME/google-cloud-sdk/path.fish.inc
          . $HOME/google-cloud-sdk/path.fish.inc
      end
    '';
  };
}
