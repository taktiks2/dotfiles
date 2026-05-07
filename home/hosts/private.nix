{ pkgs, ... }:

# taktiks2 個人の install-specific 差分。
# home/common.nix の baseline を override する形で hard-coded path 等を上書きする。
# 中身は最小スタート (YAGNI)。今後の追加候補:
#   - 個人用追加 packages (home.packages = with pkgs; [ ... ])
#   - 個人 alias (programs.fish.shellAliases.foo = "bar")
#   - 追加の git identity（home/programs/git.nix で定義された option を使う）:
#       my.git.extraIdentities.<id> = {
#         condition       = "hasconfig:remote.*.url:git@github-<id>:<owner>/**";
#         sshHostAlias    = "github-<id>";
#         sshIdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519_<id>";
#       };

{
  home.packages = with pkgs; [
    # ビジュアル / システム
    graphviz
    television

    # 言語ランタイム / ビルド
    zig
    bun
    uv
    sbcl
    cargo-binstall
  ];
  # Zulu JDK 17 を使う install 環境への hard-coded path。
  # 別 username の Mac で別 JDK を使うなら、その user file 側で同様に上書きする。
  home.sessionVariables.JAVA_HOME =
    "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home";
}
