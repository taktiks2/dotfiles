{ ... }:

# helix: モーダルエディタ。最小 enable のみ。
# 設定追加時は programs.helix.settings / programs.helix.languages を利用するか、
# ~/.config/helix を mkOutOfStoreSymlink で dotfiles 配下へ live link する。

{
  programs.helix = {
    enable = true;
  };
}
