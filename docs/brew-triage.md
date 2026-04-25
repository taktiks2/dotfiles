# Brew Formula 仕分け表

**作成日:** 2026-04-25
**対象:** `brew leaves` 出力 57 本（依存 149 本は親に追従するので無視）

## 移行ポリシー

1. **MOVE**: 純粋な CLI で aarch64-darwin バイナリキャッシュが期待でき、移行で副作用が出ないもの
2. **KEEP**: 言語ランタイム / DB サービス / Cask 連携 / 第三者 tap など brew が適している
3. **LATER**: 判断保留（次回見直し）

---

## 第一陣 MOVE（Step 2c で home/taktiks2.nix へ追加）

| Formula | Nix 名 | 備考 |
|---|---|---|
| ripgrep | `ripgrep` | Step 1 で導入済 |
| lsd | `lsd` | Step 1 で導入済 |
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
| jq | `jq` | Step 1 で導入済 |
| gnu-sed | `gnused` | |
| fswatch | `fswatch` | |
| bash | `bash` | macOS 既定の bash 3.2 を上書き不要、しかしツール群が依存しがち |
| bats-core | `bats` | |
| graphviz | `graphviz` | |
| television | `television` | |
| zig | `zig` | |
| deno | `deno` | |
| uv | `uv` | Python パッケージ管理（rye 後継） |
| sbcl | `sbcl` | Common Lisp REPL |
| cargo-binstall | `cargo-binstall` | |
| cocogitto | `cocogitto` | |
| aichat | `aichat` | |

**合計: 31 本**

---

## KEEP（brew のまま）

### 言語ランタイム / バージョンマネージャ
- `python@3.10` — uv が後継、ただしランタイム本体は brew で
- `rbenv` — Ruby バージョン管理。Nix の Ruby は別ワークフロー
- `nodebrew` — 同上、Node 用
- `composer` — PHP 専用
- `luarocks` — Lua 環境と密結合

### データベース / サービス
- `mysql`, `mysql@8.0` — `brew services` で管理中
- `postgresql@14` — 同上

### 重量ビルド / バイナリキャッシュが弱い
- `qemu` — aarch64-darwin ビルド時間が長大
- `clisp` — sbcl と重複だがレガシー
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
- `docker` (CLI; Docker Desktop は cask)

### Fish / その他
- `fisher` — Fish プラグインマネージャ。Nix で plugins 宣言する Step まで残置
- `tbls` — 移行可能だが第二陣
- `joshuto` — 移行可能だが第二陣
- `rogue` — 遊び。維持コスト無し

---

## LATER（保留）

- `tbls`, `joshuto` — 第二陣で MOVE 候補
- `fisher` — `programs.fish.plugins` 宣言移行と同時
- `clisp` — sbcl で代替可能なら廃止候補

---

## Cask（13本、Step 4 で nix-darwin に移管予定）

```
arto, bruno, copilot-cli, devtoys, font-hack-nerd-font,
font-hackgen-nerd, ghostty, godot, ngrok, utm,
visual-studio-code, warp, zulu@17
```

Step 4 で `homebrew.casks = [ ... ]` として `nix-darwin` 配下に宣言化予定。本体の brew install は維持。

---

## brew uninstall タイミング

第一陣 MOVE の brew パッケージは、**Nix 版で完全に動作確認できてから** `brew uninstall <name>` する。
途中で気付かない依存に巻き込まれていた場合に備え、`brew autoremove --dry-run` で影響範囲を確認すること。
