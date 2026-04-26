{ ... }:

# Step 6: direnv + nix-direnv（プロジェクト単位の devShell 自動有効化）
# direnv の doCheck=false overlay とその理由は flake.nix を参照。

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # HM 25.11 から enable*Integration は programs.<shell>.enable と連動して
    # 自動有効化される read-only オプションになったため、明示指定を撤廃。
    # bash / zsh / fish は既に programs.* で管理されているため自動 hook される。
  };
}
