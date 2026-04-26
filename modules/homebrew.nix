{ ... }:

# Homebrew の宣言化（nix-darwin 標準 `homebrew` モジュール経由）。
#
# 戦略:
#   - `nix-homebrew` は使わず、既存の Homebrew インストール (/opt/homebrew) はそのまま残す。
#   - nix-darwin が `brew bundle` 相当の冪等な同期を実行する。
#   - `onActivation.cleanup = "uninstall"`: 未宣言パッケージは switch 時に
#     自動 uninstall + autoremove。tap/formula/cask が完全に git 管理下にある状態。
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false; # 切替のたびに brew update を走らせない
      upgrade = false;    # 既存パッケージの自動アップグレードもしない
      cleanup = "uninstall";
    };

    # 第三者 tap。homebrew/cask 標準配下のものは tap 不要。
    taps = [
      # cask 用
      "arto-app/tap"      # arto

      # formula 用
      "carlocab/personal" # unrar
      "heroku/brew"       # heroku
      "homebrew/services" # `brew services` インフラ
      "julien-cpsn/atac"  # atac
      "ngrok/ngrok"       # ngrok (cask)
      "osx-cross/arm"     # ARM クロスコンパイル
      "osx-cross/avr"     # AVR クロスコンパイル + avr-gcc
      "oven-sh/bun"       # bun
      "qmk/qmk"           # qmk
      "raine/workmux"     # workmux
      "supabase/tap"      # supabase
    ];

    # ---------- brew formula（25 本） ----------
    # docs/brew-triage.md の KEEP + LATER に該当。Nix 化が困難または非推奨なもの。
    # （Step 7 follow-up で tbls/joshuto を Nix 移行、本フォローアップで fisher を削除予定）
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

      # Fish プラグインマネージャ
      "fisher"

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
