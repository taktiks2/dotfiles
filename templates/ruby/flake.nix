{
  description = "Ruby devShell (default: ruby_3_3 + bundler)";

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
            name = "ruby-shell";

            # 異なる Ruby バージョンが必要なら pkgs.ruby_3_2 / ruby_3_4 などへ差し替え。
            packages = with pkgs; [
              ruby_3_3
              # 補助ツール
              just
              jq
            ];

            shellHook = ''
              # bundler のローカル設定: vendor/bundle に gem を入れる
              export BUNDLE_PATH="$PWD/vendor/bundle"
              export PATH="$BUNDLE_PATH/bin:$PWD/bin:$PATH"

              # bundler が gem 単体で入っているか確認
              if ! command -v bundle >/dev/null 2>&1; then
                echo "ℹ bundler 未インストール。必要なら以下:"
                echo "  gem install --user-install bundler"
              fi

              echo "→ devShell: ruby ($(ruby --version))"
            '';
          };
        });
    };
}
