#!/bin/bash
################################################################################
# dotfiles bootstrap スクリプト (Phase 14: Nix-first slim 化)
#
# 役割は最小限の orchestration:
#   1. システム前提 (macOS / Apple Silicon / xcode-select) のチェック
#   2. Homebrew 本体のインストール (nix-darwin の homebrew モジュールが /opt/homebrew を参照)
#   3. Determinate Nix のインストール + 初回 `darwin-rebuild switch`
#      → flake で CLI / formula / cask / macOS defaults / dotfiles symlink を一括同期
#   4. fish のデフォルトシェル化 (chsh)
#   5. Nix 管理境界外の最小 bootstrap:
#      - nodebrew + 4 つの npm global (claude / ccstatusline / ccusage / diffity)
#        ※ 頻繁に upstream が更新されるため npm 直管理を意図的に維持
#
# 削除済の責務 (Phase 6-13 + Phase 18 follow-up で Nix 化):
#   - PHP / Composer / Laravel Installer       → templates/laravel devShell
#   - Rust / cargo                              → Nix 化済 (home.packages の cargo-binstall)
#   - rbenv + Ruby                              → templates/ruby devShell
#   - Fish plugins (Fisher / bobthefish 等)     → programs.fish.plugins (Nix)
#   - tmux + TPM                                → programs.tmux.plugins (Nix)
#   - dotfiles symlink                          → xdg.configFile + mkOutOfStoreSymlink
#   - ~/.claude symlink                         → home.file.".claude" (mkOutOfStoreSymlink)
#   - Neovim プラグイン (:Lazy)                 → ユーザ手動 (`nvim +Lazy +qa`)
#
# 詳細: docs/nix-adoption-report.md
################################################################################

set -u

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/.dotfiles_install_logs"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"

log()     { echo -e "${CYAN}[$(date +'%H:%M:%S')]${NC} $*"     | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}✓${NC} $*"                          | tee -a "$LOG_FILE"; }
error()   { echo -e "${RED}✗${NC} $*"                            | tee -a "$LOG_FILE"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"                         | tee -a "$LOG_FILE"; }
step()    { echo -e "\n${MAGENTA}==>${NC} $*"                   | tee -a "$LOG_FILE"; }
exists()  { command -v "$1" >/dev/null 2>&1; }
confirm() { read -rp "$(echo -e "${YELLOW}?${NC} $1 [y/N]: ")" r; [[ "$r" =~ ^[yY]$ ]]; }

check_system() {
  step "システム前提のチェック"
  [[ "$(uname)" == "Darwin" ]]    || { error "macOS 専用";          exit 1; }
  [[ "$(uname -m)" == "arm64" ]]  || { error "Apple Silicon 専用";   exit 1; }
  if ! xcode-select -p &>/dev/null; then
    warning "Xcode CLT 未インストール"
    xcode-select --install
    # GUI ダイアログ完了を待つ（押すキーは何でも良い）
    read -rp "$(echo -e "${YELLOW}?${NC} Xcode CLT のインストール完了後 Enter: ")" _
  fi
  success "macOS / Apple Silicon / Xcode CLT OK"
}

install_homebrew() {
  step "Homebrew (nix-darwin homebrew モジュールの前提)"
  if exists brew; then
    success "Homebrew 既にあり"
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    success "Homebrew インストール完了"
  fi
}

bootstrap_nix() {
  step "Determinate Nix + nix-darwin"
  if ! exists nix; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install --determinate
    success "Determinate Nix インストール完了 (新シェルで PATH 再読込)"
  else
    success "Nix 既にあり"
  fi

  # 初回は flake 同梱の nix-darwin (25.11 ピン) を `nix run` で取得して switch。
  # 2 回目以降は確立した /run/current-system 配下の darwin-rebuild を直接使う。
  # ※ 旧実装は両方走っており初回 switch が 2 重 + master / 25.11 の不一致があったため整理。
  if ! exists darwin-rebuild && [ ! -x "/run/current-system/sw/bin/darwin-rebuild" ]; then
    log "初回 darwin-rebuild ブートストラップ中 (flake の nix-darwin-25.11 ピンを使用)..."
    sudo nix run "github:nix-darwin/nix-darwin/nix-darwin-25.11#darwin-rebuild" -- \
      switch --flake "$DOTFILES_DIR#MacBook-Air"
  else
    log "darwin-rebuild switch (flake 一括同期) 中..."
    sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "$DOTFILES_DIR#MacBook-Air"
  fi
  success "Nix システム同期完了"
}

setup_fish_default_shell() {
  step "fish をデフォルトシェルに (chsh)"
  local nix_fish="/run/current-system/sw/bin/fish"
  [[ -x "$nix_fish" ]] || { warning "Nix fish 未配置のためスキップ"; return; }
  if [[ "$SHELL" == "$nix_fish" ]]; then
    success "既に Nix fish がデフォルト"
  elif confirm "デフォルトシェルを Nix fish に変更しますか？"; then
    chsh -s "$nix_fish" && success "chsh 完了"
  fi
}

# ── Nix 管理境界外 ──────────────────────────────────────────────────────────
# 以下の 4 npm パッケージは upstream の更新が極めて頻繁なため、Nix 化せず
# `npm i -g` 直管理を意図的に維持する (Phase 12 決定):
#   - claude (Claude Code 本体)
#   - ccstatusline (settings.json の statusLine から呼ぶ)
#   - ccusage (Claude Code のトークン使用量・コスト集計)
#   - diffity (ブラウザで GitHub 風 git diff)
# 更新は `npm update -g <pkg>` を手動実行する運用。
# nodebrew + nodejs はこれらを動かすための最小依存として残置。
setup_global_npm() {
  step "グローバル npm パッケージ (Nix 管理外)"

  # nodebrew の最小 bootstrap (本格的な Node 利用は templates/node devShell へ)
  if [[ ! -d "$HOME/.nodebrew" ]] && exists nodebrew; then
    nodebrew setup
    nodebrew install-binary stable
    nodebrew use stable
  fi

  if ! exists npm; then
    warning "npm 未配置のため npm global packages をスキップ"
    return
  fi

  # pkg:bin マッピング (bash 3.2 互換のため文字列で管理)
  # @anthropic-ai/claude-code は `claude` という実バイナリを公開する点に注意。
  # 旧実装の `exists "$bin" || [ "$bin" = "claude-code" ] && exists claude` は
  # bash の `||`/`&&` 同優先度・左結合のため `(LHS) && exists claude` と評価され、
  # claude 未インストール時に他パッケージも誤って install 分岐に落ちる不具合があった。
  for entry in \
    "@anthropic-ai/claude-code:claude" \
    "ccstatusline:ccstatusline" \
    "ccusage:ccusage" \
    "diffity:diffity"
  do
    local pkg="${entry%%:*}"
    local bin="${entry##*:}"
    if exists "$bin"; then
      log "$pkg ($bin) を update"
      npm update -g "$pkg" 2>&1 | tee -a "$LOG_FILE" || warning "$pkg update 失敗 (継続)"
    else
      log "$pkg ($bin) を install"
      npm install -g "$pkg" 2>&1 | tee -a "$LOG_FILE" || warning "$pkg install 失敗 (継続)"
    fi
  done

  # ~/.claude → dotfiles/.claude symlink は home-manager (home.file.".claude") で管理されるため
  # 旧 ln -s ロジックは撤廃済（home/taktiks2.nix:home.file.".claude" 参照）。
}

final_check() {
  step "完了"
  cat <<'EOS'
次のステップ:
  - 新しいターミナルで Nix fish が起動するか確認
  - 言語ランタイム別 devShell:
      nix flake init -t ~/dotfiles#laravel  (PHP)
      nix flake init -t ~/dotfiles#node     (Node)
      nix flake init -t ~/dotfiles#ruby     (Ruby)
      direnv allow
  - secrets 移行: docs/sops-migration.md 参照

日常運用:
  $EDITOR ~/dotfiles/home/taktiks2.nix
  sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air

ロールバック:
  sudo darwin-rebuild --rollback
EOS
  echo "ログ: $LOG_FILE"
}

main() {
  mkdir -p "$LOG_DIR"
  log "dotfiles bootstrap 開始: $DOTFILES_DIR"
  check_system
  install_homebrew
  bootstrap_nix
  setup_fish_default_shell
  setup_global_npm
  final_check
}

main "$@"
