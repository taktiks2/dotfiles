{ ... }:

# alacritty / ghostty を programs.* で管理。両者とも cask 経由の .app 配布なので Nix package は不要 (package = null)。

{
  programs.alacritty = {
    enable  = true;
    package = null;  # alacritty は modules/homebrew/default.nix の cask 経由でインストールされるため Nix package は不要
    # Shift+Return で ESC (0x1B) + CR を送出。
    # Nix の文字列リテラルは \u 16 進エスケープ非対応のため、JSON 経由で ESC を生成。
    settings = {
      keyboard.bindings = [
        {
          key   = "Return";
          mods  = "Shift";
          chars = (builtins.fromJSON "\"\\u001b\"") + "\r";
        }
      ];
    };
  };

  programs.ghostty = {
    enable  = true;
    package = null;  # ghostty は modules/homebrew/default.nix の cask 経由でインストールされるため Nix package は不要（macOS の ghostty は .app 配布）
    settings = {
      command       = "/run/current-system/sw/bin/fish";
      font-family   = "HackGen Console NF";
      font-size     = 10;
      font-thicken  = true;
      theme         = "TokyoNight Night";
      # Option キーを Alt 修飾子として扱う（macOS デフォルトの Unicode 入力モードを無効化）。
      # tmux の `bind -n M-*` 系キーバインドが届くようにするため。
      macos-option-as-alt = true;
    };
  };
}
