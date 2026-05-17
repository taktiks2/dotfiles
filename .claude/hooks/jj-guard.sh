#!/bin/bash
# PreToolUse Bash フック。
# - .jj/ がある（colocated mode）リポでは git の書き込み系コマンドを deny し、jj 等価コマンドを Claude に提示
# - jj の対話フラグ（agent 環境でハング）も deny
# - .jj/ がなければ完全 no-op（git 運用リポに副作用なし）
#
# グローバル配置: ~/.claude/hooks/jj-guard.sh

set -uo pipefail

# .jj/ がなければ何もしない
[ ! -d .jj ] && exit 0

input=$(cat 2>/dev/null || echo "{}")
tool=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$tool" != "Bash" ] && exit 0

cmd=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$cmd" ] && exit 0

deny() {
  jq -n --arg msg "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $msg
    }
  }'
  exit 0
}

# 1. git の書き込み系をブロック（colocated mode で jj 状態を破壊する可能性）
if echo "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+(commit|rebase|reset|checkout|switch|cherry-pick|merge|revert|stash|am|apply)\b'; then
  deny "このリポは jj colocated mode（.jj/ 検出）。git の書き込み系コマンドは jj 状態を破壊する可能性があるためブロックされた。

代替コマンド:
  git commit -m       → jj describe -m / 新規なら jj new -m
  git rebase          → jj rebase -s <change> -d <dest>
  git checkout <ref>  → jj edit <change>  または  jj new <change>
  git switch          → jj edit <change>
  git reset --hard    → jj op restore <op-id>  または  jj abandon <change>
  git cherry-pick     → jj duplicate -r <change> -d <dest>
  git merge           → jj new <A> <B>（複数親で merge commit）
  git stash           → jj new（自動で seal される。stash 不要）

git status / git log / git diff / git show は read-only なので使用OK。"
fi

# 2. jj の対話フラグをブロック（agent 環境でハング）
if echo "$cmd" | grep -qE '\bjj\b.*(\-\-interactive|[[:space:]]\-i([[:space:]]|$))'; then
  deny "jj の対話フラグ（-i / --interactive）はエージェント環境でハングする。-m \"msg\" などの非対話形式を使うこと。
例: jj squash --interactive → jj squash --from <X> --into <Y>"
fi

# 3a. jj diffedit をブロック（TUI 起動でハング）
if echo "$cmd" | grep -qE '\bjj[[:space:]]+diffedit\b'; then
  deny "jj diffedit は TUI を起動するためエージェント環境でハングする。
代替: 該当 change に jj edit <change> で乗り換え、ファイルを直接編集してください。"
fi

# 3b. jj resolve は --list 以外をブロック（--list は read-only な一覧表示、安全）
if echo "$cmd" | grep -qE '\bjj[[:space:]]+resolve\b' && \
   ! echo "$cmd" | grep -qE '\bjj[[:space:]]+resolve[[:space:]]+--list([[:space:]]|$)'; then
  deny "jj resolve（--list 以外）はマージツールを起動するためエージェント環境でハングする。
解決手順:
  1. jj resolve --list で conflict 持ちファイルを特定（このコマンドは許可されている）
  2. ファイルを直接編集（<<<<<<< / ======= / >>>>>>> マーカーを直に書き換える）
  3. 保存すれば auto-snapshot で解決扱いになる"
fi

exit 0
