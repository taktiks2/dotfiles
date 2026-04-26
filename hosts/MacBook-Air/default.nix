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
  # 弾かれ SIGKILL される問題への対症療法。
  # 症状: `kernel: CODE SIGNING: cs_invalid_page ... denying page sending SIGKILL`
  # 対策: rebuild 後に ad-hoc 再署名でハッシュを引き直す（冪等）。
  # 検証: `log show --predicate 'eventMessage CONTAINS "fish"'` で SIGKILL 履歴確認。
  # 注意点:
  #   - 旧実装の `readlink` は 1 段しか辿らないため `realpath` で完全解決する。
  #     macOS には `/usr/bin/realpath` が無い (macOS 26 Tahoe で確認、おそらく以前から存在しない)
  #     ため、Nix の coreutils 由来 `realpath` を絶対パスで呼ぶ。
  #     pkgs.coreutils は flake 評価時点で固定されるため activation の PATH に依存しない。
  #   - `chmod u+w` は /nix/store のパーミッション (mode 555) を一時的に書込可へ変更する。
  #     Determinate Nix の store は rw-mounted のため root で動く activation から書込可能。
  #   - 失敗時は WARN ログを出すのみで activation 全体は continue する。
  #     ただし旧実装のように全エラーを `2>/dev/null || true` で握り潰さない。
  #     再署名が無効化される事象（=fish SIGKILL 再発）を検知できるようにする。
  #   - upstream (nixpkgs#461406 など) で fix backport が確認できたら本ブロックごと撤廃する。
  system.activationScripts.postActivation.text = ''
    echo "[fish-resign] re-signing fish to bypass macOS page integrity issue..."
    fish_link="/run/current-system/sw/bin/fish"
    if [ ! -L "$fish_link" ] && [ ! -f "$fish_link" ]; then
      echo "[fish-resign] skipped: $fish_link not present"
    else
      fish_bin="$(${pkgs.coreutils}/bin/realpath "$fish_link" 2>/dev/null || true)"
      if [ -z "$fish_bin" ] || [ ! -f "$fish_bin" ]; then
        echo "[fish-resign] WARN: failed to resolve $fish_link"
      else
        fish_dir="$(${pkgs.coreutils}/bin/dirname "$fish_bin")"
        if /bin/chmod u+w "$fish_dir" "$fish_bin" 2>/dev/null; then
          if /usr/bin/codesign --force --sign - "$fish_bin"; then
            echo "[fish-resign] done: $fish_bin"
          else
            echo "[fish-resign] WARN: codesign failed for $fish_bin"
          fi
          /bin/chmod 555 "$fish_bin" "$fish_dir" 2>/dev/null || true
        else
          echo "[fish-resign] WARN: cannot chmod $fish_bin (read-only store?)"
        fi
      fi
    fi
  '';
}
