{ ... }:

# Step 6: direnv + nix-direnv（プロジェクト単位の devShell 自動有効化）
#
# NOTE: direnv の `doCheck = false` overlay は flake.nix 側に残置している。
#   nixpkgs#82606 (macOS sandbox 内の fish/zsh test SIGKILL) は 2026-04 時点で未解消。
#   upstream fix が landing したら flake.nix の overlay と本コメントを同時撤廃する。

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # HM 25.11 から enable*Integration は programs.<shell>.enable と連動して
    # 自動有効化される read-only オプションになったため、明示指定を撤廃。
    # bash / zsh / fish は既に programs.* で管理されているため自動 hook される。
  };
}
