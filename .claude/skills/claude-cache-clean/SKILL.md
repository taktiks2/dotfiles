---
name: claude-cache-clean
description: Use when ~/.claude is consuming excessive disk space, when the user mentions slow Claude Code startup, or when asked to clean caches/sessions. Reports sizes, proposes deletions, and only deletes after explicit user confirmation. Never touches projects/, skills/, agents/, commands/, CLAUDE.md, or settings*.json.
---

# claude-cache-clean

`~/.claude` 配下の mutable データ (キャッシュ・古いセッション) を安全に掃除する skill。
**3 段階 (報告 → 提案 → 実行)** を厳守し、消してはいけないものは絶対に消さない。

## 絶対に触らないもの

| パス | 理由 |
|---|---|
| `~/.claude/projects/` | 会話履歴と memory を含む |
| `~/.claude/skills/` `~/.claude/agents/` `~/.claude/commands/` | 設定資産 (dotfiles 管理) |
| `~/.claude/CLAUDE.md` `~/.claude/settings*.json` | 主要設定 |
| `~/.claude/plugins/installed_plugins.json` 等 `*_plugins.json` | プラグイン状態 |
| `~/.claude/.credentials.json` | 認証情報 |

## フロー

### 1. 現状報告

以下のディレクトリのサイズを `du -sh` で計測し表で提示:

- `~/.claude/cache`
- `~/.claude/paste-cache`
- `~/.claude/session-env`
- `~/.claude/file-history`
- `~/.claude/sessions`
- `~/.claude/plugins/cache`
- `~/.claude/homunculus`
- `~/.claude/telemetry`
- `~/.claude/shell-snapshots`

### 2. 削除候補の抽出

| 対象 | 条件 |
|---|---|
| `~/.claude/paste-cache/*` | 全件 (再生成可能) |
| `~/.claude/cache/*` | 全件 |
| `~/.claude/sessions/*` | 30 日以上更新なし |
| `~/.claude/session-env/*` | 30 日以上更新なし |
| `~/.claude/file-history/*` | 30 日以上更新なし |
| `~/.claude/shell-snapshots/*` | 7 日以上更新なし |
| `~/.claude/telemetry/*` | 30 日以上更新なし |

候補数と合計削除サイズを `find ... -printf '%s\n' | awk '{s+=$1} END {print s}'` で算出して提示。

### 3. 実行

ユーザーが明示的に `OK` / `削除して` / `yes` と返したら削除する。
それ以外なら何もしない。`du -sh` で削除後のサイズを再計測し、節約量を報告する。

## 失敗時の対処

- `Permission denied`: `~/.claude` が symlink で実体が別ディスクの場合あり。`readlink ~/.claude` で確認しユーザーに報告
- 削除中の中断: `find ... -delete` ではなく `find ... -print0 | xargs -0 rm` を使い、途中で止まっても部分削除で済むようにする

## Red Flags - 即座に中断すべき状況

- `rm -rf ~/.claude` のような全削除指示が出る → 拒否
- `projects/` `skills/` `agents/` `commands/` を削除候補に含めるような提案 → 自分の出力を見直し中断
- ユーザーが具体的なフォルダを指定せず「全部消して」と言う → 上の表で安全と分類されたものに限る旨を確認
