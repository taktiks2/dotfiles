{ lib, config, ... }:

# Phase 17: ~/.gitconfig + .config/git/ignore + lazygit pagers/git connection を programs.git / programs.delta に統合。
# Phase 19: user.{name,email} を ~/.config/git/config.local に分離（公開リポ上の平文露出を回避、
#           sops-nix 移行後はそちらに集約）。

{
  programs.git = {
    enable = true;

    # 旧 .config/git/ignore (4 行) を Nix 化。
    ignores = [
      ".worktree"
      ".DS_Store"
      "**/.claude/settings.local.json"
    ];

    # 旧 ~/.gitconfig 内容を 1:1 移植。HM 25.11 で userName/userEmail/extraConfig は
    # settings に統合された (settings.user.name / settings.user.email / settings.<section>.<key>)。
    # delta 関連は programs.delta が interactive.diffFilter / pager.* / [delta] navigate
    # 等を自動で注入するため重複定義しない。
    # user.{name,email} はローカル include ファイル（後述 bootstrap）に分離。
    settings = {
      init.defaultBranch    = "main";
      core.editor           = "nvim";
      merge.conflictstyle   = "diff3";
      diff.colorMoved       = "default";
    };

    # ~/.config/git/config.local（dotfiles repo 外、git 追跡対象外）から
    # user.{name,email} 等のホスト固有設定を読み込む。git は include 先が無くても無害に無視する。
    includes = [
      { path = "${config.home.homeDirectory}/.config/git/config.local"; }
    ];
  };

  # delta 本体（HM 25.11 で programs.git.delta から programs.delta へ昇格）。
  programs.delta = {
    enable = true;
    enableGitIntegration = true;  # 25.11 以降は明示指定が必要
    options = {
      navigate     = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  # 旧 ~/.gitconfig が残っていると XDG 側 (~/.config/git/config) より優先されるため、
  # 一度だけリネームして HM に主導権を渡す。idempotent。
  home.activation.migrateLegacyGitconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
      $DRY_RUN_CMD mv "$HOME/.gitconfig" "$HOME/.gitconfig.pre-hm.bak"
      echo "moved legacy ~/.gitconfig to ~/.gitconfig.pre-hm.bak (programs.git took over via ~/.config/git/config)"
    fi
  '';

  # Phase 19: user.{name,email} を含むローカル include を bootstrap。dotfiles repo 外なので tracked にならない。
  # 既存ファイルがあれば上書きしない（ホスト毎の上書きを尊重）。
  home.activation.bootstrapGitLocalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    LOCAL_CFG="$HOME/.config/git/config.local"
    if [ ! -f "$LOCAL_CFG" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$LOCAL_CFG")"
      cat > "$LOCAL_CFG" <<'EOF'
# git ホスト固有設定（dotfiles repo 外、git 追跡対象外）。
# user.{name,email} など、公開リポに露出させたくない値をここに記述する。
[user]
  name = taktiks2
  email = deathproof.lee@gmail.com
EOF
      $DRY_RUN_CMD chmod 600 "$LOCAL_CFG"
      echo "git/config.local template created at $LOCAL_CFG"
    fi
  '';
}
