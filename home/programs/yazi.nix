{ ... }:

# yazi: TUI ファイラ。programs.yazi に揃え、fish 統合（`y` ラッパ）を有効化。
# `y` で起動 → q で終了した後、最後にいたディレクトリへ自動 cd される。
#
# 置換規則 (yazi 26.x): %h = hovered, %s = selected paths, %% = literal %。
# `$@` / `$0` は yazi の置換ではなく単なるシェル変数なので run には書かない。

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    # home.stateVersion < 26.05 では legacy 既定 "yy" が選ばれるため、
    # 26.05 で変わった新既定の `y` を明示して warning を黙らせる。
    shellWrapperName = "y";

    settings = {
      # 隠しファイルを常時表示（`.` でトグルも可）。
      mgr.show_hidden = true;

      # opener.edit: yazi 同梱デフォルトは `${EDITOR:-vi} %s` で、EDITOR が yazi 起動時の
      # env に伝わらない経路だと vi/nano にフォールバックする。nvim を直書きして固定。
      opener.edit = [
        { run = "nvim %s"; block = true; desc = "nvim"; for = "unix"; }
      ];

      # Arto.app (macOS Markdown ビューア)。GUI なので orphan で yazi 終了後も生かす。
      opener.arto = [
        { run = "open -a Arto %s"; orphan = true; desc = "Arto.app"; for = "macos"; }
      ];

      # *.md / *.markdown を開くとき、O (opener picker) で arto を最上位に並べる。
      # prepend_rules は yazi デフォルトルールの前段に挿入されるので、
      # mime ベースの "text/*" → edit ルールより先にマッチする。
      open.prepend_rules = [
        { name = "*.md"; use = [ "arto" "edit" "reveal" ]; }
        { name = "*.markdown"; use = [ "arto" "edit" "reveal" ]; }
      ];
    };

    # F3 一発で hovered ファイルを Arto.app に投げる (nvim 側 keymaps.lua:21 と一貫)。
    # `--` 以降は yazi のエスケープ処理を停止する公式推奨イディオム。
    keymap.mgr.prepend_keymap = [
      {
        on = "<F3>";
        run = "shell --orphan -- open -a Arto %h";
        desc = "Open hovered file in Arto.app";
      }
    ];
  };
}
