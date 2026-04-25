{
  description = "Generic devShell template (taktiks2/dotfiles)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
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
}
