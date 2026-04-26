{ pkgs, lib, config, username, ... }:

{
  # home.username / home.homeDirectory は nix-darwin の users.users.<name> から自動解決されるため指定しない。

  # 初回設定値。home-manager のメジャー仕様変更があっても挙動を維持するための固定値。
  home.stateVersion = "25.05";

  # Phase 13: sops-nix によるシークレット管理。
  # secrets/secrets.yaml が存在する時のみ有効化（移行前の build を壊さない）。
  # 移行手順は dotfiles/docs/sops-migration.md 参照。
  sops = lib.mkIf (builtins.pathExists ../secrets/secrets.yaml) {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    # ここに secrets/secrets.yaml の各キーを列挙すると ~/.config/sops-nix/secrets/<KEY> に復号される。
    # 例:
    #   secrets.GITHUB_TOKEN = {};
    #   secrets.OPENAI_API_KEY = {};
    secrets = { };
  };

  # Phase 9: PATH と環境変数を home.sessionPath / home.sessionVariables へ移譲。
  # HM が ~/.config/fish/conf.d/hm-session-vars.fish に展開し、shell 起動時に評価される。
  # fish 固有の手書きは bobthefish theme と Nix profile prepend だけに縮小。
  home.sessionPath = [
    "/opt/homebrew/bin"
    "${config.home.homeDirectory}/Library/Android/sdk/cmdline-tools"
    "${config.home.homeDirectory}/Library/Android/sdk/platform-tools"
    "${config.home.homeDirectory}/Library/Android/sdk/emulator"
    "${config.home.homeDirectory}/Library/Android/sdk/tools"
    "${config.home.homeDirectory}/Library/Android/sdk/tools/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.nodebrew/current/bin"
    "/opt/homebrew/opt/mysql@8.0/bin"
    "${config.home.homeDirectory}/.composer/vendor/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  home.sessionVariables = {
    ANDROID_SDK_ROOT           = "${config.home.homeDirectory}/Library/Android/sdk";
    JAVA_HOME                  = "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home";
    ATAC_MAIN_DIR              = "${config.home.homeDirectory}/.config/atac";
    ATAC_THEME                 = "${config.home.homeDirectory}/.config/atac/settings/theme.toml";
    ATAC_KEY_BINDINGS          = "${config.home.homeDirectory}/.config/atac/settings/key.toml";
    GH_PAGER                   = "delta";
    VIRTUAL_ENV_DISABLE_PROMPT = "1";
    LANG                       = "en_US.UTF-8";
    DYLD_LIBRARY_PATH          = "/opt/homebrew/opt/mysql@8.0/lib";
  };

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
    # tmux は Phase 8 で programs.tmux.enable に移行（plugins 込みで Nix 提供）

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

  # Phase 7: ~/.config 配下の symlink を home-manager の純宣言形へ移行。
  # `mkOutOfStoreSymlink` は store に格納せず dotfiles repo を直接参照するため、
  # `git pull` 後の rebuild 不要で編集が即時反映される（live link）。
  # fish は programs.fish が直接管理するため除外。
  # tmux は Phase 8 までこの形式を維持し、Phase 8 で programs.tmux.extraConfig へ移譲予定。
  xdg.configFile = let
    dotfilesRoot = "${config.home.homeDirectory}/dotfiles/.config";
    link = name: {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/${name}";
    };
  in {
    alacritty    = link "alacritty";
    atac         = link "atac";
    btop         = link "btop";
    ccstatusline = link "ccstatusline";
    cspell       = link "cspell";
    gh-dash      = link "gh-dash";
    ghostty      = link "ghostty";
    git          = link "git";
    mcphub       = link "mcphub";
    nvim         = link "nvim";
    # tmux は Phase 8 で programs.tmux 一本化のため除外（generated tmux.conf と競合回避）
    workmux      = link "workmux";
  };

  # lazygit は ~/Library/Application Support 配下のため home.file 経由で別管理。
  home.file."Library/Application Support/lazygit/config.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config.yml";

  # Step 7 follow-up: install.sh の post-config 関数のうち、idempotent で
  # bootstrap 専用ではないものを home.activation に移譲。
  # Phase 8: TPM clone は撤廃。tmux plugins は programs.tmux.plugins で Nix 配布。
  home.activation.bootstrapSideEffects = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

    # Phase 10: Laravel Installer の自動 install (composer global) は撤廃。
    # 代わりに `nix flake init -t ~/dotfiles#laravel` で per-project devShell へ。
  '';

  # home-manager 自身の管理を有効化。
  programs.home-manager.enable = true;

  # Step 6: direnv + nix-direnv（プロジェクト単位の devShell 自動有効化）
  # Phase 6: upstream で direnv test の darwin issue が解消されたため
  # `doCheck = false` の overrideAttrs を撤廃。バイナリキャッシュ復帰。
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true; # Phase 3: programs.fish 有効化に伴い自動 hook
  };

  # Phase 8: tmux 完全宣言化。TPM 撤廃、plugins は Nix 経由で配布。
  # tmux.conf は HM が programs.tmux 設定から生成するため、~/dotfiles/.config/tmux/ 側は不要。
  programs.tmux = {
    enable = true;
    prefix = "C-s";
    keyMode = "vi";
    terminal = "tmux-256color";
    mouse = true;
    baseIndex = 1;
    focusEvents = true;
    escapeTime = 0;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      copycat
      pain-control
      yank
      resurrect
      continuum
      logging
      {
        plugin = tokyo-night-tmux;
        extraConfig = ''
          set -g @theme_left_separator '${""}'
          set -g @theme_right_separator '${""}'
          set -g @theme_enable_icons '0'
        '';
      }
    ];

    extraConfig = ''
      # ペインのインデックスも 1 から（programs.tmux.baseIndex は window のみ）
      setw -g pane-base-index 1

      # ghostty (TERM=xterm-ghostty) の RGB / 装飾系ケイパビリティ
      set -as terminal-features ",xterm-ghostty*:RGB:usstyle:hyperlinks:ccolour:cstyle:strikethrough:overline"
      # 旧 Tc フラグでのフォールバック
      set -ag terminal-overrides ",xterm-ghostty:Tc"
      set -ag terminal-overrides ",*256col*:Tc"

      # シェルのデフォルトを fish に。nix-darwin が公開する system fish を参照。
      set-option -g default-shell /run/current-system/sw/bin/fish
      set-environment -g PATH "/etc/profiles/per-user/taktiks2/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/bin:/bin"

      # gh dash をポップアップで開く（prefix + g）
      bind g display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "gh dash"

      # workmux dashboard をポップアップで開く（prefix + W）
      bind W display-popup -E -w 50% -h 100% -d "#{pane_current_path}" "workmux dashboard"

      # workmux 連動キー
      bind i run-shell "workmux last-done"
      bind e run-shell "workmux sidebar"
      bind -n M-j run-shell "workmux sidebar next"
      bind -n M-k run-shell "workmux sidebar prev"
      bind -n M-1 run-shell "workmux sidebar jump 1"
      bind -n M-2 run-shell "workmux sidebar jump 2"
      bind -n M-3 run-shell "workmux sidebar jump 3"
      bind -n M-4 run-shell "workmux sidebar jump 4"
      bind -n M-5 run-shell "workmux sidebar jump 5"
      bind -n M-6 run-shell "workmux sidebar jump 6"
      bind -n M-7 run-shell "workmux sidebar jump 7"
      bind -n M-8 run-shell "workmux sidebar jump 8"
      bind -n M-9 run-shell "workmux sidebar jump 9"

      # btop / lazydocker をポップアップで開く
      bind b display-popup -E -w 90% -h 90% "btop"
      bind C display-popup -E -w 90% -h 90% "lazydocker"
    '';
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
      if test -d ~/.config/sops-nix/secrets
          for f in ~/.config/sops-nix/secrets/*
              if test -r $f
                  set -gx (basename $f) (cat $f)
              end
          end
      end

      # 後方互換: 旧来の secret-env.fish も sops 移行が完了するまで併用可能。
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
