{ ... }:

# ホスト固有の home-manager 差分。
#
# このファイルは git tracked だが install.sh が
# `git update-index --skip-worktree` を設定するため、
# 各マシンでのローカル編集は `git status` / `git diff` に現れず、
# 誤って push される心配が無い。
#
# upstream（リポジトリ）側はこの空 stub のまま据え置く。
# 編集例:
#
#   { pkgs, config, ... }:
#   {
#     home.packages = with pkgs; [ eza gum ];
#     home.sessionVariables.JAVA_HOME = "/path/to/jdk";
#     programs.fish.interactiveShellInit = ''
#       fnm env --use-on-cd --shell fish | source
#     '';
#   }
#
# skip-worktree が外れた場合（`git reset` 等）の再設定:
#   git update-index --skip-worktree home/hosts/work.nix
# または `./install.sh` 再実行で冪等に復元される。

{ }
