#!/bin/bash

################################################################################
# dotfiles インストールスクリプト
# 対象: macOS (Apple Silicon)
#
# 環境管理は Nix (flakes + nix-darwin + home-manager + Determinate) で宣言化済。
# 本スクリプトの役割は薄い orchestration:
#   1. Determinate Nix のブートストラップ
#   2. `darwin-rebuild switch` で flake を一括同期
#      （CLI 33 / brew 24 / cask 13 / macOS 設定 / symlink を全て反映）
#   3. post-config: Nix では非推奨な処理だけ実行
#      - PHP/Composer の PATH 補強 + MySQL 起動
#      - Rust (rustup) / Node (nodebrew) / Ruby (rbenv) の言語ランタイム導入
#      - Fish のデフォルトシェル切替 (chsh)
#      - Neovim プラグイン初回投入
#
# 詳細: docs/nix-adoption-report.md
################################################################################

set -u # 未定義変数の使用でエラー

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ログディレクトリ
LOG_DIR="$HOME/.dotfiles_install_logs"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"

# グローバル変数
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

################################################################################
# ユーティリティ関数
################################################################################

log() {
  echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

success() {
  echo -e "${GREEN}✓${NC} $*" | tee -a "$LOG_FILE"
}

error() {
  echo -e "${RED}✗${NC} $*" | tee -a "$LOG_FILE"
}

warning() {
  echo -e "${YELLOW}⚠${NC} $*" | tee -a "$LOG_FILE"
}

info() {
  echo -e "${BLUE}ℹ${NC} $*" | tee -a "$LOG_FILE"
}

step() {
  echo -e "\n${MAGENTA}==>${NC} ${BOLD}$*${NC}" | tee -a "$LOG_FILE"
}

confirm() {
  local message="$1"
  local response
  echo -ne "${YELLOW}?${NC} $message [y/N]: "
  read -r response
  case "$response" in
  [yY][eE][sS] | [yY]) return 0 ;;
  *) return 1 ;;
  esac
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

backup_if_exists() {
  local target="$1"
  if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    local backup_path="$BACKUP_DIR/$(basename "$target")"
    warning "バックアップ: $target -> $backup_path"
    mv "$target" "$backup_path"
    return 0
  fi
  return 1
}

create_symlink() {
  local source="$1"
  local target="$2"

  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
    info "既にリンク済み: $target"
    return 0
  fi

  backup_if_exists "$target"

  ln -sf "$source" "$target"
  if [[ $? -eq 0 ]]; then
    success "シンボリックリンク作成: $target -> $source"
    return 0
  else
    error "シンボリックリンク作成失敗: $target"
    return 1
  fi
}

################################################################################
# システムチェック
################################################################################

check_system() {
  step "システム環境のチェック"

  # macOSチェック
  if [[ "$(uname)" != "Darwin" ]]; then
    error "このスクリプトはmacOS専用です"
    exit 1
  fi
  success "macOS検出"

  # Apple Siliconチェック
  if [[ "$(uname -m)" != "arm64" ]]; then
    error "このスクリプトはApple Silicon専用です"
    exit 1
  fi
  success "Apple Silicon検出"

  # Xcodeコマンドラインツールのチェック
  if ! xcode-select -p &>/dev/null; then
    warning "Xcode Command Line Toolsがインストールされていません"
    info "インストールを開始します..."
    xcode-select --install
    confirm "Xcode Command Line Toolsのインストールが完了したらEnterを押してください" || exit 1
  fi
  success "Xcode Command Line Tools確認"
}

################################################################################
# Homebrewのインストール
################################################################################

install_homebrew() {
  step "Homebrewのセットアップ"

  if command_exists brew; then
    success "Homebrew既にインストール済み"
    info "Homebrewを更新中..."
    brew update 2>&1 | tee -a "$LOG_FILE"
  else
    info "Homebrewをインストール中..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOG_FILE"

    # 現プロセスでこのあとの brew コマンドを使えるようにする (~/.zprofile への永続化はしない:
    # zsh login shell 用 env は nix-darwin / home-manager 側で宣言する方針)
    eval "$(/opt/homebrew/bin/brew shellenv)"

    success "Homebrewインストール完了"
  fi
}

################################################################################
# Nix + nix-darwin ブートストラップ
#
# brew formula / cask / tap および CLI ツール群は flake.nix に宣言済のため、
# `darwin-rebuild switch` 一発で全て同期される。
# 詳細は docs/nix-adoption-report.md を参照。
################################################################################

bootstrap_nix() {
  step "Nix + nix-darwin のブートストラップ"

  # Determinate Nix のインストール
  if ! command_exists nix; then
    info "Determinate Nix をインストール中..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
    success "Determinate Nix インストール完了"
    info "新しいシェルセッションで PATH を再読み込みしてください"
  else
    success "Nix 既にインストール済み"
  fi

  # darwin-rebuild がまだ無い場合（初回ブートストラップ）
  if ! command_exists darwin-rebuild && [ ! -x "/run/current-system/sw/bin/darwin-rebuild" ]; then
    info "初回 darwin-rebuild ブートストラップ中..."
    sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake "$DOTFILES_DIR#MacBook-Air"
    success "初回ブートストラップ完了"
  fi

  # 通常の switch（flake 内容に同期）
  info "darwin-rebuild switch 実行中..."
  sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "$DOTFILES_DIR#MacBook-Air"
  success "システム同期完了"
}

################################################################################
# PHP/Composer/Laravel環境のセットアップ
################################################################################

setup_php_environment() {
  step "PHP/Composer/Laravel環境のセットアップ"

  # mysql@8.0 / composer global の PATH は home/taktiks2.nix の programs.fish.shellInit
  # で宣言済（fish 中心運用のため zsh login shell には流し込まない）。
  # Laravel Installer のインストールは home.activation.bootstrapSideEffects に移譲。

  # PHP拡張の確認
  info "PHP設定の確認"
  php -v | tee -a "$LOG_FILE"

  # MySQL起動設定
  info "MySQLサービスの設定"
  if confirm "MySQLを起動しますか？"; then
    brew services start mysql@8.0
    success "MySQL起動完了"
  fi
}

################################################################################
# Rustのインストール
################################################################################

install_rust() {
  step "Rust (cargo)のセットアップ"

  if command_exists rustc; then
    success "Rust既にインストール済み"
    info "Rustを更新中..."
    rustup update 2>&1 | tee -a "$LOG_FILE"
  else
    info "Rustをインストール中..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tee -a "$LOG_FILE"
    source "$HOME/.cargo/env"
    success "Rustインストール完了"
  fi
}

################################################################################
# Fishのセットアップ
################################################################################

setup_fish() {
  step "Fish Shell のセットアップ（chsh のみ）"

  # Fish 本体・plugins (bobthefish/z/bass)・config.fish は home-manager (programs.fish) で管理。
  # /etc/shells への登録は nix-darwin の `environment.shells` で実施。
  # secret-env.fish のテンプレ生成は home.activation.bootstrapSideEffects に移譲。

  local nix_fish="/run/current-system/sw/bin/fish"
  if [[ ! -x "$nix_fish" ]]; then
    info "Nix 版 fish が未配置（先に darwin-rebuild switch が必要）。chsh をスキップ"
    return 0
  fi

  if [[ "$SHELL" != "$nix_fish" ]]; then
    if confirm "デフォルトシェルを Nix 版 fish ($nix_fish) に変更しますか？"; then
      info "デフォルトシェルを変更中..."
      chsh -s "$nix_fish"
      success "デフォルトシェルを変更しました"
    fi
  else
    success "既に Nix 版 fish がデフォルトシェルです"
  fi
}

################################################################################
# Node.js環境のセットアップ
################################################################################

setup_nodejs() {
  step "Node.js環境のセットアップ"

  if [[ -d "$HOME/.nodebrew" ]]; then
    success "nodebrew既にセットアップ済み"
  else
    info "nodebrewをセットアップ中..."
    nodebrew setup 2>&1 | tee -a "$LOG_FILE"
    success "nodebrewセットアップ完了"
  fi

  info "Node.jsの最新安定版をインストール中..."
  nodebrew install-binary stable 2>&1 | tee -a "$LOG_FILE"
  nodebrew use stable 2>&1 | tee -a "$LOG_FILE"
  success "Node.jsインストール完了"
}

################################################################################
# Claude Code (CLI) のセットアップ
#
# - claude-code 本体を npm global で冪等インストール / 更新
# - statusLine 用の ccstatusline をローカル配置（settings.json から呼ぶ）
# - ~/.claude を dotfiles/.claude への symlink として張る（既存 symlink は維持）
# 依存: setup_nodejs が先に走り、npm が PATH に乗っていること
################################################################################

setup_claude_code() {
  step "Claude Code CLI のセットアップ"

  if ! command_exists npm; then
    warning "npm が見つからないため Claude Code のインストールをスキップ"
    return 0
  fi

  # claude-code 本体
  if command_exists claude; then
    info "claude-code を更新中..."
    npm update -g @anthropic-ai/claude-code 2>&1 | tee -a "$LOG_FILE" || \
      warning "claude-code の更新に失敗（継続）"
    success "claude-code 確認: $(claude --version 2>/dev/null | head -1)"
  else
    info "claude-code をインストール中..."
    if npm install -g @anthropic-ai/claude-code 2>&1 | tee -a "$LOG_FILE"; then
      success "claude-code インストール完了"
    else
      error "claude-code のインストールに失敗"
    fi
  fi

  # 周辺ツール:
  #   - ccstatusline: settings.json の statusLine から呼ぶ
  #   - ccusage: Claude Code のトークン使用量・コスト集計
  #   - diffity: ブラウザで GitHub 風の git diff を表示
  for pkg in ccstatusline ccusage diffity; do
    if command_exists "$pkg"; then
      success "$pkg 既にインストール済み"
    else
      info "$pkg をインストール中..."
      npm install -g "$pkg" 2>&1 | tee -a "$LOG_FILE" || \
        warning "$pkg のインストールに失敗（継続）"
    fi
  done

  # ~/.claude を dotfiles/.claude へ symlink
  local claude_link="$HOME/.claude"
  local claude_target="$DOTFILES_DIR/.claude"

  if [[ -L "$claude_link" ]] && [[ "$(readlink "$claude_link")" == "$claude_target" ]]; then
    success "~/.claude は既に正しい symlink"
  elif [[ -e "$claude_link" ]]; then
    warning "~/.claude が存在し symlink ではない。手動で確認してください (現状を尊重しスキップ)"
  else
    ln -s "$claude_target" "$claude_link"
    success "~/.claude -> $claude_target を作成"
  fi
}

################################################################################
# Ruby環境のセットアップ
################################################################################

setup_ruby() {
  step "Ruby環境のセットアップ"

  # rbenvの初期化
  if command_exists rbenv; then
    eval "$(rbenv init - bash)"

    # 最新安定版のRubyをインストール
    local latest_ruby=$(rbenv install -l | grep -v - | tail -1 | tr -d ' ')

    if ! rbenv versions | grep -q "$latest_ruby"; then
      info "Ruby $latest_ruby をインストール中..."
      rbenv install "$latest_ruby" 2>&1 | tee -a "$LOG_FILE"
      rbenv global "$latest_ruby"
      success "Ruby $latest_ruby インストール完了"
    else
      success "Ruby $latest_ruby 既にインストール済み"
    fi

    # CocoaPodsのインストール
    if ! gem list cocoapods -i &>/dev/null; then
      info "CocoaPodsをインストール中..."
      gem install cocoapods 2>&1 | tee -a "$LOG_FILE"
      success "CocoaPodsインストール完了"
    else
      success "CocoaPods既にインストール済み"
    fi
  fi
}

################################################################################
# tmuxのセットアップ
################################################################################

setup_tmux() {
  step "tmux 補助情報"
  # TPM のクローンは home/taktiks2.nix の home.activation.bootstrapSideEffects に移譲。
  info "tmux 起動後に 'Ctrl+s' + 'I' を押すとプラグインが導入される"
}

################################################################################
# シンボリックリンクの作成 — home-manager の `home.activation.dotfilesSymlinks`
# が `~/.config` および lazygit config の symlink を冪等管理するため、本セクションは廃止。
# 詳細は home/taktiks2.nix を参照。
################################################################################

################################################################################
# Neovimのセットアップ
################################################################################

setup_neovim() {
  step "Neovimのセットアップ"

  info "初回起動でプラグインが自動インストールされます"

  if confirm "今すぐNeovimを起動してプラグインをインストールしますか？"; then
    info "Neovimを起動します（:qa で終了してください）..."
    sleep 2
    nvim +Lazy +qall
    success "Neovimプラグインのインストール完了"
  else
    info "後でNeovimを起動してプラグインをインストールしてください"
  fi
}

################################################################################
# 最終確認とメッセージ
################################################################################

final_check() {
  step "インストール完了確認"

  echo ""
  echo "================================"
  echo "  インストール完了!"
  echo "================================"
  echo ""

  # 主要ツールの確認（Nix 経由 / brew 経由 / post-config の混合）
  local tools=(
    # Nix (home-manager)
    "fish:Fish Shell (Nix)"
    "nvim:Neovim (Nix)"
    "tmux:tmux (Nix)"
    "lazygit:Lazygit (Nix)"
    "rg:ripgrep (Nix)"
    "jq:jq (Nix)"
    "delta:git-delta (Nix)"
    "direnv:direnv (Nix)"
    # Homebrew (nix-darwin で宣言)
    "brew:Homebrew"
    "php:PHP (brew)"
    "composer:Composer (brew)"
    "mysql:MySQL (brew)"
    # post-config
    "laravel:Laravel Installer (post-config)"
    "node:Node.js (nodebrew)"
    "ruby:Ruby (rbenv)"
    "cargo:Rust (rustup)"
    "claude:Claude Code (npm)"
    "ccstatusline:ccstatusline (npm)"
    "ccusage:ccusage (npm)"
    "diffity:diffity (npm)"
  )

  echo "主要ツール:"
  for tool_pair in "${tools[@]}"; do
    IFS=':' read -r cmd name <<<"$tool_pair"
    if command_exists "$cmd"; then
      echo -e "  ${GREEN}✓${NC} $name"
    else
      echo -e "  ${RED}✗${NC} $name"
    fi
  done

  echo ""
  echo "次のステップ:"
  echo "  1. 新しいターミナルウィンドウを開いて Fish が起動するか確認"
  echo "     （chsh 済の場合はログインシェルが Nix 版 fish になっている）"
  echo "  2. tmux を起動して Ctrl+s + I でプラグインをインストール"
  echo "  3. Neovim 起動時にプラグインが自動展開される（:Lazy で確認）"
  echo "  4. ~/.config/fish/secret-env.fish に必要な秘匿環境変数を追記"
  echo ""
  echo "日常運用:"
  echo "  - 設定変更 → \$EDITOR ~/dotfiles/home/taktiks2.nix → sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air"
  echo "  - 緊急ロールバック → sudo darwin-rebuild --rollback"
  echo "  - 新規プロジェクトの devShell → nix flake init -t ~/dotfiles && direnv allow"
  echo ""

  if [[ -d "$BACKUP_DIR" ]]; then
    echo "バックアップディレクトリ: $BACKUP_DIR"
    echo ""
  fi

  echo "ログファイル: $LOG_FILE"
  echo ""
}

################################################################################
# メイン処理
################################################################################

main() {
  # ログディレクトリの作成
  mkdir -p "$LOG_DIR"

  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║   dotfiles インストールスクリプト      ║"
  echo "║   macOS (Apple Silicon) 専用           ║"
  echo "╚════════════════════════════════════════╝"
  echo ""

  log "インストール開始: $DOTFILES_DIR"

  # 各ステップの実行
  check_system
  install_homebrew    # nix-darwin の homebrew モジュールが /opt/homebrew を参照するため必須
  bootstrap_nix       # Nix + nix-darwin で brew formula/cask/tap, CLI, macOS 設定, symlink を一括同期
  setup_php_environment  # post-config: composer global require laravel/installer
  install_rust           # post-config: rustup toolchain
  setup_nodejs           # post-config: nodebrew install latest
  setup_claude_code      # post-config: npm i -g @anthropic-ai/claude-code + ccstatusline + symlink
  setup_ruby             # post-config: rbenv install $version
  setup_fish             # post-config: Fisher + bobthefish + chsh + secret-env テンプレ
  setup_tmux             # post-config: TPM clone
  setup_neovim           # post-config: :Lazy install
  final_check

  success "全ての処理が完了しました！"
}

# スクリプト実行
main "$@"
