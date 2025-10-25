# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

このリポジトリは個人用のdotfiles管理リポジトリです。Neovim、Fish shell、Alacritty、Git、Lazygitなどの設定ファイルを管理しています。

## Setup and Installation

### 🚀 自動インストール（推奨）

```bash
# リポジトリをクローン
git clone <repository-url> ~/dotfiles
cd ~/dotfiles

# インストールスクリプトを実行（全自動）
./install.sh
```

**これだけで完全な開発環境がセットアップされます！**

インストールスクリプトは以下を自動実行：
- Homebrew、必須パッケージの一括インストール
- PHP/Composer/Laravel環境の構築
- Rust、Node.js、Ruby環境のセットアップ
- Fish Shell + Fisher + bobthefishテーマ
- tmux + TPMのセットアップ
- シンボリックリンクの作成とバックアップ
- Neovimプラグインのインストール（オプション）

### インストール後の確認

```bash
# インストールログの確認
cat ~/.dotfiles_install_logs/install_*.log

# バックアップの確認（既存設定がある場合）
ls ~/.dotfiles_backup_*/
```

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
- **PATH設定**: Homebrew、Android SDK、nodebrew、cargo、rbenv、MySQL、Composerなど
- **主要エイリアス**:
  - `vim/vi/v` → nvim
  - `gd` → gh dash
  - `lg` → lazygit
  - `ls/la/ll` → lsd
  - `sls` → sbcl (Common Lisp REPL with nvlime)
- **環境変数**: `secret-env.fish`に秘匿情報を管理（gitignore対象、インストール時に自動生成）

### PHP/Laravel 環境

- **PHP**: Homebrew経由でインストール（最新版）
- **Composer**: グローバルインストール済み
- **Laravel Installer**: `composer global require laravel/installer`で自動インストール
- **MySQL 8.0**: Homebrew経由でインストール、`brew services`で管理
- **PATH**: `~/.composer/vendor/bin`と`/opt/homebrew/opt/mysql@8.0/bin`が自動設定される

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

### Laravel開発

```bash
# MySQLを起動
brew services start mysql@8.0

# 新しいLaravelプロジェクトを作成
laravel new my-project
cd my-project

# 開発サーバーを起動
php artisan serve

# データベースマイグレーション
php artisan migrate
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

### 開発ツール
- **Neovim**: テキストエディタ (LazyVim)
- **Fish**: メインシェル (bobthefishテーマ)
- **Alacritty**: ターミナルエミュレータ
- **tmux**: ターミナルマルチプレクサ
- **Lazygit**: Git TUI
- **git-delta**: Git差分表示
- **gh**: GitHub CLI
- **gh-dash**: GitHub管理ツール
- **lsd**: lsの代替
- **ripgrep**: 高速grep
- **tree-sitter**: パーサー（Neovim用）

### 言語環境
- **PHP 8.4+**: Laravel開発
- **Composer**: PHPパッケージマネージャー
- **Laravel Installer**: Laravelプロジェクト作成
- **MySQL 8.0**: データベース
- **Node.js**: JavaScript（nodebrew管理）
- **Ruby**: iOS開発等（rbenv管理）
- **Rust**: システムプログラミング（rustup管理）
- **Common Lisp**: nvlime + sbcl

## Notes

- **対象OS**: macOS (Apple Silicon専用)
- **言語**: 日本語環境
- **インストール**: `./install.sh`で完全自動化
- **冪等性**: 何度実行しても安全（既存設定は自動バックアップ）
- **ログ**: `~/.dotfiles_install_logs/`にインストールログを保存
- **バックアップ**: `~/.dotfiles_backup_YYYYMMDD_HHMMSS/`に既存設定を自動バックアップ
