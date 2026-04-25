# Nix 導入レポート — taktiks2/dotfiles

**作成日:** 2026-04-25
**対象機:** MacBook Air (Apple Silicon, macOS 26.3.1)
**対象リポジトリ:** `~/dotfiles`
**目的:** 既存の Homebrew + `install.sh` ベース構成に Nix を統合し、宣言的・再現可能な開発環境管理へ段階移行する。

---

## 1. エグゼクティブサマリー

- **dotfiles で Nix を管理するのは 2026 年時点のベストプラクティス**。ただし「全部 Nix 化」は罠。aarch64-darwin のビルド事情と GUI アプリの事情から、**Nix / Homebrew / 手動の三層併用**が現実解。
- 本機は **Nix インストール済（Determinate Systems installer 経由）**・Homebrew は formula 206 + cask 13 という規模。**ゼロから入れる段階は終了済**で、次は「dotfiles に統合し `install.sh` を段階的に縮小する」フェーズ。
- 推奨スタックは **flakes + nix-darwin + home-manager + nix-homebrew**。
- 移行は 7 ステップに分割し、**PHP / MySQL / 既存 .config 中身は当面さわらない**ことでリスクを抑える。

---

## 2. 現状調査結果

| 項目 | 状態 |
|---|---|
| OS | macOS 26.3.1 (Darwin 25.3.0, arm64) |
| Shell | `/bin/zsh`（Fish はログインシェル外で運用） |
| Nix | **インストール済** (`/nix/var/nix/profiles/default/bin/nix`、Determinate `nix-installer` の `receipt.json` あり) |
| Homebrew | 5.1.7 / formula **206本** / cask **13本** |
| dotfiles 規模 | `install.sh` 588 行、`.config/` に 20+ ツール設定 |
| 主要言語環境 | PHP/Composer/Laravel, MySQL 8.0, Node (nodebrew), Ruby (rbenv), Rust (rustup), Common Lisp |

---

## 3. Nix エコシステム最新動向 (2026 早期)

### インストーラ
- **Determinate Nix Installer**: 2026 早期から **Determinate Nix（独自ディストリ）専用**になった。upstream CppNix を入れるには `--determinate=false` か **公式 installer (`nix.dev`)** を使う。
- 本機は Determinate 経由で導入済 → **そのまま継続推奨**（macOS アップグレード耐性が最も高い）。

### 主要コンポーネント
- **nix-darwin**: `LnL7` 個人 repo から **`nix-darwin/nix-darwin` org** に移管され、複数メンテナ体制 + nixpkgs リリース連動の安定ブランチ（例 `nix-darwin-25.11`）あり。
- **home-manager**: `nix-community` 配下で活発。**nix-darwin モジュールとして組み込む**のが標準（standalone CLI は非 darwin 用）。
- **Flakes**: 上流仕様上はまだ `experimental-features` フラグ付きだが、**事実上の標準**。Determinate Nix では既定で有効。

### 周辺
- **Lix**: CppNix 2.18 ベースのフォーク。コミュニティ伸長中だが **macOS dotfiles のブートストラップに 2026 時点で選ぶ強い理由はない**。
- **flake-parts (hercules-ci)**: flake の構造化ヘルパとして主流。Snowfall Lib も健在だが規模は小さめ。
- **nix-homebrew (zhaofengli)**: nix-darwin から Homebrew を宣言的にブートストラップする標準的な選択肢。

### 出典
- https://github.com/DeterminateSystems/nix-installer
- https://determinate.systems/blog/installer-dropping-upstream/
- https://github.com/nix-darwin/nix-darwin
- https://nix-community.github.io/home-manager/
- https://wiki.nixos.org/wiki/Flakes
- https://github.com/zhaofengli/nix-homebrew
- https://lix.systems/

---

## 4. 推奨アーキテクチャ

### リポジトリ構成

```
dotfiles/
├── flake.nix              # inputs: nixpkgs, nix-darwin, home-manager, nix-homebrew
├── flake.lock
├── hosts/
│   └── MacBook-Air/
│       └── default.nix    # nix-darwin: system.defaults / homebrew.casks / services
├── home/
│   └── taktiks2.nix       # home-manager: CLIパッケージ + xdg.configFile symlink
├── modules/               # 共通モジュール（必要時）
├── overlays/              # 必要時
└── .config/               # 既存ファイル群（中身は触らずsymlinkで配布）
```

切替コマンド: `darwin-rebuild switch --flake .#MacBook-Air`

### 設計原則
- **`.config/*` の中身は Nix DSL に書き直さない**。home-manager の `xdg.configFile."nvim".source = ./.config/nvim;` で symlink するだけ。
- ホストごとの設定は `hosts/<hostname>/`、ユーザごとは `home/<user>.nix`。将来 2 台目を導入しても拡張可能。
- flake input は最小限から。`flake-parts` は規模が増えてから検討。

---

## 5. 役割分担マトリクス

| 領域 | 担当 | 理由 |
|---|---|---|
| CLI ツール (ripgrep, lsd, fd, fzf, gh, gh-dash, lazygit, delta, tmux, jq, btop, bat, neovim) | **Nix (home-manager)** | aarch64-darwin で即座に動く・宣言的管理の最大効用 |
| GUI cask 13本 (Alacritty, Ghostty, Chrome, Slack, Docker Desktop 等) | **nix-darwin + nix-homebrew** | 宣言的に保ちつつ署名・自動更新は brew に委譲 |
| macOS システム設定 (Dock, Finder, キーリピート, 入力ソース) | **`system.defaults.*`** | Nix の最大の勝ち筋。GUI 手動設定が消える |
| **PHP / Composer / Laravel** | **Homebrew のまま** | aarch64-darwin で PHP 拡張のローカルビルドが極めて高コスト |
| **MySQL 8.0** | **`brew services` のまま** | nix-darwin `services.mysql` は動くが macOS では事故率高 |
| Rust / Node / Ruby のグローバル | 当面据え置き、新規プロジェクトは **devShell + direnv (`nix-direnv`)** | rustup / nodebrew / rbenv からの段階脱却 |
| `.config/*` 設定ファイル | home-manager `xdg.configFile` で **symlink** | 二重管理回避 |
| Fish | `programs.fish` で plugin だけ宣言、`config.fish` は `source` | 既存資産そのまま活用 |
| Fonts | nixpkgs `nerd-fonts.*` (home-manager) | aarch64-darwin で動作良好 |

### Apple Silicon 上の注意
- 一部パッケージは aarch64-darwin バイナリキャッシュが薄く、ローカルビルドで時間を消費（PHP 拡張、古い Python wheel、旧 XCode SDK 依存物など）。
- **Determinate Cache** または `cachix` を有効化すると緩和される。

---

## 6. 段階的移行プラン

| Step | 内容 | 状態 | `install.sh` への影響 |
|---|---|---|---|
| 0 | Nix インストール (Determinate) | ✅ 完了 | — |
| 1 | flake 雛形 + nix-darwin + home-manager + nix-homebrew を最小構成で起動。CLI 3 ツール程度で `darwin-rebuild switch` 成功を検証 | 未着手 | 変更なし |
| 2 | CLI ツール群（formula 約 60〜80 本）を home-manager に移行 | 未着手 | brew install 該当行を削除 |
| 3 | `system.defaults.*` で macOS 設定を宣言化 | 未着手 | 新規の勝ち（手動 GUI 設定が消える） |
| 4 | cask 13 本を `nix-darwin.homebrew.casks` に移管（`nix-homebrew` で brew 自体も宣言的に） | 未着手 | brew install --cask 行を削除 |
| 5 | `.config/*` の symlink ロジックを home-manager に移譲 | 未着手 | symlink セクション削除 |
| 6 | 新規プロジェクトから **devShell + nix-direnv** を採用 | 未着手 | rustup / nodebrew / rbenv は共存維持 |
| 7 | 余剰の brew formula 棚卸し → 不要なものを削除 | 未着手 | brew のサイズが大幅減 |

**最終形:** `install.sh` は「**Nix 入れる → repo clone → `darwin-rebuild switch`**」に縮小。PHP / MySQL の brew ブートストラップだけ残す。

### 当面さわらない方針（重要）
- PHP / Composer / Laravel
- MySQL 8.0
- rbenv 管理の Ruby
- 動いている `.config/*` の中身そのもの

---

## 7. リスクと緩和策

| リスク | 緩和策 |
|---|---|
| `darwin-rebuild switch` 失敗で環境が壊れる | nix-darwin は **世代管理**あり。`darwin-rebuild --rollback` で即時戻せる |
| brew と Nix で同名コマンドが衝突 | PATH 順序を nix-darwin で明示。重複を発見次第 brew 側を削除 |
| aarch64-darwin で長時間ビルド | Determinate Cache / cachix を併用。問題パッケージは brew に残す |
| flake input のバージョン乖離 | `flake.lock` を git 管理。`nix flake update` は意図的に運用 |
| 既存 `.config/*` を Nix DSL に書き直して破綻 | **書き直さない**。symlink 方式を厳守 |

---

## 8. 期待される効果

- macOS 再セットアップ時間が **数時間 → 数分**（ビルド済キャッシュ前提）
- システム設定（Dock / Finder / キーボード等）の **GUI 手動操作ゼロ化**
- ツールバージョンの **ホスト間完全一致**（将来 2 台目導入時に効く）
- `install.sh` の保守コスト **大幅低下**（588 行 → 100 行未満が射程）
- プロジェクトごとの開発環境を **devShell** で分離し、グローバル汚染を解消

---

## 9. 次アクション

**Step 1（flake 雛形作成）から着手することを推奨。**

- 最小構成: `flake.nix` + `hosts/MacBook-Air/default.nix` + `home/taktiks2.nix`
- 試験対象: `ripgrep`, `lsd`, `jq` の 3 つだけを home-manager 経由で導入
- 既存 brew・`.config`・`install.sh` には一切手を加えない
- `darwin-rebuild switch --flake .#MacBook-Air` の成功を確認した時点で commit

任意で先に **「formula 206 本の仕分けリスト」**（Nix 行き / brew 残留 の分類）を作成すると、Step 2 以降の手戻りを最小化できる。

---

*このレポートは Claude Code (Opus 4.7) による調査に基づく。エコシステム動向は 2026 年 4 月時点。*
