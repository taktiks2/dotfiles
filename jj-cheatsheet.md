# jj 実務チートシート

Solo-jj × team-git の colocated 運用を前提とした、自分用の作業フローと早見表。

## 目次

- [前提と設定](#前提と設定)
- [1日のリズム](#1日のリズム)
- [コマンド早見表](#コマンド早見表)
- [レシピ](#レシピ)
- [罠と回避](#罠と回避)
- [緊急復旧](#緊急復旧)
- [補足](#補足)

---

## 前提と設定

### 設定の置き場所

| 項目 | パス | 管理 |
|---|---|---|
| 宣言的設定 | `~/.config/jj/config.toml` | symlink → Nix store（read-only） |
| identity / 署名鍵 | `~/.config/jj/local.toml` | host-local、git untracked |
| 設定ソース | `~/dotfiles/home/programs/jujutsu.nix` | dotfiles |
| repo 単位の上書き | `~/.config/jj/repos/<hash>/config.toml` | jj が自動管理 |

設定変更は `jujutsu.nix` を編集 → `sudo darwin-rebuild switch --flake ~/dotfiles#private` で反映。

### 仕込まれている仕掛け

| 機能 | 設定キー | 効果 |
|---|---|---|
| `wip:*` push ガード | `git.private-commits = "description(glob:'wip:*')"` | description が `wip:` 始まりの change は push 拒否 |
| `tug` alias | `bookmark move --from closest_bookmark(@-) --to @-` | 直近 bookmark を `@-` まで追従 |
| Lazy signing | `signing.behavior = "drop"` + `git.sign-on-push = true` | 履歴編集中は無署名／push 瞬間に SSH 鍵で署名 |
| `immutable_heads()` | `present(trunk()) | tags() | remote_bookmarks()` | 不変保護を保守的に |
| `stack()` revset | `ancestors(reachable(@, mutable()), 10)` | `jj log -r 'stack()'` で現スタック |
| `l` alias | `log -r '(trunk()..@):: | (trunk()..@)-'` | 作業範囲だけ log |
| `ll` alias | `log --limit 20` | 上から20件 |
| `s` alias | `status` | st |
| `si` alias | `squash --interactive` | partial squash |

### colocated mode の前提

- 既存 git リポに `jj git init --colocate` で `.jj/` を同居させる
- `.gitignore` に `/.jj/` を追加（チームに jj を強制しない）
- git 書き込み系（`git rebase`, `git commit`, `git checkout`）は使わず、jj に統一する

---

## 1日のリズム

### 朝（取り込み）

```bash
jj git fetch
jj bookmark move main --to main@origin
jj rebase -d main -s 'roots(main..@)'    # in-flight 作業を最新 main に再着地
jj l                                       # 作業範囲を確認
```

#### 朝の3行を読み解く

「リモートが進んだので、ローカル main と自分の作業をその上に乗せ替える」一連動作。

**状態遷移**:

```
fetch 直前:
  ○  main, main@origin   ← 両方とも commit X
  │
  ○  自分の作業（X の上）

fetch 直後:
  ○  main@origin         ← Y（チームが push した最新）
  │
  ○  main                ← X（ローカルは古いまま）
  │
  ○  自分の作業          ← まだ X の上に取り残されている

bookmark move 後:
  ○  main, main@origin (Y)
  │
  ○  X（孤立した古い main 位置）
  │
  ○  自分の作業          ← X の上で取り残されたまま

rebase 後:
  ○  main, main@origin (Y)
  │
  ○  自分の作業          ← Y の上に再着地
```

**コマンド別の役割**:

| コマンド | 役割 |
|---|---|
| `jj git fetch` | リモートを取得して `main@origin` を最新（Y）に更新。ローカルは未変更 |
| `jj bookmark move main --to main@origin` | ローカル `main` ラベルを Y に動かす。**作業 commit には触らない** |
| `jj rebase -d main -s 'roots(main..@)'` | 自分の作業 stack を新 main の上に再着地。stack が空なら no-op |
| `jj l` | 結果確認（trunk..@ + 親子1段） |

**rebase のフラグ分解**:

- `-d main` = destination = いま動かしたばかりの新 main（Y）
- `-s 'roots(main..@)'` = source = 自分の作業 stack の最下段
  - `main..@` = main から @ までの自分の in-flight 作業
  - `roots(...)` = その集合の中で親を持たない最下段
- `-s` で最下段を渡せば、子孫すべてが一緒に動く（stack 全体が再着地）

**git 流との対比**:

```bash
git checkout main && git pull --ff-only       # = jj bookmark move main --to main@origin
git checkout my-feature && git rebase main    # = jj rebase -d main -s 'roots(main..@)'
```

jj 版の優位:
- stack が複数 commit でも 1 コマンド（git は branch ごとに rebase）
- 競合があっても**操作は止まらず**、conflict 持ち commit として記録される
- 作業 stack が空なら自動的に no-op（git は何かしらエラーが出がち）

### 開発中

```bash
jj new main -m "wip: 機能X"      # wip: 始まりは push ガードに引っかかる
# 編集（@ に自動スナップショット、git add 不要）
jj describe -m "feat: 機能X — 検索ロジック追加"
jj new                            # 次のキャンバスへ
jj tug                            # bookmark を @- まで追従
```

### PR を出す

**bookmark の流儀（2つから選ぶ）**:

| 流儀 | 向く場面 |
|---|---|
| **A. 名前付き bookmark**（推奨） | チーム規約あり、長寿命 PR、CI が branch 名を検証 |
| B. `--change` 自動命名 | 個人作業、短命 PR、スタック中間層、命名コスト省きたい |

#### A. 名前付き bookmark

```bash
<プロジェクトの validate>            # git hooks は走らないので手動
jj describe @- -m "feat: 機能X — 検索ロジック追加"   # wip: を外す
jj bookmark create feat/x-search -r @-               # チーム規約に合わせた命名
jj git push -b feat/x-search
gh pr create --fill --head feat/x-search
```

#### B. `--change` で自動命名

```bash
<プロジェクトの validate>
jj describe @- -m "feat: 機能X — 検索ロジック追加"
jj git push --change @-              # push-<change-id> という bookmark を自動生成
gh pr create --fill
```

### レビュー指摘に対応

```bash
jj edit <指摘 change>
# 修正（auto-snapshot）

# A. 名前付き bookmark なら: 同じ bookmark を新位置に動かして再 push
jj bookmark move feat/x-search --to <change>
jj git push -b feat/x-search

# B. --change 流儀なら: そのまま再 push（同じ push-<id> bookmark が動く）
jj git push --change <change>
```

どちらも force-push 相当。子 commit は自動 rebase される。

### マージ後

```bash
jj git fetch
jj bookmark move main --to main@origin
jj abandon <旧 change>             # main@origin に取り込まれた古い change を片付け
jj bookmark delete feat/x-search   # A 流儀なら自分で付けた名前 / B 流儀なら push-<id>
```

---

## コマンド早見表

### 状態を見る

| やりたいこと | コマンド |
|---|---|
| カレント状態 | `jj s` |
| 自分の作業範囲 | `jj l` |
| 直近20件 | `jj ll` |
| 単一 change の中身 | `jj show <id>` |
| 任意 change の差分 | `jj diff -r <id>` |
| WIP だけ抽出 | `jj log -r 'description(glob:"wip:*")'` |
| change の進化史（rewrite履歴） | `jj evolog -r <id>` |
| 操作ログ | `jj op log` |
| 単一 op の内容 | `jj op show <op-id>` |

### `@` を動かす

| やりたいこと | コマンド |
|---|---|
| メッセージ付け | `jj describe -m "..."` |
| 別の change の description を書く | `jj describe <id> -m "..."` |
| 次のキャンバス | `jj new` |
| 任意の change の上に新規 | `jj new <change> -m "..."` |
| 既存 change を編集対象に | `jj edit <change>` |
| 親へ移動 | `jj prev` |
| 子へ移動 | `jj next` |

`ui.movement.edit = true` の効果で `jj prev`/`jj next` は edit セマンティクス（その change を `@` にする）。

### 過去を編集

| やりたいこと | コマンド |
|---|---|
| `@` を `@-` に畳む | `jj squash` |
| 部分的に畳む（hunk 選択 UI） | `jj si` |
| X を Y に畳む | `jj squash --from X --into Y` |
| 1 change を 2 つに割る | `jj split` |
| change を捨てる | `jj abandon <id>` |
| 任意の場所に乗せ替え | `jj rebase -s X -d Y` |
| 別の場所にコピー | `jj duplicate -r X -d Y` |
| author/timestamp を更新 | `jj metaedit --update-author` |

`jj rebase` の `-d` は v0.36+ で `-o`/`--onto` に改名。旧形は deprecation 期間中で当面動作。

### bookmark

| やりたいこと | コマンド |
|---|---|
| 一覧（ローカル） | `jj bookmark list` |
| 一覧（リモート込） | `jj bookmark list -a` |
| 作成 | `jj bookmark create <name> -r <id>` |
| 移動 | `jj bookmark move <name> --to <id>` |
| 削除 | `jj bookmark delete <name>` |
| 直近 bookmark を `@-` まで | `jj tug` |
| リモート bookmark を track | `jj bookmark track <name>@origin` |

### リモート

| やりたいこと | コマンド |
|---|---|
| fetch | `jj git fetch` |
| change から自動 bookmark で push | `jj git push --change <id>` |
| 既存 bookmark を push | `jj git push -b <name>` |
| 全 tracked を一気に push | `jj git push --tracked` |
| dry-run | `jj git push --dry-run` |

### 救済

| やりたいこと | コマンド |
|---|---|
| 直前の操作を取り消す | `jj undo` |
| undo を redo | `jj redo` |
| 任意の op に丸ごと戻す | `jj op restore <op-id>` |
| 特定 op だけ打ち消す（中間温存） | `jj op revert <op-id>` |
| conflict 一覧 | `jj resolve --list` |
| conflict 解決 | `jj resolve` または直接編集（auto-snapshot） |

---

## レシピ

### A. 単発 PR

```bash
jj new main -m "wip: タイトル"
# 編集
jj describe -m "feat: タイトル"
<プロジェクトの validate>

# 推奨: 名前付き bookmark
jj bookmark create feat/<name> -r @-
jj git push -b feat/<name>
gh pr create --fill --head feat/<name>

# 簡易: 命名不要なら
jj git push --change @-
gh pr create --fill
```

### B. 3層スタック PR（型 → API → UI）

```bash
jj new main -m "feat: 型定義"
jj new      -m "feat: API 実装"
jj new      -m "feat: UI"

# 各層を別の名前付き bookmark に
jj bookmark create feat/x-types -r @--
jj bookmark create feat/x-api   -r @-
jj bookmark create feat/x-ui    -r @
jj git push -b feat/x-types -b feat/x-api -b feat/x-ui

# base 連結（feat/x-api は feat/x-types を base に、UI は feat/x-api を base に）
gh pr create --base main           --head feat/x-types --title "feat: 型定義"
gh pr create --base feat/x-types   --head feat/x-api   --title "feat: API"
gh pr create --base feat/x-api     --head feat/x-ui    --title "feat: UI"
```

簡易版（命名にこだわらない場合）:

```bash
jj git push --change @-- --change @- --change @
# push-<id> 形式で 3 つの bookmark が自動生成。--base/--head には push-<id> を指定する
```

### C. レビュー指摘で過去 change を直す

```bash
jj edit <指摘 change>
# 修正

# 名前付き bookmark なら、同じ bookmark を新位置に動かして再 push
jj bookmark move feat/<name> --to <change>
jj git push -b feat/<name>

# --change 流儀なら、そのまま再 push（push-<id> bookmark が動く）
jj git push --change <change>
```

どちらも force-push 相当。子 commit は自動 rebase される。

### D. 試行錯誤を保存して比較・捨てる

```bash
jj bookmark create attempt-A -r @
jj new @- -m "wip: 別案"
# 編集 → 比較
jj diff -r attempt-A -r @
# 採否決定
jj abandon attempt-A
jj bookmark delete attempt-A
```

### E. 過去 change に fixup を混ぜる

```bash
jj new <混ぜたい change> -m "fixup"
# 修正
jj squash --into <元の change>
```

### F. ローカル `main` の divergence を bookmark に剥がす

ローカル main に直接コミットしてしまったときの救済:

```bash
jj bookmark create chore/work -r main           # 現 main 位置を保存
jj bookmark move main --to main@origin          # main を origin に巻き戻す
jj log -r 'main@origin..chore/work'             # 剥がせたか確認
jj git push -b chore/work                       # PR にする
```

### G. rebase で巻き込んだ競合を解消

```bash
jj rebase -s X -d Y         # 競合あっても操作は成功する（jj の特徴）
jj resolve --list           # 何が conflict か
jj edit <conflict-持ち>      # その change を working copy に
$EDITOR <conflicted-file>   # マーカーを直接編集 → 保存で auto-snapshot
jj log                      # conflict マークが消えれば完了
```

### H. fish 関数（一連を 1 コマンドに）

```fish
# ~/.config/fish/conf.d/jj-pr.fish

function jjsync -d "fetch and rebase work onto latest main"
    jj git fetch; or return 1
    jj bookmark move main --to main@origin
    jj rebase -d main -s 'roots(main..@)'
end

function jjpush -d "validate then push"
    pnpm validate; or return 1   # プロジェクトに合わせて差し替え
    jj git push $argv
end

function jjpr -d "validate, create named bookmark, push, open PR"
    set name $argv[1]
    if test -z "$name"
        echo "usage: jjpr <bookmark-name>  (例: jjpr feat/x-search)"
        return 1
    end
    pnpm validate; or return 1
    jj bookmark create $name -r @-; or return 1
    jj git push -b $name; or return 1
    gh pr create --fill --head $name
end

function jjpr-quick -d "validate, push @- as push-<change-id>, open PR (no naming)"
    pnpm validate; or return 1
    jj git push --change @-; or return 1
    gh pr create --fill
end

function jjrepush -d "move named bookmark to current change and force-push"
    set name $argv[1]
    if test -z "$name"
        echo "usage: jjrepush <bookmark-name>"
        return 1
    end
    jj bookmark move $name --to @-; or return 1
    jj git push -b $name
end
```

---

## 罠と回避

| 罠 | 症状 | 回避 |
|---|---|---|
| ローカル `main` に直接コミット | main と main@origin が diverge | 必ず `jj new main -m ...` で1段上げてから作業 |
| git hooks 不在 | pre-commit / pre-push が無効 | push 前に validate 手動。fish 関数化推奨（レシピH） |
| `--change @` を空 commit に | push できない／意味なし | `--change @-` を使う（`@` は基本キャンバス） |
| bookmark 置き去り | feature の頭に進んでくれない | `jj new` の後は `jj tug` |
| force-push の無自覚 | 共有ブランチで巻き込み事故 | 自分1人の PR ブランチに限る原則 |
| `git rebase`/`git commit` 直打ち | jj 状態と乖離 | colocated では書き込み系は jj 経由に統一 |
| describe を間違えた `@` | 変な commit が積まれる | 焦らず `jj undo` |
| LFS 使用リポ | LFS ポインタが展開されない | jj は LFS 非対応。LFS リポは git で運用 |

---

## 緊急復旧

```bash
# 直前の 1 操作を取り消す
jj undo

# 全活動ログを眺める
jj op log

# その時点に丸ごと戻す（破滅的失敗の最終救済）
jj op restore <op-id>

# 特定 op だけ無効化（前後の op は保持）
jj op revert <op-id>

# conflict が手に負えない → そもそも作り直す
jj abandon <conflict-持ち>
jj op restore <abandon 前の op-id>   # 必要なら原本も拾い直し
```

`jj op log` の `args:` 行に**そのとき打ったコマンド**が残るので、何が起きたかは事後で完全に再現可能。

---

## 補足

### たまに使うが押さえておく

| コマンド | 用途 |
|---|---|
| `jj split` | 1 change を 2 つに（hunk 選択 UI） |
| `jj duplicate` | change を別の場所にコピー（無破壊） |
| `jj evolog -r X` | X が辿った rewrite 履歴 |
| `jj fix` | configured formatter を自動適用してコミット化 |
| `jj show -r <id>` | 単一 change の詳細 |
| `jj op diff` | op 同士の差分 |
| `jj git push --dry-run` | push の予行演習 |
| `jj metaedit --update-author` | identity 設定後に既存 `@` の author を遡って更新 |

### TUI: jjui

```bash
jjui
```

| キー | 操作 |
|---|---|
| `j` / `k` | 上下移動 |
| `l` | 詳細を覗く |
| `Esc` / `h` | 戻る |
| `D` | description 編集 |
| `n` | `jj new` |
| `s` | split |
| `a` | abandon |
| `r` | rebase（移動先選択 UI） |
| `o` | operation log ビュー切替 |
| `p` | プレビューペイン切替 |
| `q` | 終了 |

誤操作は `q` で抜けて `jj undo`。

### 用語対比（git → jj）

| Git | jj |
|---|---|
| HEAD | `@` |
| HEAD^ | `@-` |
| commit hash | commit ID（書き換わると変わる） |
| (なし) | change ID（rewrite で保持される論理的 ID） |
| branch | bookmark |
| stash | （不要。`jj new` で seal される） |
| reflog | `jj op log`（より強力） |
| `git rebase --onto` | `jj rebase -s X -d Y` |
| `git commit --amend` | ファイル保存だけ（`@` に auto-snapshot） |
| `git add -p` + `commit --amend` | `jj squash -i` |
