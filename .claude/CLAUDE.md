# CLAUDE.md

## Conversation Guidelines

- 常に日本語で会話する
- 端的に答える。差分の後に冗長な要約を書かない（`git diff` で見れば分かる内容を繰り返さない）
- ファイルや関数を参照するときは `path:line` の形式で示し、ユーザーが即ジャンプできるようにする

## Development Philosophy

### Test-Driven Development (TDD)

- 原則としてテスト駆動開発（TDD）で進める
- 期待される入出力に基づき、まずテストを作成する
- 実装コードは書かず、テストのみを用意する
- テストを実行し、失敗を確認する
- テストが正しいことを確認できた段階でコミットする
- その後、テストをパスさせる実装を進める
- 実装中はテストを変更せず、コードを修正し続ける
- すべてのテストが通過するまで繰り返す

## Safe Operations

- 破壊的操作（`rm -rf`、`git push --force`、`git reset --hard`、DB の DROP など）は、明示的な依頼が無い限り実行しない。実行する場合も対象パス・対象ブランチを必ず確認してから走らせる
- pre-commit / pre-push フックを `--no-verify` で回避しない。失敗したら原因を直す
- 認証情報を含むファイル（`.env*`、`secret-env.fish`、`~/.aws/credentials`、`~/.ssh/id_*`、`*credentials*`）は読まない・コミットしない
- `sudo` を要する操作は、ユーザーに確認してから提案する
- 共有状態を変える操作（`git push`、PR 作成、外部サービスへの投稿）は、スコープが明示されている場合だけ実行する

## Memory

- 永続メモリは `~/.claude/projects/-Users-taktiks2-dotfiles/memory/` に格納する
- ユーザーの役割・嗜好・フィードバック・進行中プロジェクトの背景など「次回会話で役立つ情報」のみ保存する
- 「コードを読めば分かること」「git log で分かること」は保存しない
