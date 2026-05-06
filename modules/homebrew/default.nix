{ lib, ... }:

# Homebrew の宣言化（nix-darwin 標準 `homebrew` モジュール経由）の entry。
#
# 構成:
#   - 本ファイル (default.nix) : 全 PC 共通 (git tracked, push 対象)
#   - local.nix                : ホスト / ユーザ固有 (git tracked だが install.sh が
#                                `git update-index --skip-worktree` でローカル変更を隠蔽)
#       upstream 側は空 stub のまま。各マシンで自由に編集 →
#       `git status` に現れず, `git commit` にも入らない。
#
# 戦略:
#   - `nix-homebrew` は使わず、既存の Homebrew インストール (/opt/homebrew) はそのまま。
#   - `onActivation.cleanup = "uninstall"`: 未宣言は switch 時に uninstall + autoremove。
#   - `homebrew.{taps,brews,casks}` は listOf 型なので default.nix と local.nix の
#     宣言が nix-darwin 側で自動 list concat される。

let
  localFile = ./local.nix;
in
{
  imports = lib.optional (builtins.pathExists localFile) localFile;

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade    = false;
      cleanup    = "uninstall";
    };

    taps = [
      "arto-app/tap"        # cask: arto
      "raine/workmux"       # workmux
    ];

    # ---------- brew formula（共通） ----------
    brews = [
      # 言語ランタイム / DB
      "composer"
      "mysql@8.0"
      "rbenv"

      # ベンダー
      "raine/workmux/workmux"
    ];

    # ---------- cask（共通） ----------
    casks = [
      "arto"
      "bruno"
      "font-hack-nerd-font"
      "font-hackgen-nerd"
      "ghostty"
      "mysql-shell"  # mysqlsh (公式 .pkg): dump 取り込み (util.loadDump) 用。
                     #   nixpkgs 版は V8 を含まずビルドされるため `--js` が
                     #   "JavaScript is not supported." で落ちる。brew は cask 配布のみ。
      "visual-studio-code"
    ];
  };
}
