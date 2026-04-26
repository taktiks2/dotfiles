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
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, determinate, ... }:
    let
      hostname = "MacBook-Air";
      username = "taktiks2";
      system = "aarch64-darwin";
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit username hostname; };
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
            home-manager.users.${username} = import ./home/${username}.nix;
          }
          # 予防的 unfree allowlist。Nix 化したい unfree パッケージが出たらここに追加。
          ({ lib, ... }: {
            nixpkgs.config.allowUnfreePredicate = pkg:
              builtins.elem (lib.getName pkg) [
                # 例: "vscode" "claude-code"
              ];
          })
        ];
      };

      # `nix flake init -t ~/dotfiles` でプロジェクトに devShell を投入できる。
      templates = {
        default = {
          path = ./templates/default;
          description = "Generic devShell template with direnv";
        };
      };
    };
}
