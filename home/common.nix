{ pkgs, lib, config, username, dotfilesRoot, ... }:

# Phase 18 (modular split): per-tool の programs.* 設定は home/programs/*.nix へ抜き出し。
# 本ファイルには「複数ツールに跨るプラットフォーム設定」のみを残す:
#   - stateVersion / sops（メタ）
#   - sessionPath / sessionVariables（PATH と環境変数）
#   - home.packages（Nix CLI バンドル）
#   - xdg.configFile（mkOutOfStoreSymlink による live link）
#   - home.activation.bootstrapSideEffects（idempotent な bootstrap）
# tool 固有の programs.* 設定は ./programs/<tool>.nix を参照。

{
  imports = [
    ./programs/direnv.nix
    ./programs/git.nix         # programs.git + programs.delta + migrateLegacyGitconfig
    ./programs/lazygit.nix
    ./programs/btop.nix
    ./programs/gh-dash.nix
    ./programs/terminal.nix    # programs.alacritty + programs.ghostty
    ./programs/cli.nix         # programs.bat + programs.fzf + programs.lsd
    ./programs/tmux.nix
    ./programs/fish.nix
    ./programs/claude.nix      # claude work / claude private profile switcher
  ];

  # home.username / home.homeDirectory は nix-darwin の users.users.<name> から自動解決されるため指定しない。

  # 初回設定値。home-manager のメジャー仕様変更があっても挙動を維持するための固定値。
  # ※ macOS Sequoia + HM release-25.11 で activation 中に TCC `checkAppManagementPermission`
  #   がクラッシュする issue (nix-community/home-manager#8336) が報告されている。
  #   発生したら `System Settings > Privacy & Security > App Management` で
  #   ターミナル / `darwin-rebuild` を許可リストに追加して再実行。
  home.stateVersion = "25.05";

  # home-manager 自身の管理を有効化。
  programs.home-manager.enable = true;

  # Phase 13: sops-nix によるシークレット管理。
  # 以下を全て満たす時のみ有効化（移行前 build や設定不備での暴発を防ぐ）:
  #   1. secrets/secrets.yaml が存在
  #   2. .sops.yaml の AGE 公開鍵が `AGE_PUBLIC_KEY_PLACEHOLDER` のまま放置されていない
  # 移行手順は dotfiles/docs/sops-migration.md 参照。
  sops = lib.mkIf (
    builtins.pathExists ../secrets/secrets.yaml
    && !lib.hasInfix "AGE_PUBLIC_KEY_PLACEHOLDER" (builtins.readFile ../.sops.yaml)
  ) {
    defaultSopsFile = ../secrets/secrets.yaml;
    # Darwin の AGE 鍵保存先は Apple File System Programming Guide に従い
    # `~/Library/Application Support/sops/age/keys.txt` を採用（Mic92/sops-nix README 準拠）。
    age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
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
    # Android SDK 実体側に存在するサブディレクトリのみ宣言（cmdline-tools/tools/tools/bin は実機に無いので除外）
    "${config.home.homeDirectory}/Library/Android/sdk/platform-tools"
    "${config.home.homeDirectory}/Library/Android/sdk/emulator"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.nodebrew/current/bin"
    "/opt/homebrew/opt/mysql@8.0/bin"
    "${config.home.homeDirectory}/.composer/vendor/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    # rbenv shim も sessionPath に集約（旧 fish interactiveShellInit からの移譲）
    "${config.home.homeDirectory}/.rbenv/shims"
  ];

  # Phase 21: install-specific な hard-coded path (JAVA_HOME など) は home/users/<username>.nix へ移譲。
  # LANG はロケール変更があり得るため lib.mkDefault でラップし、user 側で `mkForce` 不要で上書き可能にする。
  home.sessionVariables = {
    ANDROID_SDK_ROOT           = "${config.home.homeDirectory}/Library/Android/sdk";
    ATAC_MAIN_DIR              = "${config.home.homeDirectory}/.config/atac";
    ATAC_THEME                 = "${config.home.homeDirectory}/.config/atac/settings/theme.toml";
    ATAC_KEY_BINDINGS          = "${config.home.homeDirectory}/.config/atac/settings/key.toml";
    GH_PAGER                   = "delta";
    VIRTUAL_ENV_DISABLE_PROMPT = "1";
    LANG                       = lib.mkDefault "en_US.UTF-8";
    DYLD_LIBRARY_PATH          = "/opt/homebrew/opt/mysql@8.0/lib";
    RBENV_SHELL                = "fish";
  };

  # Step 2 第一陣: brew leaves 57 本のうち、移行確度が高い 31 本を Nix 化。
  # 仕分け根拠は docs/brew-triage.md を参照。
  # 設定が programs.* で管理されている CLI（bat / fzf / lsd / lazygit / btop / delta 等）は
  # ./programs/<tool>.nix の `enable` で配布されるため、本リストには含まない。
  home.packages = with pkgs; [
    # 検索 / ファイル操作
    ripgrep
    fd
    tree
    broot
    fswatch

    # Git / GitHub / 開発フロー
    gh
    git-filter-repo
    lazydocker
    docker-client      # CLI + compose v2 plugin。daemon は OrbStack / Docker Desktop 側が提供
    docker-credential-helpers  # docker-credential-osxkeychain (~/.docker/config.json の credsStore=osxkeychain 用)
    cocogitto

    # エディタ / マルチプレクサ
    neovim

    # JSON / テキスト
    jq
    gnused             # brew: gnu-sed

    # ネットワーク / シェル
    wget
    bash
    bats               # brew: bats-core

    # 言語ランタイム / ビルド
    bun

    # その他
    just
    nh         # darwin-rebuild の Rust 再実装 (`nh darwin switch ~/dotfiles -H private`)。
               # diff 表示・confirm prompt・nix-output-monitor 統合を提供。
               # Determinate Nix 環境でも darwin-rebuild を呼ぶ wrapper として動作する想定。

    # 第二陣 (Step 7 follow-up): brew LATER から Nix へ移行
    tbls       # DB スキーマドキュメント生成
    joshuto    # ranger 風ファイラ

    # 第三陣: nvim none-ls から呼ばれる外部 CLI
    cspell     # Spell checker (lua/plugins/lsp.lua の cspell.nvim が PATH 上の `cspell` を要求)
  ];

  # Phase 7: ~/.config 配下の symlink を home-manager の純宣言形へ移行。
  # `mkOutOfStoreSymlink` は store に格納せず dotfiles repo を直接参照するため、
  # `git pull` 後の rebuild 不要で編集が即時反映される（live link）。
  #
  # Trade-off (2026-04 ベスプラ監査): live edit は再現性を犠牲にする選択。
  #   - メリット: nvim/cspell/ccstatusline 等の頻繁編集対象を `darwin-rebuild switch` 不要で更新
  #   - デメリット: dotfiles repo が `~/dotfiles` に存在することが前提。別 host で
  #                 git pull を忘れるとリンク先が古い。Pure 派は `source = ./.config/<name>`
  #                 で nix store inclusion し、再現性を取る。
  # 本リポジトリは「日常 1 マシン運用 + 編集快適性優先」として live を選択。
  # 引っ越し / 多 host 化が進んだら store inclusion に切替検討。詳細は docs/config-management-strategy.md。
  xdg.configFile = let
    configRoot = "${dotfilesRoot}/.config";
    link = name: {
      source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/${name}";
    };
  in {
    # 専用 programs.* モジュール非対応のもののみ live link で残す。
    # alacritty/btop/gh-dash/ghostty/git/lazygit は programs.* に移行済（Phase 17）。
    atac         = link "atac";
    ccstatusline = link "ccstatusline";
    cspell       = link "cspell";
    mcphub       = link "mcphub";
    nvim         = link "nvim";
    workmux      = link "workmux";
    # tmux は Phase 8 で programs.tmux 一本化のため除外（generated tmux.conf と競合回避）

    # gh-dash の keybindings から呼ばれるシェルスクリプトのみ残す
    # （config.yml は programs.gh-dash.settings 側で管理）
    "gh-dash/bin/octo-review.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${configRoot}/gh-dash/bin/octo-review.sh";
  };

  # ~/.claude も dotfiles 配下を live link で参照（Claude Code 設定 / agents / skills / plugins）。
  # 旧 install.sh の `setup_global_npm` 内で行っていた手動 `ln -s` を home-manager に集約。
  home.file.".claude".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/.claude";

  # Step 7 follow-up: install.sh の post-config 関数のうち、idempotent で
  # bootstrap 専用ではないものを home.activation に移譲。
  # Phase 8: TPM clone は撤廃。tmux plugins は programs.tmux.plugins で Nix 配布。
  # 注: programs.git / .gitconfig 移行用 activation は ./programs/git.nix 側で定義。
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
}
