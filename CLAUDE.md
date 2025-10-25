# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

このリポジトリは個人用のdotfiles管理リポジトリです。Neovim、Fish shell、Alacritty、Git、Lazygitなどの設定ファイルを管理しています。

## Setup and Installation

### 初期セットアップ

```bash
# install.shを実行してシンボリックリンクを作成
./install.sh

# 必要なツールのインストール（README.mdを参照）
brew install neovim fish ripgrep tree-sitter lazygit git-delta
brew install --cask alacritty
brew install fisher
fisher install oh-my-fish/theme-bobthefish

# tmuxプラグインのインストール
# tmuxを起動後、<Prefix> + I でプラグインをインストール
```

### Lazygit設定

`config.yml`は`/Users/{UserName}/Library/Application Support/lazygit`にコピーする必要があります（deltaとの連携用）。

## Architecture

### ディレクトリ構造

```
.
├── .config/
│   ├── fish/          # Fish shell設定
│   │   ├── config.fish       # メイン設定ファイル
│   │   └── secret-env.fish   # 秘匿情報（gitignore対象）
│   ├── nvim/          # Neovim (LazyVim)設定
│   │   ├── init.lua          # エントリーポイント
│   │   ├── lua/
│   │   │   ├── config/       # LazyVim設定（keymaps, options, etc.）
│   │   │   └── plugins/      # カスタムプラグイン設定
│   │   └── lazy-lock.json    # プラグインバージョン管理
│   ├── git/           # Git設定
│   ├── alacritty/     # Alacrittyターミナル設定
│   ├── atac/          # ATAC (APIクライアント)設定
│   └── cspell/        # スペルチェック設定
├── config.yml         # Lazygit設定（deltaとの連携）
└── install.sh         # セットアップスクリプト
```

### Neovim (LazyVim) 構成

- **ベース**: LazyVimディストリビューションを使用
- **プラグイン管理**: lazy.nvim
- **言語サポート**: TypeScript, Rust, Go, Python, PHP, Vue, Astro, Docker, Markdownなど
- **主要機能**:
  - LSP、linting (ESLint)、formatting (Prettier)
  - GitHub Copilot連携
  - DAP (デバッグ)、テストサポート
  - cspellによるスペルチェック（none-ls経由）
- **カスタム設定**:
  - `lua/config/`: キーマップ、オプション、自動コマンド
  - `lua/plugins/`: プラグイン固有の設定（LSP、UI、コーディング、AIなど）
  - `lua/taktiks2/discipline.lua`: カスタムユーティリティ

### Fish Shell 構成

- **テーマ**: bobthefish (Dracula配色)
- **PATH設定**: Homebrew、Android SDK、nodebrew、cargo、rbenvなど
- **主要エイリアス**:
  - `vim/vi/v` → nvim
  - `gd` → gh dash
  - `lg` → lazygit
  - `ls/la/ll` → lsd
  - `sls` → sbcl (Common Lisp REPL with nvlime)
- **環境変数**: `secret-env.fish`に秘匿情報を管理（gitignore対象）

## Development Workflow

### Neovim設定の編集

```bash
# Neovim設定ファイルを編集
nvim ~/.config/nvim/lua/config/keymaps.lua
nvim ~/.config/nvim/lua/plugins/lsp.lua

# LazyVim プラグインマネージャーを開く
nvim
:Lazy

# Masonでツールを管理
:Mason
```

### Fish設定の編集

```bash
# Fish設定を編集
nvim ~/.config/fish/config.fish

# 設定を再読み込み
source ~/.config/fish/config.fish
```

### Git操作

```bash
# Lazygitを使用（推奨）
lg

# またはgh dashでGitHub管理
gd
```

## Important Files

### 秘匿情報の管理

- `.config/fish/secret-env.fish`: アクセストークンなどの秘匿情報を含む環境変数
- `.config/git/ignore`: Gitグローバルignore設定
- これらのファイルは`.gitignore`に含まれています

### プラグイン管理

- `.config/nvim/lazy-lock.json`: Neovimプラグインのバージョンロック
- `.config/nvim/lazyvim.json`: LazyVim設定

## Commonly Used Tools

- **Neovim**: テキストエディタ (LazyVim)
- **Fish**: メインシェル (bobthefishテーマ)
- **Alacritty**: ターミナルエミュレータ
- **Lazygit**: Git TUI
- **git-delta**: Git差分表示
- **gh-dash**: GitHub管理ツール
- **lsd**: lsの代替
- **ripgrep**: 高速grep
- **tree-sitter**: パーサー（Neovim用）

## Notes

- このリポジトリは日本語環境で使用されています
- 開発環境はmacOS（Homebrew使用）
- Android SDK、Node.js (nodebrew)、Ruby (rbenv)、Rust (cargo)などの開発環境を含む
- Common Lisp開発環境（nvlime + sbcl）も設定済み
