{ lib, ... }:

# Phase 17: ~/.gitconfig + .config/git/ignore + lazygit pagers/git connection を programs.git / programs.delta に統合。

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
    settings = {
      user.name             = "taktiks2";
      user.email            = "deathproof.lee@gmail.com";
      init.defaultBranch    = "main";
      core.editor           = "nvim";
      merge.conflictstyle   = "diff3";
      diff.colorMoved       = "default";
    };
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
}
