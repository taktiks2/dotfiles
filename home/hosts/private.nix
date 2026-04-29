{ ... }:

# Phase 21: taktiks2 個人の install-specific 差分。
# home/common.nix の baseline を override する形で hard-coded path 等を上書きする。
# 中身は最小スタート (YAGNI)。今後の追加候補:
#   - 個人用追加 packages (home.packages = with pkgs; [ ... ])
#   - 個人 alias (programs.fish.shellAliases.foo = "bar")
#   - 個人 git identity (programs.git.includes に gitdir 条件)

{
  # Zulu JDK 17 を使う install 環境への hard-coded path。
  # 別 username の Mac で別 JDK を使うなら、その user file 側で同様に上書きする。
  home.sessionVariables.JAVA_HOME =
    "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home";
}
