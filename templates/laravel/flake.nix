{
  description = "Laravel devShell (php82 + composer + mysql)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "laravel-shell";

            packages = with pkgs; [
              php82
              php82Packages.composer
              # 補助ツール
              just
              gnused
              jq
            ];

            # PHP プロジェクトのよくあるパス: vendor/bin と composer global を最優先に。
            shellHook = ''
              export PATH="$PWD/vendor/bin:$HOME/.composer/vendor/bin:$PATH"

              if ! command -v laravel >/dev/null 2>&1; then
                echo "ℹ Laravel Installer 未インストール。必要なら以下:"
                echo "  composer global require laravel/installer"
              fi

              echo "→ devShell: laravel ($(php --version | head -1))"
            '';
          };
        });
    };
}
