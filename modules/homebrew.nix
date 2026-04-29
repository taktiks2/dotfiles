{ ... }:

# Homebrew の宣言化（nix-darwin 標準 `homebrew` モジュール経由）。
#
# 本ファイルは feat/work ブランチ専用に書き換えられている。
# main の同ファイルは個人機（taktiks2 / MacBook-Air）向け。
#
# 戦略:
#   - `nix-homebrew` は使わず、既存の Homebrew インストール (/opt/homebrew) はそのまま。
#   - `onActivation.cleanup = "uninstall"`: 未宣言は switch 時に uninstall + autoremove。
#
# 本マシン固有の判断:
#   - bash/bat/broot/btop/fish/fzf/gh/git-delta/jq/just/lazydocker/lazygit/lsd/neovim/
#     ripgrep/tmux/uv/wget は home/common.nix の Nix 経由で配布されるため brew から除外。
#   - bandwhich/eza/fnm/gum/httpie/nushell/p7zip/poppler/pv/terminal-notifier/vhs/
#     visidata/zoxide/bun は home/common.nix（bun）または home/users/takeru.osoegawa.nix
#     （その他）で Nix 化。
#   - acli/lazyjira/awscli/jira-cli/oath-toolkit/csv 系/lnav/miller 等は brew 維持。
#   - wtp は git を transitive 依存として持ち込み /opt/homebrew/bin/git が
#     PATH 順で Nix git を覆い隠していたため撤去（satococoa/tap も同時 drop）。

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade    = false;
      cleanup    = "uninstall";
    };

    taps = [
      "arto-app/tap"            # cask: arto
      "atlassian-labs/acli"     # acli
      "raine/workmux"           # workmux
      "textfuel/tap"            # lazyjira
      # oven-sh/bun は bun の Nix 化により不要（cleanup = "uninstall" で除去される）
      # satococoa/tap は wtp 撤去により未使用
      # local/tap, lucagrulla/tap は orphan のため宣言しない
    ];

    # ---------- brew formula（19 本） ----------
    brews = [
      # 言語ランタイム / DB（main と共通理由）
      "composer"
      "mysql@8.0"
      "rbenv"

      # ベンダー / 商用 CLI（main と共通理由）
      "gemini-cli"
      "raine/workmux/workmux"

      # 業務系（brew tap 専属で nixpkgs 不在 / 不安定）
      "atlassian-labs/acli/acli"
      "textfuel/tap/lazyjira"
      "awscli"
      "jira-cli"
      "oath-toolkit"

      # データ探索系（CLI 群、brew 維持）
      "csview"
      "csvkit"
      "csvtk"
      "lnav"
      "miller"
      "qsv"
      "rich-cli"
      "tidy-viewer"

      # 直 install 系
      "claude-squad"
    ];

    # ---------- cask（23 本） ----------
    casks = [
      # main と共通
      "arto"
      "bruno"
      "copilot-cli"
      "font-hack-nerd-font"
      "font-hackgen-nerd"
      "ghostty"
      "visual-studio-code"

      # work PC 固有
      "alacritty"             # programs.alacritty.package = null のため cask 必須
      "aws-vault-binary"
      "claude-devtools"
      "cmux"
      "cursor"
      "dbeaver-community"
      "docker-desktop"
      "firefox"
      "font-hackgen"
      "mysql-shell"
      "mysqlworkbench"
      "obsidian"
      "orbstack"
      "postman"
      "raycast"
      "session-manager-plugin"
    ];
  };
}
