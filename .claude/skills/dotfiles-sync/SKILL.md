---
name: dotfiles-sync
description: Use when the user asks to sync, update, or apply dotfiles changes — pulls latest from origin, rebuilds the nix-darwin system, and reports the diff. Specific to ~/dotfiles managed with flake.nix + nix-darwin + home-manager.
---

# dotfiles-sync

`~/dotfiles` を最新化して `darwin-rebuild switch` で適用する手順をまとめた skill。新しい設定を取り込みたいとき・複数マシン間で同期を取りたいときに使う。

## 前提

- `~/dotfiles` が git 管理されている
- `nix`、`darwin-rebuild` が PATH にある (`/run/current-system/sw/bin/`)
- ホスト名が `MacBook-Air` (異なる場合は flake から該当 host を選ぶ)

## フロー

1. **作業ツリーの確認**: `git -C ~/dotfiles status --short` を実行。未コミット変更があれば中断し、ユーザーに「先にコミット/stash するか」を確認する
2. **fetch + 変更プレビュー**: `git -C ~/dotfiles fetch origin` → `git -C ~/dotfiles log --oneline HEAD..origin/main` で取り込む差分を提示
3. **fast-forward**: `git -C ~/dotfiles pull --ff-only` で更新
4. **適用**: `sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/dotfiles#MacBook-Air`
   - 失敗したら最後の 50 行を抜粋して報告
   - `Building` フェーズで時間がかかるのは正常 (sudo タイムアウトに注意)
5. **検証**: `claude --version`、`fish --version`、`nvim --version | head -1` で主要ツールが動作するか確認
6. **差分要約**: `git -C ~/dotfiles log -p HEAD@{1}..HEAD -- '.claude/' 'home/' 'modules/' 'flake.nix'` の主要変更を 3 行以内で要約

## やらないこと

- `nix flake update` は **実行しない** (lock 固定運用、別途明示要求があれば実行)
- `sudo darwin-rebuild --rollback` は障害時のみ、ユーザー確認の上で
- `git pull --rebase` や `--no-ff` への変更
- 強制的な `git reset` や `git stash drop`

## 失敗時の対処

| 症状 | 対処 |
|---|---|
| `darwin-rebuild: command not found` | `/run/current-system/sw/bin/darwin-rebuild` のフルパスで再試行 |
| `error: builder for ... failed` | 最後の `error:` 行 + 直後 20 行を抜粋し報告。修正は加えない |
| `Permission denied` (sudo) | sudo タイムアウト切れ。ユーザーにパスワード入力を依頼 |
| `non-fast-forward` | ローカルに未 push のコミットあり。ユーザーに rebase か force-pull を選んでもらう |

## 関連

- `~/dotfiles/install.sh` — 初回ブートストラップ用 (このスキルは「適用済み環境の更新」専用)
- `~/dotfiles/docs/nix-adoption-report.md` — Nix 化の経緯と原則
