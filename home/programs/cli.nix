{ ... }:

# 「設定なしで enable のみ」の小物 CLI。programs.* で宣言することで shell integration / fish hook が自動付く。

{
  # `bat` — `cat` クローン。programs.fish.enable と連動して fish 補完が自動。
  programs.bat.enable = true;

  programs.fzf = {
    enable = true;
    # programs.fish.enable と連動して enableFishIntegration は自動 true（HM 25.11 仕様）。
    # bash / zsh も同様。Ctrl-T (file)、Ctrl-R (history)、Alt-C (cd) のキーバインドが入る。
  };

  programs.lsd = {
    enable = true;
    # HM 25.11 で旧 enableAliases は廃止され、enableFishIntegration（programs.fish 連動で自動 true）
    # が `ls / la = lsd -A / ll = lsd -lA` を inject する。
    # 既存の programs.fish.shellAliases (la = "lsd -a", ll = "lsd -al") と衝突するため、
    # behavior 維持のため Fish integration を明示的に無効化。
    enableFishIntegration = false;
    enableBashIntegration = false;
    enableZshIntegration  = false;
  };
}
