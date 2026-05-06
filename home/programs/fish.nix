{ pkgs, ... }:

# Phase 3: Fish 本格宣言化。Phase 9 で PATH / 環境変数を home.sessionPath / sessionVariables へ移譲。
# Phase 13 で sops 復号 secrets の interactiveShellInit 取り込みを追加。
# Phase 18 (modular split): home/taktiks2.nix から本ファイルへ抜き出し（Phase 21 で taktiks2.nix → common.nix へ rename）。

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

      # darwin-rebuild switch のラッパ。引数で flake のホスト attribute を切り替える。
      darwin-switch = ''
        set -l host $argv[1]
        switch "$host"
            case work private
                sudo darwin-rebuild switch --flake ~/dotfiles#$host
            case '*'
                echo "usage: darwin-switch <work|private>" >&2
                return 1
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
      # __bobthefish_prompt_node は interactiveShellInit で再定義し、PATH 上の `node --version` を表示する。
      # `yes` 指定により package.json / .nvmrc / .node-version が見つかったディレクトリでのみ表示される。
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
      # `home/common.nix` の sops.secrets 配下に登録した KEY を順次読み込む。
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

      # bobthefish の __bobthefish_prompt_node を上書き。
      # bobthefish の fish_prompt.fish は内部で __bobthefish_prompt_node を inline 定義するため、
      # ~/.config/fish/functions/ に置く autoload override は fish_prompt.fish のロード時に
      # 上書きされてしまう。解決策: 先に fish_prompt を autoload させ (= bobthefish の関数群を
      # メモリへ展開)、そのあとで再定義することで我々の実装を勝たせる。
      # 標準実装は `fnm current` を呼ぶため、Nix flake + direnv で切替えた Node が prompt に
      # 反映されない。PATH 上の `node --version` をそのまま使う実装に置き換える。
      functions -q fish_prompt
      function __bobthefish_prompt_node --description 'Display current node version (PATH-based)' --no-scope-shadowing
          [ "$theme_display_node" = no ]
          and return

          if [ "$theme_display_node" = yes ]
              __bobthefish_prompt_find_file_up "$PWD" package.json .nvmrc .node-version
              or return
          end

          command -q node
          or return

          set -l node_version (node --version 2>/dev/null)
          [ -z "$node_version" ]
          and return

          __bobthefish_start_segment $color_node
          echo -ns $node_glyph $node_version ' '
          set_color normal
      end

      # fnm の interactive 統合は廃止 (Phase 24)。
      # 理由:
      #   - `fnm env` が PATH 先頭に fnm multishell dir を prepend するため、
      #     direnv (nix-direnv) で用意した devShell の Node が子シェルで上書きされる。
      #   - `--use-on-cd` は `.node-version` を読みに行くので、Nix flake 化したリポジトリで
      #     未 install バージョンを要求してエラーが出る。
      # Node のバージョン管理はリポジトリ単位の flake.nix + direnv に一本化する。
      # fnm コマンド自体は home.packages に残すため、必要なら `eval (fnm env | source)` で手動有効化可。
    '';
  };
}
