{
  description = "Rust devShell (rust-overlay; honors rust-toolchain.toml)";

  inputs = {
    # 既存 templates と揃えて unstable を採用（templates は新規プロジェクト前提）。
    nixpkgs.url      = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  # flake-utils は依存削減のため不採用。素の `forAllSystems` で十分。
  outputs = { self, nixpkgs, rust-overlay }:
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
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };

          # rust-toolchain.toml が git tracked であればそれを尊重（MSRV / nightly / component pin）。
          # 純 flake 評価のため未 add のファイルは見えない点に注意（`git add rust-toolchain.toml` が必要）。
          # 別バージョンが必要ならフォールバック側を以下に差し替え:
          #   pkgs.rust-bin.stable."1.83.0".default
          #   pkgs.rust-bin.nightly.latest.default
          #   pkgs.rust-bin.beta.latest.default
          toolchain =
            if builtins.pathExists ./rust-toolchain.toml
            then pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml
            else pkgs.rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
            };
        in
        {
          default = pkgs.mkShell {
            name = "rust-shell";

            packages = [
              toolchain
              # 補助ツール
              pkgs.cargo-watch
              pkgs.cargo-nextest
              pkgs.pkg-config
              pkgs.just
              pkgs.jq
            ];

            # ネイティブリンクが要る crate (openssl-sys / reqwest 等) 用。
            # macOS framework が必要なら以下も追加:
            #   pkgs.darwin.apple_sdk.frameworks.{Security,SystemConfiguration,CoreFoundation}
            buildInputs = with pkgs; [ openssl ]
              ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ libiconv ];

            shellHook = ''
              export RUST_BACKTRACE=1
              echo "→ devShell: rust ($(rustc --version 2>/dev/null | awk '{print $2}'))"
            '';
          };
        });
    };
}
