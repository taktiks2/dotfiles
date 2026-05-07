{ pkgs, username, ... }:

# Phase 8: tmux 完全宣言化。TPM 撤廃、plugins は Nix 経由で配布。
# tmux.conf は HM が programs.tmux 設定から生成するため、~/dotfiles/.config/tmux/ 側は不要。
# Phase 18 (modular split): home/taktiks2.nix から本ファイルへ抜き出し（Phase 21 で taktiks2.nix → common.nix へ rename）。username は specialArgs から受け取る。

{
  programs.tmux = {
    enable = true;
    prefix = "C-s";
    keyMode = "vi";
    terminal = "tmux-256color";
    mouse = true;
    baseIndex = 1;
    focusEvents = true;
    escapeTime = 0;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      copycat
      pain-control
      yank
      {
        plugin = resurrect;
        extraConfig = ''
          # save は prefix + S に再割当て（デフォルト C-s C-s は prefix と同指連打で打ち間違えやすい）。
          # restore は prefix + R に移設（sensible が R に持っていた reload-config は extraConfig 末尾で C-r に再配置）。
          set -g @resurrect-save 'S'
          set -g @resurrect-restore 'R'
        '';
      }
      continuum
      logging
      {
        plugin = tokyo-night-tmux;
        extraConfig = ''
          set -g @theme_left_separator '${""}'
          set -g @theme_right_separator '${""}'
          set -g @theme_enable_icons '0'
        '';
      }
    ];

    extraConfig = ''
      # ペインのインデックスも 1 から（programs.tmux.baseIndex は window のみ）
      setw -g pane-base-index 1

      # Shift+Enter / Ctrl+Shift+* 等の拡張キー（CSI u）を内側アプリへ転送する。
      # Claude Code は Ghostty/kitty 由来の CSI u を期待しているが、tmux のデフォルトは off で
      # `\r` に丸めてしまう。`always` でアプリの要求有無に関わらず CSI u 形式で常時転送。
      set -s extended-keys always
      # 外側ターミナル（xterm-ghostty 含む）が extkeys 対応であることを tmux に宣言。
      set -as terminal-features ",xterm*:extkeys"

      # ghostty (TERM=xterm-ghostty) の RGB / 装飾系ケイパビリティ
      set -as terminal-features ",xterm-ghostty*:RGB:usstyle:hyperlinks:ccolour:cstyle:strikethrough:overline"
      # 旧 Tc フラグでのフォールバック
      set -ag terminal-overrides ",xterm-ghostty:Tc"
      set -ag terminal-overrides ",*256col*:Tc"

      # シェルのデフォルトを fish に。nix-darwin が公開する system fish を参照。
      # tmux on macOS は default-command を reattach-to-user-namespace -l /bin/zsh
      # に焼き付けてくる（default-shell より優先される）ので、ここで上書きする。
      set-option -g default-shell /run/current-system/sw/bin/fish
      set-option -g default-command /run/current-system/sw/bin/fish
      set-environment -g PATH "/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/bin:/bin"

      # lazygit をポップアップで開く（prefix + g）
      bind g display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "lazygit"

      # gh dash をポップアップで開く（prefix + G）
      bind G display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "gh dash"

      # workmux dashboard をポップアップで開く（prefix + W）
      bind W display-popup -E -w 50% -h 100% -d "#{pane_current_path}" "workmux dashboard"

      # workmux 連動キー
      bind i run-shell "workmux last-done"
      bind e run-shell "workmux sidebar"
      bind -n M-j run-shell "workmux sidebar next"
      bind -n M-k run-shell "workmux sidebar prev"
      bind -n M-1 run-shell "workmux sidebar jump 1"
      bind -n M-2 run-shell "workmux sidebar jump 2"
      bind -n M-3 run-shell "workmux sidebar jump 3"
      bind -n M-4 run-shell "workmux sidebar jump 4"
      bind -n M-5 run-shell "workmux sidebar jump 5"
      bind -n M-6 run-shell "workmux sidebar jump 6"
      bind -n M-7 run-shell "workmux sidebar jump 7"
      bind -n M-8 run-shell "workmux sidebar jump 8"
      bind -n M-9 run-shell "workmux sidebar jump 9"

      # btop / lazydocker をポップアップで開く
      bind b display-popup -E -w 90% -h 90% "btop"
      bind C display-popup -E -w 90% -h 90% "lazydocker"

      # config reload。sensible の prefix + R から prefix + C-r に移設（R は resurrect restore に譲った）。
      bind C-r run-shell "tmux source-file ~/.config/tmux/tmux.conf > /dev/null; tmux display-message 'Sourced tmux.conf'"
    '';
  };
}
