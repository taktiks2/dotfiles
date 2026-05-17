#!/bin/bash
# SessionStart / PreCompact 共用フック。
# - .jj/ が無ければ何もしない（git 運用リポに副作用なし）
# - .jj/ があれば jj status を走らせて auto-snapshot を強制
# - SessionStart のときだけ Claude に jj 用コンテキストを注入
#
# グローバル配置: ~/.claude/hooks/jj-context.sh

set -uo pipefail

# stdin（フック仕様で渡される JSON）を読む。SessionStart だと hook_event_name が入る。
input=$(cat 2>/dev/null || echo "{}")
event=$(echo "$input" | jq -r '.hook_event_name // ""' 2>/dev/null)

# .jj/ がなければ何もしない
[ ! -d .jj ] && exit 0

# auto-snapshot 強制（panozzaj.com パターン）
jj status --no-pager >/dev/null 2>&1 || true

# SessionStart のときだけコンテキストを注入
if [ "$event" = "SessionStart" ]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: "## このリポは jj (Jujutsu) colocated mode で運用中\n\nバージョン管理操作のルール:\n- `git commit / rebase / checkout / switch / reset --hard / cherry-pick / merge / stash` は使わない（PreToolUse hook で自動 deny）\n- 代替: `jj describe -m` / `jj new` / `jj rebase -s X -d Y` / `jj edit <change>` / `jj abandon <change>` / `jj op restore <op-id>` / `jj new`\n- 対話フラグ禁止: `-i`, `--interactive`, `jj resolve`（TUI）, `jj diffedit` はエージェント環境でハングする\n- describe / new には必ず `-m \"msg\"` を渡す（エディタ起動を避ける）\n- conflict は jj では操作を止めない。`jj log` で `(conflict)` 表示、`jj resolve --list` でファイル特定、ファイルを直接編集して保存（auto-snapshot で解決扱い）\n- bookmark は手動で進める。`jj new` の後は `jj tug` で直近 bookmark を `@-` に追従\n- push: `jj git push --change @-`（これは force-push 相当 — レビュー済み PR ブランチには使わない）\n- 誤操作は `jj undo`、深い救済は `jj op log` → `jj op restore <op-id>`\n- `wip:*` プレフィックスの commit は push ガードがかかる（`git.private-commits` 設定）。完成したら describe で wip: を外す\n- ローカル `main` への直接コミット禁止。`jj new main -m \"...\"` で必ず1段上げる\n- 自分の作業範囲は `jj log -r \"(trunk()..@):: | (trunk()..@)-\"` または alias `jj l`"
    }
  }'
fi

exit 0
