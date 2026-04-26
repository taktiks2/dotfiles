{ pkgs, username, hostname, ... }:

{
  imports = [
    ../../modules/macos-defaults.nix
    ../../modules/homebrew.nix
  ];

  # Nix 自体の管理は flake 側で `determinate.darwinModules.default` + `determinateNix.enable = true`
  # により Determinate に委譲済み（nix-darwin の `nix.*` は自動で disable される）。
  # https://docs.determinate.systems/guides/nix-darwin/

  # nix-darwin 25.05 以降で必須。home-manager 等のユーザ向け機能で使用される。
  system.primaryUser = username;

  # 設定の互換性バージョン（後方互換のため固定）。
  system.stateVersion = 6;

  # Phase 6: Apple Silicon の system は flake.nix で `inherit system` 渡し済のため
  # `nixpkgs.hostPlatform` の重複指定は削除。

  # 救出用ツール: home-manager がぶっ壊れた緊急時にも
  # /run/current-system/sw/bin/{git,vim} で復旧できるよう確保。
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  networking.hostName = hostname;
  networking.computerName = "MacBook Air";

  # ユーザ定義（home-manager がホームディレクトリ解決に参照する）
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # zsh は既存ユーザ環境を尊重し、interactive shell の初期化のみ有効化。
  programs.zsh.enable = true;

  # fish を system level で有効化:
  #   - /run/current-system/sw/bin/fish が公開される（Alacritty / Ghostty 等の terminal config から参照）
  #   - /etc/fish/config.fish がシステム準備（Nix profile 等の PATH を全 fish セッションに注入）
  # 実際のユーザ向け設定は home-manager の programs.fish 側で行う。
  programs.fish.enable = true;

  # /etc/shells への登録（chsh で fish を選択可能にするため）。
  environment.shells = [ pkgs.fish ];

  # fish 4.2.x の Mach-O linker-signed が Apple Silicon の page integrity 検証で
  # 弾かれ SIGKILL される問題への恒久対策。
  # 症状: `kernel: CODE SIGNING: cs_invalid_page ... denying page sending SIGKILL`
  # 対策: rebuild 後に ad-hoc 再署名でハッシュを引き直す（冪等）。
  # 参考: 直近のクラッシュは `log show --predicate 'eventMessage CONTAINS "fish"'` で確認可。
  system.activationScripts.postActivation.text = ''
    echo "[fish-resign] re-signing fish to bypass macOS page integrity issue..."
    fish_bin="$(/usr/bin/readlink /run/current-system/sw/bin/fish || true)"
    if [ -n "$fish_bin" ] && [ -f "$fish_bin" ]; then
      fish_dir="$(/usr/bin/dirname "$fish_bin")"
      /bin/chmod u+w "$fish_dir" "$fish_bin" 2>/dev/null || true
      /usr/bin/codesign --force --sign - "$fish_bin" 2>/dev/null || true
      /bin/chmod 555 "$fish_bin" "$fish_dir" 2>/dev/null || true
      echo "[fish-resign] done: $fish_bin"
    else
      echo "[fish-resign] skipped: fish binary not found"
    fi
  '';
}
