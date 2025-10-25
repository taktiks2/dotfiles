# dotfiles

macOS (Apple Silicon) 用の個人用dotfiles管理リポジトリ

## 🚀 クイックスタート

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

たったこれだけで、開発環境が完全にセットアップされます！

## 📦 自動インストールされる内容

### 必須開発ツール
- **Neovim** - LazyVimベースのエディタ設定
- **Fish Shell** - bobthefishテーマ付き
- **Alacritty** - 高速ターミナルエミュレータ
- **tmux** - ターミナルマルチプレクサ（Tokyo Nightテーマ）
- **Lazygit** - Git TUI
- **git-delta** - Git差分表示改善ツール
- **lsd** - 次世代lsコマンド
- **ripgrep** - 高速grep
- **GitHub CLI (gh)** - GitHub操作ツール

### PHP/Laravel環境
- **PHP 8.4+** (Homebrew)
- **Composer** - PHPパッケージマネージャー
- **Laravel Installer** - Laravelプロジェクト作成ツール
- **MySQL 8.0** - データベース

### その他の開発環境
- **Node.js** - nodebrew経由でインストール
- **Ruby** - rbenv経由でインストール
- **Rust** - rustup経由でインストール
- **CocoaPods** - iOSアプリ開発用

### アプリケーション
- Visual Studio Code
- Google Chrome
- Docker

## 📋 システム要件

- macOS (Apple Silicon)
- Xcode Command Line Tools（インストールスクリプトが自動でインストール）

## 🎯 インストールスクリプトの機能

### ✅ 安全な設計
- **冪等性**: 何度実行しても安全
- **自動バックアップ**: 既存の設定ファイルは自動的にバックアップ
- **エラーハンドリング**: 各ステップで適切なエラー処理
- **ログ出力**: `~/.dotfiles_install_logs/` にログを保存

### 🔄 自動セットアップされる項目

1. **Homebrew** のインストールと更新
2. **必須パッケージ** の一括インストール
3. **PHP/Composer/Laravel** 環境の構築
4. **Rust (cargo)** のインストール
5. **Node.js (nodebrew)** のセットアップ
6. **Ruby (rbenv)** のセットアップと最新版インストール
7. **Fish Shell** + Fisher + bobthefishテーマ
8. **tmux** + TPM（Tmux Plugin Manager）
9. **シンボリックリンク** の自動作成
10. **Neovim プラグイン** の自動インストール（オプション）

## 📁 主要な設定ファイル

```
~/dotfiles/
├── .config/
│   ├── fish/
│   │   ├── config.fish          # Fish設定
│   │   └── secret-env.fish      # 秘匿情報（自動生成、gitignore済）
│   ├── nvim/                    # Neovim (LazyVim)設定
│   ├── alacritty/               # Alacritty設定
│   ├── tmux/                    # tmux設定
│   ├── git/                     # Git設定
│   └── atac/                    # ATAC (APIクライアント)設定
├── config.yml                   # Lazygit設定
└── install.sh                   # インストールスクリプト
```

## 🛠 インストール後の手順

インストールスクリプト完了後、以下を実行してください：

1. **ターミナルを再起動**
2. **Fishシェルでログイン**（デフォルトシェルに設定した場合）
3. **tmuxを起動** して `Ctrl+s` + `I` でプラグインをインストール
4. **Neovimを起動** してプラグインをインストール（`:Lazy`）

## 🎨 カスタマイズ

### 秘匿情報の設定

`~/.config/fish/secret-env.fish` に環境変数を追加：

```fish
set -x GITHUB_TOKEN "your_token_here"
set -x OPENAI_API_KEY "your_api_key_here"
```

### Neovim設定のカスタマイズ

```bash
nvim ~/.config/nvim/lua/config/keymaps.lua    # キーマップ
nvim ~/.config/nvim/lua/plugins/lsp.lua       # LSP設定
```

### Fish設定のカスタマイズ

```bash
nvim ~/.config/fish/config.fish
source ~/.config/fish/config.fish  # 再読み込み
```

## 🔧 主要エイリアス

Fish設定で以下のエイリアスが利用可能：

```fish
vim/vi/v    → nvim
gd          → gh dash
lg          → lazygit
ls/la/ll    → lsd
sls         → sbcl (Common Lisp REPL with nvlime)
```

## 📝 Laravelプロジェクトはじめかた

インストール完了後、すぐにLaravelプロジェクトを作成できます：

```bash
# MySQLを起動（インストール時に起動していない場合）
brew services start mysql@8.0

# Laravelプロジェクト作成
laravel new my-project
cd my-project

# 開発サーバー起動
php artisan serve
```

## 🔍 トラブルシューティング

### インストールログの確認

```bash
ls ~/.dotfiles_install_logs/
cat ~/.dotfiles_install_logs/install_*.log
```

### バックアップの確認

既存設定のバックアップは `~/.dotfiles_backup_YYYYMMDD_HHMMSS/` に保存されます。

### 再インストール

```bash
cd ~/dotfiles
./install.sh  # 何度でも実行可能（冪等性保証）
```

## 📚 ドキュメント

- [CLAUDE.md](./CLAUDE.md) - Claude Code用のリポジトリガイド
- [Neovim LazyVim Docs](https://www.lazyvim.org/)
- [Fish Shell Docs](https://fishshell.com/docs/current/)

## 🙏 使用ツール・謝辞

- [LazyVim](https://www.lazyvim.org/) - Neovim設定フレームワーク
- [bobthefish](https://github.com/oh-my-fish/theme-bobthefish) - Fishテーマ
- [Homebrew](https://brew.sh/) - macOSパッケージマネージャー
- その他、各種オープンソースプロジェクト

## 📄 ライセンス

MIT License - 個人使用向け
