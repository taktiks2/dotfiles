# Config 管理戦略レポート (2026-04 監査)

`~/.config/<tool>` 配下の設定ファイルを home-manager でどう管理するか、
2026 年初頭時点のベストプラクティスを踏まえて整理した監査レポート。

> 対象: `dotfiles/` リポジトリ全体（nix-darwin + home-manager + flake + Determinate Nix）
> 前提: Phase 6–17 監査完了済み（fish/tmux/git/lazygit/btop/alacritty/ghostty/gh-dash/delta/direnv は `programs.*` 移行済）
> 残課題: live-link 6 件（nvim / atac / ccstatusline / cspell / mcphub / workmux）の再評価と全体構造の最適化

---

## TL;DR

| 結論 | 推奨度 |
|---|---|
| 残った 6 件の live-link のうち **5 件** は store inclusion / inline 化で再現性が取れる | ★★★ |
| 600 行近い `home/taktiks2.nix` を `programs/*.nix` 単位にモジュール分割 | ★★★ |
| `nh darwin` 導入で日常 UX を改善（diff 表示 + confirm prompt） | ★★☆ |
| `dotfilesRoot` を `${config.home.homeDirectory}/dotfiles` 動的化（マルチホスト保険） | ★★☆ |
| **stylix 導入は現時点では見送り**（Ghostty 主端末では恩恵が薄い） | ★☆☆ |
| **nvim を nixvim/nvf に移行しない**（コスパ悪、LazyVim 維持が合理的） | ✗ |

---

## 1. 設定管理の 4 段階モデル

home-manager で設定を持つ手段は本質的に 4 つ。**選択軸は「編集頻度」と「再現性が必要か」** の 2 つだけ。

| 方式 | 編集→反映 | 再現性 | 適合ケース |
|---|---|---|---|
| **A. `programs.<tool>.settings`** | rebuild 必要 | ◎ | モジュール対応 + 設定がほぼ凍結 |
| **B. `xdg.configFile.<n>.text`** (Nix 内 inline) | rebuild 必要 | ◎ | 短い JSON / YAML / TOML、モジュール非対応 |
| **C. `xdg.configFile.<n>.source = ./...`** (store inclusion) | rebuild 必要 | ◎ | 中〜大の設定で編集が稀 |
| **D. `mkOutOfStoreSymlink`** (live link) | 即時 | ✗ | lazy-lock.json 等の自動書き換え対象、TUI で頻繁にいじる対象 |

### コミュニティ合意（2026-04 時点）

- [jade.fyi - "use nix less"](https://jade.fyi/blog/use-nix-less/): D は逃げ道。乱用すべきでない
- [fzakaria - "home-manager is a false enlightenment"](https://fzakaria.com/2025/07/07/home-manager-is-a-false-enlightenment): 過剰な Nix 化は iteration を遅くする
- 本リポジトリは Phase 7 で **ほぼ全部 D に倒した経緯** があるため、Phase 17 で 6 件を A に移行した今こそ残り 6 件を再評価するタイミング

---

## 2. 残った live-link 対象の個別判定

| 対象 | 現状の中身 | 編集頻度 | mutable? | 推奨移行先 |
|---|---|---|---|---|
| **nvim** | 20 lua + lazy-lock.json | 高（`:Lazy update` で書き換え） | ✓ | **D 維持** |
| **atac** | TOML 2 つ + `atac.log`（mutable） | 低 | log のみ ✓ | **C 一部** （settings/ のみ store inclusion、log は触らない） |
| **ccstatusline** | 18 行 JSON | 中 | ✗ | **B**（`text = builtins.toJSON {...}`） |
| **cspell** | スキーマ込み JSON + 辞書 txt | 低 | ✗ | **C**（`source = ./.config/cspell`） |
| **mcphub** | 12 行 JSON | 低 | ✗ | **B**（`text = builtins.toJSON {...}`） |
| **workmux** | `nerdfont: true` 1 行 | ほぼ無 | ✗ | **B**（`text = "nerdfont: true\n"`） |

**結論**: 移行後は `xdg.configFile` のエントリが 6 → 1（nvim のみ）に絞れる。

### 詳細: なぜ nvim だけ live link を残すか

- `lazy-lock.json` は `:Lazy update` で nvim 自身が書き換える → store read-only と相性最悪
- 20 lua ファイルを Nix DSL に書き直すコストに対して、得られる再現性のメリットが薄い
- LazyVim 民の界隈合意は「`mkOutOfStoreSymlink` がベスト解」（[lazy.nvim lockfile docs](https://lazy.folke.io/usage/lockfile)）

---

## 3. クロスカット改善（インパクト順）

### ① モジュール分割（推奨度: ★★★）

`home/taktiks2.nix` が 600 行近い。コミュニティの慣習（[Mic92/dotfiles](https://github.com/Mic92/dotfiles)、[NixOS & Flakes Book - modularize](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration)）は **500 行超で per-tool 分割**。

#### 提案ディレクトリ構成

```
home/
  taktiks2.nix          # imports = [ ./programs/*.nix ./packages.nix ./session.nix ];
  packages.nix          # home.packages
  session.nix           # sessionPath / sessionVariables
  programs/
    fish.nix
    tmux.nix
    git.nix             # programs.git + programs.delta + activation
    terminal.nix        # alacritty + ghostty
    sysmon.nix          # btop
    github.nix          # gh-dash + lazygit
    direnv.nix
  files.nix             # xdg.configFile + B 方式の inline (ccstatusline/mcphub/workmux)
```

**評価オーバーヘッドはほぼゼロ**（Nix は import 解決を memoize する）。可読性・git diff の局所性・将来の host 分岐に直結。

### ② `nh darwin` 導入（推奨度: ★★☆）

[viperML/nh](https://github.com/viperML/nh) は `darwin-rebuild` の Rust 再実装。macOS 公式サポート済。

#### 機能差分

- ビルド時に **derivation diff を pretty 表示**（次の世代で何が変わるか可視化）
- **confirm prompt** 付き（rebuild 事故防止）
- `nh clean` で gcroot 含むまとめて GC

#### 使い方

```fish
nh darwin switch ~/dotfiles -H MacBook-Air
```

Determinate Nix との公式互換性明記はないが、`darwin-rebuild` を呼ぶ wrapper のため `determinateNix.enable = true` 環境でも動く実例多数。**1 行 alias 化して試す価値あり**、合わなければ素の `darwin-rebuild` に戻すだけ。

### ③ マルチホスト準備（推奨度: ★★☆）

現状 `flake.nix` で `dotfilesRoot = "/Users/${username}/dotfiles"` と決め打ちしているため、**ユーザー名やパスが違うマシンでは破綻**する。今すぐの対応は不要だが、2 台目を建てる時のために:

```nix
# flake.nix の mkDarwin factory:
dotfilesRoot ? "${config.home.homeDirectory}/dotfiles"
```

### ④ Stylix 選択的導入 — 現状は見送り（推奨度: ★☆☆）

[stylix](https://github.com/danth/stylix) は `stylix.darwinModules.stylix` で home-manager レイヤに base16 パレット注入する system-wide theming framework。`alacritty` / `btop` / `tmux` / `neovim` / `bat` / `delta` / `fzf` をテーマ統一できる。

#### 本リポジトリでの評価

- **Ghostty が 2026-04 時点で stylix 非対応**（[ghostty-org/ghostty#2824](https://github.com/ghostty-org/ghostty/discussions/2824) — macOS の nixpkgs ビルドが Swift 6 制約で blocked、cask 経由のため stylix が touch できない）
- 本リポジトリは Ghostty を主端末にしているため恩恵が限定的
- macOS の system UI（メニューバー / Dock 色）は stylix の対象外

→ **Ghostty 中心ならば現時点では導入価値薄い**。Alacritty を主に使うようになったタイミングで再検討。

### ⑤ nvim を nixvim/nvf に移行 — 推奨しない（推奨度: ✗）

[devctrl.blog 比較](https://devctrl.blog/posts/which-one-should-i-use-programs-neovim-nix-cats-nvim-nixvim-or-nvf/) のコミュニティ評価:

| プロジェクト | 評価 |
|---|---|
| **nixvim** | lazy loading が 2026 でも experimental、20 lua → Nix DSL 翻訳コスト膨大、起動遅延報告あり |
| **nvf** | 同様にフル Nix 化が前提 |
| **nixCats-nvim** | 「Nix が plugin の hash-pin、Lua はそのまま」のハイブリッド。LazyVim ユーザの移行先として推奨多数 |

→ **既存 LazyVim 設定が安定しているなら触らない**。Nix の再現性を nvim プラグインにまで広げたくなったら nixCats を検討。

---

## 4. アンチパターン警告

本リポジトリで該当しうる、もしくは将来踏みうる地雷。

### ① `xdg.configFile.atac.source = mkOutOfStoreSymlink "...atac"` — log 混入

中に `atac.log` があるため live link 必須。store inclusion した瞬間 atac が log 書き込み失敗する。**一段細かく `atac/settings/theme.toml` 単位でリンクする** のが正解。

### ② `programs.btop.settings.save_config_on_exit = true` — read-only への自動書き込み失敗

store read-only なのに btop が auto-save しようとして黙って失敗。**Phase 17 で `false` 化済 ✓**

### ③ `useGlobalPkgs = true` + HM 側 `nixpkgs.overlays = [...]`

2026 で deprecation 警告。flake input の overlays に統一すべし。**本リポジトリは flake 側に集約済 ✓**

### ④ `mkOutOfStoreSymlink` で複数階層リンク

例: `xdg.configFile.nvim` と `xdg.configFile."nvim/lua/foo.lua"` を併用すると後者で前者が壊れる。同一プレフィックスでは粒度を統一する。

### ⑤ over-nixification

CLI ツールを全部 Nix 管理しようとして頻繁な rebuild が iteration を遅くする。
本リポジトリの `install.sh` 末尾の npm global 4 本（`claude` / `ccstatusline` / `ccusage` / `diffity`）は **意図的な「Nix 管理境界外の最小 bootstrap」** であり、これは正しい判断。

---

## 5. 推奨ロードマップ

| 順 | 作業 | 工数 | 効果 |
|---|---|---|---|
| 1 | `workmux` / `mcphub` / `ccstatusline` を `text =` 化 | 15 分 | live link 4 件削減 |
| 2 | `cspell` を store inclusion (`source = ./.config/cspell`) | 5 分 | 再現性向上（編集稀） |
| 3 | `atac` を `settings/{theme,key}.toml` 単位でリンク + log 排除 | 10 分 | log の dotfiles 混入を防げる |
| 4 | `home/taktiks2.nix` を `programs/*.nix` に分割 | 1–2 時間 | 可読性・diff 局所性が劇的改善 |
| 5 | `nh` 導入（`home.packages` に `pkgs.nh`） | 5 分 | 日常 UX 改善 |
| 6 | `dotfilesRoot` を `${homeDirectory}/dotfiles` で動的化 | 5 分 | 将来のマルチホスト保険 |
| 7 | （任意）stylix を Alacritty/btop/tmux 限定で試す | 30 分 | テーマ統一したい時のみ |
| ✗ | nixvim 移行 | 数日 | コスパ悪、推奨しない |

**1〜3 を片付ければ live link 残は nvim だけ**となり、`xdg.configFile` 設計が 1 行で済むほど整理される。それが終わったタイミングで 4 のモジュール分割に進むのが消化しやすい順序。

---

## 6. 参考資料

### home-manager / Nix 公式

- [home-manager `mkOutOfStoreSymlink` 実装](https://github.com/nix-community/home-manager/blob/release-25.11/modules/files.nix)
- [home-manager `programs/*` モジュール一覧 (release-25.11)](https://github.com/nix-community/home-manager/tree/release-25.11/modules/programs)
- [Determinate Systems nix-darwin guide](https://docs.determinate.systems/guides/nix-darwin/)

### コミュニティ議論・ブログ

- [jade.fyi - "use nix less"](https://jade.fyi/blog/use-nix-less/) — 過剰 Nix 化への警鐘
- [fzakaria - "home-manager is a false enlightenment"](https://fzakaria.com/2025/07/07/home-manager-is-a-false-enlightenment) — HM の限界と現実的運用
- [devctrl.blog - nixvim/nvf/nixCats 比較](https://devctrl.blog/posts/which-one-should-i-use-programs-neovim-nix-cats-nvim-nixvim-or-nvf/)
- [NixOS & Flakes Book - Modularize the Configuration](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration)

### ツール

- [stylix](https://github.com/danth/stylix)
- [nh (nix-helper)](https://github.com/viperML/nh)
- [nixvim](https://github.com/nix-community/nixvim)
- [nixCats-nvim](https://github.com/BirdeeHub/nixCats-nvim)
- [lazy.nvim lockfile](https://lazy.folke.io/usage/lockfile)

### リファレンス dotfiles

- [Mic92/dotfiles](https://github.com/Mic92/dotfiles) — flake-parts でモジュール分割した代表例
- [fufexan/dotfiles](https://github.com/fufexan/dotfiles) — 同上
- [stevearc/dotfiles](https://github.com/stevearc/dotfiles/blob/master/.config/nvim/lazy-lock.json) — lazy-lock.json を git tracked にする例

### Issue / ブロッカー

- [ghostty-org/ghostty#2824](https://github.com/ghostty-org/ghostty/discussions/2824) — Ghostty の nixpkgs macOS ビルド (Swift 6 問題)
- [nixpkgs#82606](https://github.com/NixOS/nixpkgs/issues/82606) — direnv の fish/zsh test SIGKILL（本リポジトリ flake.nix で overlay 適用中）

---

## 付録: 未解決の論点

調査でも結論が出なかったため、実地で試す必要がある項目。

- **nixCats-nvim の macOS 上での実績**: NixOS 向け事例が多く、nix-darwin + Determinate Nix 環境での動作事例は確認できなかった
- **`nh darwin` + Determinate Nix の動作可否**: 公式ドキュメントに明記なし。実際に試した報告が必要
- **stylix の Ghostty 対応時期**: Ghostty の nixpkgs macOS ビルド対応（Swift 6 問題の解決）次第
- **`nixpkgs.overlays` + `useGlobalPkgs` の廃止スケジュール**: 正確な廃止バージョン未確認

---

*このレポートは Phase 17 完了直後（2026-04-26）に作成。
次回監査タイミング: 上記ロードマップ 1–6 完了後（Phase 18 として記録予定）。*
