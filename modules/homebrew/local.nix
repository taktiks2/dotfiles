{ ... }:

# ホスト / ユーザ固有の Homebrew 上書き。
#
# このファイルは git tracked だが install.sh が
# `git update-index --skip-worktree` を設定するため、
# 各マシンでのローカル編集は `git status` / `git diff` に現れず、
# 誤って push される心配が無い。
#
# upstream（リポジトリ）側はこの空 stub のまま据え置く。
# 編集例:
#
#   { ... }:
#   {
#     homebrew = {
#       taps  = [ "atlassian-labs/acli" ];
#       brews = [ "awscli" ];
#       casks = [ "alacritty" ];
#     };
#   }
#
# skip-worktree が外れた場合（`git reset` 等）の再設定:
#   git update-index --skip-worktree modules/homebrew/local.nix
# または `./install.sh` 再実行で冪等に復元される。

{
  homebrew = {
    taps  = [ ];
    brews = [ ];
    casks = [ ];
  };
}
