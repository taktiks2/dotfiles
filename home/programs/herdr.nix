{ pkgs, ... }:

# herdr のパッケージ導入と設定を集約。
# home-manager に programs.herdr モジュールは無いため、pkgs.formats.toml で
# Nix attrset から config.toml を生成する。パッケージは flake input の overlay 経由 (pkgs.herdr)。
#
# 生成される ~/.config/herdr/config.toml は store 内 read-only symlink なので、
# herdr の Settings UI / onboarding / `herdr config reset-keys` からの書き込みは失敗する。
# 設定変更はこのファイルを編集して darwin-rebuild switch → `herdr server reload-config`。
# onboarding = false は初回起動時の config.toml 書き込みを回避するために必須。
#
# キーバインドは tmux (./tmux.nix) と同じ操作感に揃える。
# デフォルトと同じキー（c / n / p / 1..9 / h,j,k,l / z / x / w / [）は設定不要。
# ユーザー設定がデフォルトと衝突した場合はデフォルト側が自動で unbind される。
#
# 移植しないもの:
#   - H/J/K/L ステップリサイズ（herdr は prefix+r のリサイズモード方式のみ）
#   - workmux 連動キー（workmux は tmux の pane を直接操作するため herdr 内では動作しない）
#   - resurrect/continuum の S/R（herdr はネイティブのセッション永続化を標準装備）

let
  tomlFormat = pkgs.formats.toml { };

  settings = {
    onboarding = false;

    keys = {
      # tmux と同じ prefix (C-s)
      prefix = "ctrl+s";

      # ワークスペース切替はデフォルト未割当のため割当てる。
      # workmux sidebar (./tmux.nix の M-j / M-k / M-1..9) と同じ prefix 無しの直接キー。
      # alt 系は Ghostty の macos-option-as-alt = true (./terminal.nix) が前提。
      # prefix+shift+j/k は swap_pane_down/up の隠れデフォルトと被るため使わない
      # (--default-config には出ないが v0.7.1 src/config/model.rs で prefix+shift+h/j/k/l)。
      next_workspace = "alt+j";
      previous_workspace = "alt+k";
      switch_workspace = "alt+1..9";

      # worktree の open / 削除もデフォルト未割当。キーは公式 docs の例に合わせる。
      # remove は確認ダイアログ付きで git worktree remove を実行（ブランチは消さない）。
      open_worktree = "prefix+shift+o";
      remove_worktree = "prefix+alt+d";

      # goto (セッションナビゲーター) はデフォルト g を lazygit に譲り alt+g へ移設。
      goto = "prefix+alt+g";

      # tmux の display-popup 相当。type = "pane" は一時ペインで開き、終了で閉じる。
      command = [
        { key = "prefix+g";       type = "pane"; command = "lazygit";    description = "lazygit"; }
        # f = diff。素の f は working tree、shift+f はベースブランチ指定。
        { key = "prefix+f";       type = "pane"; command = "hunk diff";    description = "hunk diff"; }
        # ベースブランチを fzf で選んで hunk diff <base>..HEAD を開く。
        # type = "pane" は /bin/sh -c の実 PTY 実行なので対話コマンド (fzf) が使える。
        {
          key = "prefix+shift+f";
          type = "pane";
          command = "base=$(git branch --sort=-committerdate --format='%(refname:short)' | fzf --prompt='base branch> ') && hunk diff \"$base..HEAD\"";
          description = "hunk diff vs base";
        }
        { key = "prefix+shift+c"; type = "pane"; command = "lazydocker"; description = "lazydocker"; }
      ];
    };

    # tmux 側の tokyo-night-tmux テーマに合わせる
    theme.name = "tokyo-night";
  };
in
{
  home.packages = [ pkgs.herdr ];

  xdg.configFile."herdr/config.toml".source =
    tomlFormat.generate "herdr-config.toml" settings;
}
