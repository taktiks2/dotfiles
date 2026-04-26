{ ... }:

# Homebrew の宣言化（nix-darwin 標準 `homebrew` モジュール経由）。
#
# 戦略:
#   - `nix-homebrew` は使わず、既存の Homebrew インストール (/opt/homebrew) はそのまま残す。
#   - nix-darwin が `brew bundle` 相当の冪等な同期を実行する。
#   - `onActivation.cleanup = "uninstall"`: 未宣言パッケージは switch 時に
#     自動 uninstall + autoremove。tap/formula/cask が完全に git 管理下にある状態。
#
# 暗黙依存に関する注意 (cleanup = "uninstall" の挙動):
#   `brew bundle cleanup` は Brewfile に列挙されていない formula のうち
#   「Brewfile 内 formula の `depends_on` 依存ではない」もののみを uninstall する。
#   そのため `composer` を列挙すれば `php` は依存として自動保持される。
#   ただし upstream で formula の依存宣言が変わると意図せず削除される可能性があるため、
#   重要な runtime 依存は列挙したいところ:
#     - composer  → php (homebrew-core/Formula/c/composer.rb の depends_on "php")
#     - rbenv     → ruby-build (cask 経由でなく brew tap)
#     - nodebrew  → 単体動作 (依存なし)
#   `MAS apps` は cleanup の対象外（Homebrew Bundle 制限）。
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false; # 切替のたびに brew update を走らせない
      upgrade = false;    # 既存パッケージの自動アップグレードもしない
      cleanup = "uninstall";
    };

    # 第三者 tap。homebrew/cask 標準配下のものは tap 不要。
    # Brew 5.x で `brew services` はコア化されたため `homebrew/services` は不要（削除済）。
    # `osx-cross/arm` / `oven-sh/bun` は宣言された formula が無いため削除。
    taps = [
      # cask 用
      "arto-app/tap"      # arto

      # formula 用
      "carlocab/personal" # unrar
      "heroku/brew"       # heroku
      "julien-cpsn/atac"  # atac
      "ngrok/ngrok"       # ngrok (cask)
      "osx-cross/avr"     # AVR クロスコンパイル + avr-gcc
      "qmk/qmk"           # qmk
      "raine/workmux"     # workmux
      "supabase/tap"      # supabase
    ];

    # ---------- brew formula（24 本） ----------
    # docs/brew-triage.md の KEEP + LATER に該当。Nix 化が困難または非推奨なもの。
    # （Step 7 follow-up で tbls/joshuto を Nix 移行、本フォローアップで fisher を削除）
    brews = [
      # 言語ランタイム / バージョンマネージャ
      "composer"
      "luarocks"
      "nodebrew"
      "python@3.10"
      "rbenv"

      # データベース / サービス
      "mysql"
      "mysql@8.0"
      "postgresql@14"

      # 重量ビルド / Nix キャッシュが弱い
      "bundletool"
      "clisp"
      "openapi-generator"
      "qemu"

      # ベンダー / 商用 CLI
      "azure-cli"
      "docker"
      "fastlane"
      "gemini-cli"
      "supabase"

      # 第三者 tap formula（tap/repo/name 形式）
      "carlocab/personal/unrar"
      "heroku/brew/heroku"
      "julien-cpsn/atac/atac"
      "osx-cross/avr/avr-gcc@9"
      "qmk/qmk/qmk"
      "raine/workmux/workmux"

      # LATER 残: Nix 化が困難または嗜好問題で残置
      "rogue" # 古典ローグライクゲーム、Nix 版なし
    ];

    # ---------- cask（13 本） ----------
    casks = [
      "arto"
      "bruno"
      "copilot-cli"
      "devtoys"
      "font-hack-nerd-font"
      "font-hackgen-nerd"
      "ghostty"
      "godot"
      "ngrok"
      "utm"
      "visual-studio-code"
      "warp"
      "zulu@17"
    ];

    # masApps（Mac App Store）は現状未使用。
  };
}
