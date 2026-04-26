{
  description = "Generic devShell template (taktiks2/dotfiles)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  # flake-utils は依存削減のため不採用。素の `forAllSystems` で十分。
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
            name = "dev-shell";

            # プロジェクトに必要なツールをここに追加
            packages = with pkgs; [
              git
              jq
              ripgrep
              # 例: 言語ごとに以下を有効化
              # nodejs_22
              # python313
              # rustup
              # go
              # deno
            ];

            # 環境変数
            # env = {
            #   FOO = "bar";
            # };

            shellHook = ''
              echo "→ devShell: $(basename $PWD)"
            '';
          };
        });
    };
}
