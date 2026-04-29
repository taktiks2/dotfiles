{ lib, ... }:

# Phase 23: Claude Code multi-account profile switcher.
# `claude` 自体はラップしない (npm 経由の binary を素のまま実行)。
# `claude-switch <work|private>` で macOS Keychain entry を差し替え、
# `CLAUDE_CONFIG_DIR` を universal variable に永続セットすることで
# 以後の全 fish shell で対応 profile が active になる。
#
# 設計メモ:
#   - macOS の Claude Code は OAuth token を Keychain service "Claude Code-credentials" の
#     **単一エントリ**で保持するため、CLAUDE_CONFIG_DIR を切替えるだけでは認証が分離されない。
#     起動前に "Claude Code-credentials-<profile>" を active に流し込む必要がある。
#   - 同時に 2 profile を別アカウントで起動することは不可（Keychain が共有のため）。
#   - 直前 profile の token は次回 switch 時に backup へ退避（refresh による更新を保持）。
#   - `set -Ux` (universal + exported) は ~/.local/share/fish/fish_variables に永続化され
#     全 fish shell で即時反映される。default に戻すには `set -eU CLAUDE_CONFIG_DIR`。
#
# 共有リソース（~/.claude → ~/.claude-profiles/<profile>/<name> へ symlink）:
#   agents / skills / plugins / CLAUDE.md / settings.json
# Profile 別に独立:
#   credentials / projects / sessions / history / logs / cache 等
#
# 初回セットアップ:
#   1. darwin-rebuild switch で profile dir + symlink を bootstrap
#   2. 既ログイン状態のアカウントを `claude-save-profile <work|private>` で backup
#   3. `claude-switch <other>` → /login → `claude-save-profile <other>` で backup
#   4. 以後 `claude-switch work` / `claude-switch private` で切替え可能

{
  programs.fish.functions = {
    # Keychain entry と CLAUDE_CONFIG_DIR を <profile> に切替える。
    # 直前 profile の最新 token は backup へ退避してから target を load する。
    claude-switch = ''
      set -l profile $argv[1]
      if not contains -- "$profile" work private
          echo "usage: claude-switch <work|private>" >&2
          return 1
      end
      set -l keychain "Claude Code-credentials"
      set -l state $HOME/.claude-profiles/.active

      mkdir -p $HOME/.claude-profiles/$profile

      # 直前 profile の最新 token (refresh 反映済み) を backup に退避
      if test -f $state
          set -l prev (cat $state 2>/dev/null)
          if contains -- "$prev" work private; and test "$prev" != "$profile"
              set -l curr (security find-generic-password -s $keychain -w 2>/dev/null)
              if test -n "$curr"
                  security add-generic-password -U -a "$USER" -s "Claude Code-credentials-$prev" -w "$curr" >/dev/null 2>&1
              end
          end
      end

      # target profile の backup を active に load
      set -l target (security find-generic-password -s "Claude Code-credentials-$profile" -w 2>/dev/null)
      if test -n "$target"
          security add-generic-password -U -a "$USER" -s $keychain -w "$target" >/dev/null 2>&1
      else
          echo "claude-switch: profile '$profile' has no saved credentials yet." >&2
          echo "  /login で認証後、\`claude-save-profile $profile\` で backup を作成してください。" >&2
      end

      set -Ux CLAUDE_CONFIG_DIR $HOME/.claude-profiles/$profile
      echo $profile > $state
      echo "claude-switch: active profile → '$profile'"
    '';

    # 現在 active な profile (work / private) を表示。未設定なら "(unset)"。
    claude-current = ''
      set -l state $HOME/.claude-profiles/.active
      if test -f $state
          set -l profile (cat $state 2>/dev/null)
          if contains -- "$profile" work private
              echo $profile
              return 0
          end
      end
      echo "(unset)"
      return 1
    '';

    # 現在 active の Keychain token を <profile> backup に保存。
    # /login 直後 / token refresh 後の永続化に使う。
    claude-save-profile = ''
      set -l profile $argv[1]
      if not contains -- "$profile" work private
          echo "usage: claude-save-profile <work|private>" >&2
          return 1
      end
      set -l creds (security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
      if test -z "$creds"
          echo "claude-save-profile: active Keychain に Claude Code 認証情報がありません" >&2
          return 1
      end
      security add-generic-password -U -a "$USER" -s "Claude Code-credentials-$profile" -w "$creds" >/dev/null 2>&1
      echo "saved current Claude credentials → profile '$profile'"
    '';
  };

  # Profile ディレクトリを idempotent に bootstrap し、共有リソースを ~/.claude から symlink。
  # link 先に既存ファイル/シンボリックリンクがある場合は触らない（ユーザの手動配置を尊重）。
  home.activation.bootstrapClaudeProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for profile in work private; do
      pdir="$HOME/.claude-profiles/$profile"
      $DRY_RUN_CMD mkdir -p "$pdir"
      for shared in agents skills plugins CLAUDE.md settings.json; do
        target="$HOME/.claude/$shared"
        link="$pdir/$shared"
        if [ -e "$target" ] && [ ! -e "$link" ] && [ ! -L "$link" ]; then
          $DRY_RUN_CMD ln -s "$target" "$link"
        fi
      done
    done
  '';
}
