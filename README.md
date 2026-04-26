# dotfiles

macOS (Apple Silicon) 用の個人 dotfiles。**Nix (flakes + nix-darwin + home-manager + Determinate)** で開発環境を宣言的に管理しています。

## 🚀 クイックスタート

```bash
# 1. Determinate Nix をインストール
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate

# 2. リポジトリをクローン
git clone git@github.com:taktiks2/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 3. インストールスクリプトを実行（Nix bootstrap + post-config）
./install.sh
```

`install.sh` は薄い orchestration で、本体の宣言は `flake.nix` 配下にあります。`darwin-rebuild switch` 一発で CLI / Homebrew / macOS 設定 / symlink まで全て同期されます。

## 🏗️ アーキテクチャ

4 層の宣言的管理 + 1 層の post-config:

```
┌────────────────────────────────────────────────────────────────┐
│ Nix (home-manager)        CLI 33 + Fish 4.6 + plugins          │
│   /etc/profiles/per-user/taktiks2/bin/                         │
├────────────────────────────────────────────────────────────────┤
│ Homebrew (nix-darwin で宣言)  formula 24 + cask 13 + tap 12    │
│   /opt/homebrew/  (cleanup="uninstall" で git に完全同期)      │
├────────────────────────────────────────────────────────────────┤
│ macOS system.defaults     Dock / Finder / Trackpad 等           │
├────────────────────────────────────────────────────────────────┤
│ home.activation           dotfilesSymlinks + bootstrapSideEffects │
│                           (TPM / secret-env テンプレ / Laravel)  │
├────────────────────────────────────────────────────────────────┤
│ direnv + nix-direnv       プロジェクト単位の devShell 自動有効化 │
└────────────────────────────────────────────────────────────────┘
```

post-config (`install.sh`): PHP / MySQL / Rust (rustup) / Node (nodebrew) / Ruby (rbenv) / Neovim プラグインの初回投入。

## 📦 管理される内容

### Nix (home-manager) — CLI 33 本 + Fish

検索/ファイル: ripgrep, fd, fzf, bat, lsd, tree, broot, fswatch, joshuto
Git/開発: gh, delta, git-filter-repo, lazygit, lazydocker, cocogitto, tbls
エディタ/マルチプレクサ: neovim, tmux
JSON/テキスト: jq, gnused
ネットワーク/シェル: wget, bash, bats, fish 4.6
ビジュアル/システム: btop, graphviz, television
言語/ビルド: zig, deno, uv, sbcl, cargo-binstall
AI/その他: aichat, just
direnv (+ nix-direnv)

Fish plugins (Fisher 撤廃、Nix 直接管理): bobthefish / z / bass

### Homebrew (`modules/homebrew.nix` で宣言)

- **言語ランタイム**: composer, luarocks, nodebrew, python@3.10, rbenv
- **DB**: mysql, mysql@8.0, postgresql@14
- **重量ビルド**: bundletool, clisp, openapi-generator, qemu
- **ベンダー CLI**: azure-cli, docker, fastlane, gemini-cli, supabase
- **第三者 tap**: qmk, atac, workmux, unrar, avr-gcc@9, heroku
- **嗜好**: rogue
- **GUI cask 13** + Nerd Fonts: VS Code / Warp / Ghostty / UTM / Bruno / Godot 等

完全な内訳は `modules/homebrew.nix` および `docs/brew-triage.md` を参照。

### macOS system.defaults

Dock 自動隠し、Finder リスト表示、ダーク Mode、スクリーンショット保存先、トラックパッドのタップクリック等を `modules/macos-defaults.nix` で固定。OPT-IN 候補（拡張子表示、自動修正系の無効化、KeyRepeat 最速化）はコメント形式で同梱。

### home.activation

- `dotfilesSymlinks`: `~/.config/{nvim, git, alacritty, ...}` 計 12 ディレクトリと lazygit の symlink を冪等保証
- `bootstrapSideEffects`: TPM (tmux plugin manager) clone、`~/.config/fish/secret-env.fish` テンプレ生成、Laravel Installer の初回投入

### post-config (install.sh が担当)

- PHP/Composer/MySQL のセットアップ（brew formula 経由のサービス起動・PATH 設定）
- Rust (rustup)、Node.js (nodebrew)、Ruby (rbenv) の初回インストール
- Fish の chsh
- Neovim プラグインの初回展開 (`:Lazy install`)

## 📋 システム要件

- macOS (Apple Silicon)
- Determinate Nix
- Xcode Command Line Tools（`install.sh` が自動でインストール案内）

## 🛠 ファイル構成

```
~/dotfiles/
├── flake.nix                     # Nix flake エントリ (inputs / darwinConfigurations / templates)
├── flake.lock                    # 依存バージョンロック
├── hosts/
│   └── MacBook-Air/
│       └── default.nix           # nix-darwin: networking / shells / system.primaryUser
├── home/
│   └── taktiks2.nix              # home-manager: Nix CLI / programs.fish / direnv / activation
├── modules/
│   ├── homebrew.nix              # tap / formula / cask 宣言
│   └── macos-defaults.nix        # system.defaults.* (ACTIVE / OPT-IN)
├── templates/
│   └── default/                  # `nix flake init -t ~/dotfiles` 用の汎用 devShell
├── .config/
│   ├── nvim/                     # Neovim (LazyVim) 設定
│   ├── alacritty/                # Alacritty 設定
│   ├── ghostty/                  # Ghostty 設定
│   ├── tmux/                     # tmux 設定
│   ├── git/                      # Git 設定
│   ├── atac/                     # ATAC (API クライアント) 設定
│   ├── ccstatusline/             # Claude Code statusline 設定
│   ├── btop/  cspell/  gh-dash/  mcphub/  workmux/
│   └── (fish は home-manager 管理。dotfiles repo に置かない)
├── config.yml                    # Lazygit 設定 (~/Library/Application Support/lazygit/ に symlink)
├── install.sh                    # Nix bootstrap + post-config orchestration
└── docs/
    ├── nix-adoption-report.md    # Nix 導入レポート (Step 1〜7 + 監査フォローアップ)
    └── brew-triage.md            # brew formula 仕分け表
```

秘匿情報 `~/.config/fish/secret-env.fish` は **dotfiles repo 外** に配置（`bootstrapSideEffects` がテンプレを生成、実値はマシンごとに編集）。

## 🎯 日常運用

### 何かを足したい

| 種類 | 編集ファイル | 適用 |
|---|---|---|
| Nix CLI | `home/taktiks2.nix` の `home.packages` | `sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air` |
| brew formula / cask | `modules/homebrew.nix` の `brews` / `casks` | 同上 |
| macOS 設定 | `modules/macos-defaults.nix` | 同上 |
| Fish 設定 | `home/taktiks2.nix` の `programs.fish.{shellInit, interactiveShellInit, shellAliases}` | 同上 |

### Fish 設定の編集

`~/.config/fish/config.fish` は **Nix 生成 symlink** のため直接編集してはいけません。`home/taktiks2.nix` の `programs.fish` セクションを編集してください。

### 秘匿情報の管理

```fish
# ~/.config/fish/secret-env.fish (gitignore 対象、dotfiles repo 外)
set -x GITHUB_TOKEN "your_token_here"
set -x OPENAI_API_KEY "your_api_key_here"
```

### 新規プロジェクトの devShell

```bash
mkdir my-project && cd my-project
nix flake init -t ~/dotfiles      # 汎用 devShell テンプレを投入
$EDITOR flake.nix                 # 必要なランタイムを packages に追加
direnv allow                      # 以後 cd で自動有効化
```

### 月次メンテ

```bash
cd ~/dotfiles
nix flake update                                  # 全 input を最新化
sudo darwin-rebuild switch --flake .#MacBook-Air  # 適用
```

## 🔧 主要エイリアス

`programs.fish.shellAliases` で宣言（`home/taktiks2.nix` 参照）:

```fish
vim, vi, v   → nvim
ghd          → gh dash
lg           → lazygit
ls           → lsd
la           → lsd -a
ll           → lsd -al
sls          → sbcl --load ~/.local/share/nvim/lazy/nvlime/lisp/start-nvlime.lisp
wm           → workmux
agents       → agents.fish
css          → tmux attach-session -t shogun
csm          → tmux attach-session -t multiagent
```

## 📝 Laravel プロジェクトの始め方

```bash
brew services start mysql@8.0   # MySQL 起動
laravel new my-project          # Laravel Installer (home.activation で自動導入済)
cd my-project
php artisan serve
```

## 🔍 トラブルシューティング

### 緊急ロールバック

```bash
sudo darwin-rebuild --rollback
```

`/nix/var/nix/profiles/system-*-link` に積み上がった世代へ即座に戻せます。

### インストールログ

```bash
ls ~/.dotfiles_install_logs/
cat ~/.dotfiles_install_logs/install_*.log
```

### バックアップ

既存設定のバックアップは `~/.dotfiles_backup_YYYYMMDD_HHMMSS/` および `*.hm-backup` (home-manager) に保存。

### 再適用

```bash
sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air
```

### symlink activation の WARN

`home.activation.dotfilesSymlinks` が「予期しない実体」を保護スキップしている可能性。手動で内容を確認してから削除 → 再 switch。

## 📚 詳細ドキュメント

- [docs/nix-adoption-report.md](./docs/nix-adoption-report.md) — Nix 導入レポート（Step 1〜7 + 監査フォローアップの完全な実施記録）
- [docs/brew-triage.md](./docs/brew-triage.md) — brew formula 仕分け表
- [CLAUDE.md](./CLAUDE.md) — Claude Code 用のリポジトリガイド
- [LazyVim](https://www.lazyvim.org/) / [Fish Shell](https://fishshell.com/docs/current/)

## 🙏 使用ツール・謝辞

- [nix-darwin](https://github.com/nix-darwin/nix-darwin) — macOS の宣言的システム管理
- [home-manager](https://github.com/nix-community/home-manager) — ユーザ環境の宣言的管理
- [Determinate Systems](https://determinate.systems/) — Determinate Nix インストーラとモジュール
- [LazyVim](https://www.lazyvim.org/) — Neovim 設定フレームワーク
- [bobthefish](https://github.com/oh-my-fish/theme-bobthefish) — Fish テーマ
- [Homebrew](https://brew.sh/) — macOS パッケージマネージャ
- その他、各種オープンソースプロジェクト

## 📄 ライセンス

MIT License - 個人使用向け
