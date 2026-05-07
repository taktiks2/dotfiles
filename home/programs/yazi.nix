{ ... }:

# yazi: TUI ファイラ。programs.yazi に揃え、fish 統合（`y` ラッパ）を有効化。
# `y` で起動 → q で終了した後、最後にいたディレクトリへ自動 cd される。

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
  };
}
