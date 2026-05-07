{ ... }:

# lazygit の設定を Nix attrset で宣言。
# 出力先は HM が macOS パスを自動判定する（xdg.enable=false なので ~/Library/Application Support/lazygit/）。
# fish wrapper (LAZYGIT_NEW_DIR_FILE 連携の cd-on-quit) は programs.fish.enable と連動して自動投入。

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
