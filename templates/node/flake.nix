{
  description = "Node.js devShell (default: nodejs_22)";

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
            name = "node-shell";

            # 異なる Node バージョンが必要なら以下を差し替え:
            #   pkgs.nodejs_18  / pkgs.nodejs_20  / pkgs.nodejs_22  / pkgs.nodejs_24
            packages = with pkgs; [
              nodejs_22
              corepack_22  # pnpm / yarn を corepack 経由で
              # 補助ツール
              jq
              just
            ];

            shellHook = ''
              # node_modules/.bin を最優先に
              export PATH="$PWD/node_modules/.bin:$PATH"
              echo "→ devShell: node ($(node --version))"
            '';
          };
        });
    };
}
