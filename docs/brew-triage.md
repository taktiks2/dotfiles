# Brew Formula 仕分け表

**初版:** 2026-04-25
**最終更新:** 2026-04-26（Step 7 follow-up 反映）
**対象:** `brew leaves` の Nix / brew 二段運用での仕分け基準

## 移行ポリシー

1. **MOVED**: 純粋な CLI で aarch64-darwin バイナリキャッシュが期待でき、副作用が出ないもの → Nix（home-manager）
2. **KEEP**: 言語ランタイム / DB サービス / Cask 連携 / 第三者 tap など brew が適しているもの
3. **DEFERRED**: 判断保留 / Nix 化が困難なもの

---

## 第一陣 MOVED（Step 2c で home/taktiks2.nix へ移行・31 本）

| Formula | Nix 名 | 備考 |
|---|---|---|
| ripgrep | `ripgrep` | Step 1 で導入 |
| lsd | `lsd` | Step 1 で導入 |
| jq | `jq` | Step 1 で導入 |
| bat | `bat` | |
| fd | `fd` | |
| fzf | `fzf` | |
| gh | `gh` | |
| git-delta | `delta` | nixpkgs では `delta` |
| git-filter-repo | `git-filter-repo` | |
| lazygit | `lazygit` | |
| lazydocker | `lazydocker` | |
| neovim | `neovim` | |
| tmux | `tmux` | |
| tree | `tree` | |
| wget | `wget` | |
| btop | `btop` | |
| broot | `broot` | |
| just | `just` | |
| gnu-sed | `gnused` | brew の `sed` を上書き（GNU sed 既定化） |
| fswatch | `fswatch` | |
| bash | `bash` | macOS 既定 bash 3.2 を補完 |
| bats-core | `bats` | |
| graphviz | `graphviz` | dot/neato 等を提供 |
| television | `television` | バイナリ名は `tv` |
| zig | `zig` | |
| deno | `deno` | |
| uv | `uv` | Python パッケージ管理 |
| sbcl | `sbcl` | Common Lisp REPL |
| cargo-binstall | `cargo-binstall` | |
| cocogitto | `cocogitto` | バイナリ名は `cog` |
| aichat | `aichat` | |

## 第二陣 MOVED（Step 7 follow-up で追加・2 本）

| Formula | Nix 名 | 備考 |
|---|---|---|
| tbls | `tbls` | DB スキーマドキュメント生成 |
| joshuto | `joshuto` | ranger 風ファイラ |

**MOVED 累計: 33 本**

---

## KEEP（brew のまま・宣言は `modules/homebrew.nix`）

### 言語ランタイム / バージョンマネージャ
- `python@3.10` — uv が後継、ただしランタイム本体は brew
- `rbenv` — Ruby バージョン管理
- `nodebrew` — Node 用
- `composer` — PHP 専用
- `luarocks` — Lua 環境と密結合

### データベース / サービス
- `mysql`, `mysql@8.0` — `brew services` で管理中
- `postgresql@14` — 同上

### 重量ビルド / バイナリキャッシュが弱い
- `qemu` — aarch64-darwin ビルド時間が長大
- `clisp` — sbcl と機能重複だが手元で残置
- `openapi-generator`, `bundletool` — JVM 依存

### 第三者 tap（brew 必須）
- `qmk/qmk/qmk`
- `julien-cpsn/atac/atac`
- `raine/workmux/workmux`
- `carlocab/personal/unrar`
- `osx-cross/avr/avr-gcc@9`
- `heroku/brew/heroku`

### ベンダー CLI（brew 配布が公式 / 楽）
- `azure-cli`
- `fastlane`
- `supabase`
- `gemini-cli`
- `docker`（CLI; Docker Desktop は cask）

### Fish / その他
- `fisher` — Fish プラグインマネージャ。home.activation で初期化を委譲
- `rogue` — 古典ローグライク。Nix パッケージなし、嗜好で残置

---

## DEFERRED（残留判断保留）

| Formula | 状態 |
|---|---|
| `clisp` | sbcl で代替可能なら廃止候補 |
| `fisher` | `programs.fish.plugins` 宣言移行と同時に再検討 |
| `rogue` | Nix 化は不可、好みで残置 |

---

## 現在の brew 状態（2026-04-26 時点）

```
brew leaves : 25 本（KEEP 22 + DEFERRED 3）
brew tap    : 12
brew cask   : 13
```

すべて `modules/homebrew.nix` で宣言されており、`onActivation.cleanup = "uninstall"` により未宣言パッケージは自動掃除される。

---

## Cask（13 本・nix-darwin で宣言）

```
arto, bruno, copilot-cli, devtoys, font-hack-nerd-font,
font-hackgen-nerd, ghostty, godot, ngrok, utm,
visual-studio-code, warp, zulu@17
```

---

## 運用メモ

- 新規 formula を追加するとき: `modules/homebrew.nix` の `brews = [ ... ]` に追記 → `darwin-rebuild switch`
- KEEP セットから外したくなったとき: home/taktiks2.nix に追加 → switch（cleanup=uninstall が自動的に brew 側を削除）
- `brew install` を素手で叩いた一時パッケージは次回 switch で削除される（意図的設計）
