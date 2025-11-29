#!/bin/bash

################################################################################
# dotfiles インストールスクリプト
# 対象: macOS (Apple Silicon)
# 必要な環境を完全自動でセットアップします
################################################################################

set -u # 未定義変数の使用でエラー

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
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

    # PATHを追加
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"

    success "Homebrewインストール完了"
  fi
}

################################################################################
# Homebrewパッケージのインストール
################################################################################

install_brew_packages() {
  step "Homebrewパッケージのインストール"

  local packages=(
    # 必須ツール
    "neovim"
    "fish"
    "ripgrep"
    "tree-sitter"
    "lazygit"
    "lazydocker"
    "git-delta"
    "lsd"
    "tmux"
    "gh"

    # PHP環境
    "php"
    "composer"
    "mysql@8.0"

    # その他の開発ツール
    "node"
    "nodebrew"
    "rbenv"
    "ruby-build"
  )

  for package in "${packages[@]}"; do
    if brew list "$package" &>/dev/null; then
      info "$package は既にインストール済み"
    else
      info "$package をインストール中..."
      brew install "$package" 2>&1 | tee -a "$LOG_FILE"
      if [[ $? -eq 0 ]]; then
        success "$package インストール完了"
      else
        error "$package インストール失敗"
      fi
    fi
  done
}

install_brew_casks() {
  step "Homebrewアプリケーション(Cask)のインストール"

  local casks=(
    "alacritty"
    "font-hack-nerd-font"
    "visual-studio-code"
    "google-chrome"
    "docker"
    "postman"
    "dbeaver-community"
    "slack"
  )

  # フォントタップの追加
  if ! brew tap | grep -q "homebrew/cask-fonts"; then
    info "homebrew/cask-fontsをタップ中..."
    brew tap homebrew/cask-fonts
  fi

  for cask in "${casks[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
      info "$cask は既にインストール済み"
    else
      info "$cask をインストール中..."
      if [[ "$cask" == "alacritty" ]]; then
        brew install --cask --no-quarantine "$cask" 2>&1 | tee -a "$LOG_FILE"
      else
        brew install --cask "$cask" 2>&1 | tee -a "$LOG_FILE"
      fi

      if [[ $? -eq 0 ]]; then
        success "$cask インストール完了"
      else
        warning "$cask インストールスキップ（既存または失敗）"
      fi
    fi
  done
}

################################################################################
# PHP/Composer/Laravel環境のセットアップ
################################################################################

setup_php_environment() {
  step "PHP/Composer/Laravel環境のセットアップ"

  # MySQL@8.0のPATH設定確認
  if ! grep -q "/opt/homebrew/opt/mysql@8.0/bin" ~/.zprofile 2>/dev/null; then
    info "MySQL@8.0のPATH設定を追加"
    echo 'export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"' >>~/.zprofile
  fi

  # Composerグローバルパッケージ
  info "Composerグローバルパッケージのセットアップ"

  # Composer global binのPATH確認
  if ! grep -q "/.composer/vendor/bin" ~/.zprofile 2>/dev/null; then
    echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >>~/.zprofile
  fi

  # Laravel Installerのインストール
  if ! command_exists laravel; then
    info "Laravel Installerをインストール中..."
    composer global require laravel/installer 2>&1 | tee -a "$LOG_FILE"
    success "Laravel Installerインストール完了"
  else
    success "Laravel Installer既にインストール済み"
  fi

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
  step "Fish Shellのセットアップ"

  # Fisherのインストール
  if [[ ! -f "$HOME/.config/fish/functions/fisher.fish" ]]; then
    info "Fisherをインストール中..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>&1 | tee -a "$LOG_FILE"
    success "Fisherインストール完了"
  else
    success "Fisher既にインストール済み"
  fi

  # bobthefishテーマのインストール
  info "bobthefishテーマをインストール中..."
  fish -c "fisher install oh-my-fish/theme-bobthefish" 2>&1 | tee -a "$LOG_FILE"
  success "bobthefishテーマインストール完了"

  # デフォルトシェルの変更
  if [[ "$SHELL" != "/opt/homebrew/bin/fish" ]]; then
    if confirm "デフォルトシェルをFishに変更しますか？"; then
      # /etc/shellsに追加
      if ! grep -q "/opt/homebrew/bin/fish" /etc/shells; then
        info "/etc/shellsにFishを追加中..."
        echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
      fi

      info "デフォルトシェルを変更中..."
      chsh -s /opt/homebrew/bin/fish
      success "デフォルトシェルをFishに変更しました"
    fi
  else
    success "既にFishがデフォルトシェルです"
  fi

  # secret-env.fishのテンプレート作成
  local secret_env="$DOTFILES_DIR/.config/fish/secret-env.fish"
  if [[ ! -f "$secret_env" ]]; then
    info "secret-env.fishテンプレートを作成中..."
    cat >"$secret_env" <<'EOF'
# 秘匿情報用の環境変数
# このファイルは.gitignoreに含まれています

# 例:
# set -x GITHUB_TOKEN "your_token_here"
# set -x OPENAI_API_KEY "your_api_key_here"
EOF
    success "secret-env.fishテンプレート作成完了"
    warning "必要に応じて $secret_env を編集してください"
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
  step "tmuxのセットアップ"

  # TPM (Tmux Plugin Manager)のインストール
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    info "TPM (Tmux Plugin Manager)をインストール中..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>&1 | tee -a "$LOG_FILE"
    success "TPMインストール完了"
  else
    success "TPM既にインストール済み"
    info "TPMを更新中..."
    cd "$tpm_dir" && git pull 2>&1 | tee -a "$LOG_FILE"
  fi

  info "tmux設定を有効にするには、tmux起動後に 'Ctrl+s' + 'I' を押してください"
}

################################################################################
# シンボリックリンクの作成
################################################################################

setup_symlinks() {
  step "シンボリックリンクのセットアップ"

  # .configディレクトリ
  if [[ -L "$HOME/.config" ]] && [[ "$(readlink "$HOME/.config")" == "$DOTFILES_DIR/.config" ]]; then
    success ".config は既にリンク済み"
  else
    if [[ -d "$HOME/.config" ]] && [[ ! -L "$HOME/.config" ]]; then
      warning "$HOME/.config が既に存在します"
      if confirm "既存の .config をバックアップしてリンクを作成しますか？"; then
        mkdir -p "$BACKUP_DIR"
        mv "$HOME/.config" "$BACKUP_DIR/config"
        create_symlink "$DOTFILES_DIR/.config" "$HOME/.config"
      else
        info ".config のリンク作成をスキップしました"
      fi
    else
      create_symlink "$DOTFILES_DIR/.config" "$HOME/.config"
    fi
  fi

  # lazygit設定
  local lazygit_config_dir="$HOME/Library/Application Support/lazygit"
  mkdir -p "$lazygit_config_dir"

  if [[ -f "$DOTFILES_DIR/config.yml" ]]; then
    if [[ -f "$lazygit_config_dir/config.yml" ]] && ! diff -q "$DOTFILES_DIR/config.yml" "$lazygit_config_dir/config.yml" &>/dev/null; then
      backup_if_exists "$lazygit_config_dir/config.yml"
    fi
    cp "$DOTFILES_DIR/config.yml" "$lazygit_config_dir/config.yml"
    success "lazygit設定をコピー完了"
  fi
}

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

  # インストール済みツールの確認
  local tools=(
    "brew:Homebrew"
    "fish:Fish Shell"
    "nvim:Neovim"
    "tmux:tmux"
    "lazygit:Lazygit"
    "delta:git-delta"
    "lsd:lsd"
    "php:PHP"
    "composer:Composer"
    "laravel:Laravel Installer"
    "node:Node.js"
    "ruby:Ruby"
    "cargo:Rust"
  )

  echo "インストール済みツール:"
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
  echo "  1. ターミナルを再起動してください"
  echo "  2. Fishシェルでログインし直してください"
  echo "  3. tmuxを起動して Ctrl+s + I でプラグインをインストールしてください"
  echo "  4. Neovimを起動してプラグインをインストールしてください (:Lazy)"
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
  install_homebrew
  install_brew_packages
  install_brew_casks
  setup_php_environment
  install_rust
  setup_nodejs
  setup_ruby
  setup_fish
  setup_tmux
  setup_symlinks
  setup_neovim
  final_check

  success "全ての処理が完了しました！"
}

# スクリプト実行
main "$@"
