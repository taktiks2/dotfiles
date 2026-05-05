{
  description = "taktiks2 dotfiles — nix-darwin + home-manager (Step 1 minimal bootstrap)";

  inputs = {
    # nixpkgs-unstable channel。最新パッケージ追従が必要なため stable から切替。
    # トレードオフ: lock 更新ごとに大規模リビルドが走る、release branch 限定の修正は外れる。
    # `home.stateVersion` は変更しない（HM 公式が初回値固定を明記）。
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate Nix を nix-darwin から宣言的に管理する公式モジュール。
    # 取り込むと自動的に nix-darwin 側の `nix.*` 管理が無効化される（手書きで `nix.enable = false` 不要）。
    # https://docs.determinate.systems/guides/nix-darwin/
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    # Phase 13: シークレット管理。AGE/PGP 暗号化の YAML を git tracked にできる。
    # https://github.com/Mic92/sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, determinate, sops-nix, ... }:
    let
      # Phase 16: ホスト追加が 1 行で済むよう mkDarwin factory 化。
      # Phase 20: hosts/<name>/default.nix を hosts/common.nix に統合。
      #           ホスト固有差分は `extraModules` 引数で per-host モジュールを注入できる。
      # 新ホストは下の darwinConfigurations に `mkDarwin { hostname = "..."; username = "..."; }` を 1 行追加。
      # `dotfilesRoot` は別マシンで `~/code/dotfiles` 等にクローンする場合の上書き用。
      # デフォルトは `/Users/<username>/dotfiles`。`mkOutOfStoreSymlink` の絶対パス解決に使う。
      mkDarwin =
        { hostname
        , username
        , dotfilesRoot ? "/Users/${username}/dotfiles"
        , system ? "aarch64-darwin"
        , extraModules ? [ ]
        , homeExtraModules ? [ ]
        }:
        let
          # Phase 21: ユーザ単位の差分を home/users/<username>.nix で auto-import。
          # ファイルが無ければ pathExists=false で skip され common.nix のみが適用される。
          userFile = ./home/users + "/${username}.nix";
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs username hostname dotfilesRoot; };
          modules = [
            determinate.darwinModules.default
            ({ ... }: {
              determinateNix.enable = true;
            })
            ./hosts/common.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.extraSpecialArgs = { inherit username dotfilesRoot; };
              # Phase 13: sops-nix を home-manager に注入（secrets を ~/.config/sops-nix/secrets/ に復号配置）
              home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
              # Phase 21: home/common.nix を baseline、home/users/<username>.nix を user 差分、
              # homeExtraModules を per-host one-off escape hatch として import。
              home-manager.users.${username} = { lib, ... }: {
                imports =
                  [ ./home/common.nix ]
                  ++ lib.optional (builtins.pathExists userFile) userFile
                  ++ homeExtraModules;
              };
            }
            # 予防的 unfree allowlist。Nix 化したい unfree パッケージが出たらここに追加。
            ({ lib, ... }: {
              nixpkgs.config.allowUnfreePredicate = pkg:
                builtins.elem (lib.getName pkg) [
                  # 例: "vscode" "claude-code"
                ];
              # direnv 2.37.1 の fish/zsh テストが macOS sandbox 内で Killed: 9 で落ちるため回避。
              # 検証 (2026-04-26): 25.11 stable channel (rev 3f05c8657c) に切替後も
              # `nix build nixpkgs#direnv` で `make: *** [GNUmakefile:150: test-fish] Killed: 9`
              # を継続観測したため overlay 残置。upstream fix 反映後に再撤廃判定可。
              nixpkgs.overlays = [
                (final: prev: {
                  direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
                })
              ];
            })
          ] ++ extraModules;
        };
    in
    {
      darwinConfigurations = {
        "private" = mkDarwin {
          hostname = "private";
          username = "taktiks2";
        };
        "work" = mkDarwin {
          hostname = "work";
          username = "takeru.osoegawa";
        };
      };

      # `nix flake init -t ~/dotfiles#<name>` でプロジェクトに devShell を投入できる。
      # default は generic、laravel/node/ruby は per-project ランタイム切替用。
      templates = {
        default = {
          path = ./templates/default;
          description = "Generic devShell template with direnv";
        };
        laravel = {
          path = ./templates/laravel;
          description = "Laravel + PHP 8.4 + Composer devShell";
        };
        node = {
          path = ./templates/node;
          description = "Node.js 22 + corepack devShell";
        };
        ruby = {
          path = ./templates/ruby;
          description = "Ruby 3.3 + Bundler devShell";
        };
        rust = {
          path = ./templates/rust;
          description = "Rust toolchain via rust-overlay (honors rust-toolchain.toml)";
        };
        go = {
          path = ./templates/go;
          description = "Go + gopls/delve/golangci-lint devShell";
        };
      };
    };
}
