{ ... }:

# Phase 17: lazygit を programs.lazygit へ移行。
# 旧 ~/Library/Application Support/lazygit/config.yml の YAML を attrset 化。
# 出力先は HM が macOS パスを自動判定する（xdg.enable=false なので AppSupport 側）。
# fish wrapper (LAZYGIT_NEW_DIR_FILE 連携の cd-on-quit) も programs.fish.enable と連動して自動投入。

{
  programs.lazygit = {
    enable = true;
    settings = {
      git.pagers = [
        {
          colorArg = "always";
          pager    = "delta --dark --paging=never";
        }
      ];
    };
  };
}
