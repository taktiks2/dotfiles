{
  description = "taktiks2 dotfiles — nix-darwin + home-manager (Step 1 minimal bootstrap)";

  inputs = {
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
      # 新ホストは下の darwinConfigurations に `mkDarwin { hostname = "..."; username = "..."; }` を 1 行追加。
      mkDarwin = { hostname, username, system ? "aarch64-darwin" }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs username hostname; };
          modules = [
            determinate.darwinModules.default
            ({ ... }: {
              determinateNix.enable = true;
            })
            ./hosts/${hostname}
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.extraSpecialArgs = { inherit username; };
              # Phase 13: sops-nix を home-manager に注入（secrets を ~/.config/sops-nix/secrets/ に復号配置）
              home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
              home-manager.users.${username} = import ./home/${username}.nix;
            }
            # 予防的 unfree allowlist。Nix 化したい unfree パッケージが出たらここに追加。
            ({ lib, ... }: {
              nixpkgs.config.allowUnfreePredicate = pkg:
                builtins.elem (lib.getName pkg) [
                  # 例: "vscode" "claude-code"
                ];
              # direnv 2.37.1 の zsh テストが macOS sandbox 内でハングするための回避。
              # 注: Phase 6 計画は「2026-04 nixpkgs-unstable で fix 済」を前提に削除したが、
              # flake.lock の nixpkgs は 2025-10-28 (rev daf6dc47aa4b) のまま固定で fix が入っていないため復元。
              # nixpkgs lock を 2026-04 系に更新できたら再撤廃可。
              nixpkgs.overlays = [
                (final: prev: {
                  direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
                })
              ];
            })
          ];
        };
    in
    {
      darwinConfigurations = {
        "MacBook-Air" = mkDarwin {
          hostname = "MacBook-Air";
          username = "taktiks2";
        };
        # 追加例 (新 Mac 来たら 1 ブロック増やすだけ):
        # "MacBook-Pro" = mkDarwin {
        #   hostname = "MacBook-Pro";
        #   username = "taktiks2";
        # };
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
          description = "Laravel + PHP 8.2 + Composer devShell";
        };
        node = {
          path = ./templates/node;
          description = "Node.js 22 + corepack devShell";
        };
        ruby = {
          path = ./templates/ruby;
          description = "Ruby 3.3 + Bundler devShell";
        };
      };
    };
}
