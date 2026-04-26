---
name: project-plan
description: Use when the user asks to plan a new feature, refactor, or non-trivial change in this project, before any implementation. Produces a concise written plan with intent restatement, impact analysis, recommended approach with one alternative, file list, test strategy (TDD), and verification steps. Does NOT touch code.
---

# project-plan

このプロジェクトの実装プランを立てる skill。実装には着手せず、設計のみを返す。

## 前提

- このプロジェクトの `CLAUDE.md` は読んだ前提
- TDD を採用 (テスト先行)

## フロー

1. **意図の確認**: ユーザー要求を 2 行で言い換え。何を達成したいのか / なぜ必要なのか
2. **影響範囲の調査**:
   - `rg` / `grep` で関連ファイルを洗い出す
   - 既存パターンや再利用可能なユーティリティを探す (新規実装より優先)
3. **設計**:
   - 推奨アプローチ 1 つ + 主要な代替案 1 つ
   - 各案のトレードオフ (複雑度・将来の拡張性・テスト容易性) を 1 行で
4. **影響を受けるファイル一覧**: パス + 操作 (新規 / 編集 / 削除)
5. **テスト計画**:
   - TDD 順序: どんなテストを先に書き、何を verify するか
   - 既存テストの修正範囲
6. **検証手順**: 実装後に走らせるコマンドと動作確認ステップ
7. **確認**: 「この方針で進めて良いか」をユーザーに **1 度だけ** 聞いてから実装に移る

## 出力フォーマット

```
## Intent
<2 行>

## Impact
<関連ファイルと既存パターンの要約>

## Approach
**推奨**: <1-2 行>
**代替**: <1 行>
**選定理由**: <1 行>

## Files
- `path/to/file.ts` — 編集 (関数 X を追加)
- ...

## Test Plan
1. ...
2. ...

## Verification
- `npm test` / `cargo test` / ...
- 手動確認: ...
```

## やらないこと

- 実装コードを書く
- 設計とは無関係な refactor を勧める
- 「将来こうなるかも」という仮想要件への対応を含める
- 1 度の確認で OK が出ない場合に「とりあえず実装する」
