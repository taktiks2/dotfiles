{
  description = "Go devShell (default: pkgs.go = latest stable)";

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
            name = "go-shell";

            # 異なる Go バージョンが必要なら以下を差し替え:
            #   pkgs.go_1_22 / pkgs.go_1_23 / pkgs.go_1_24
            packages = with pkgs; [
              go
              gopls           # 公式 LSP
              gotools         # goimports / godoc / stringer 等
              delve           # debugger (dlv)
              golangci-lint   # 統合 linter
              # 補助ツール
              just
              jq
            ];

            shellHook = ''
              # `go install` 出力をプロジェクトローカルに分離。
              # GOPATH (= モジュールキャッシュ) はあえて触らず global 共有を維持。
              export GOBIN="$PWD/.gobin"
              export PATH="$GOBIN:$PATH"
              mkdir -p "$GOBIN"
              echo "→ devShell: go ($(go version | awk '{print $3}'))"
            '';
          };
        });
    };
}
