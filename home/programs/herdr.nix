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

      # tmux の display-popup 相当。type = "pane" は一時ペインで開き、終了で閉じる。
      command = [
        { key = "prefix+g";       type = "pane"; command = "lazygit";    description = "lazygit"; }
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
