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
#   5. SSH 鍵 bootstrap (host 非依存):
#      - ~/.ssh/id_ed25519 (default、OS user に紐づく主アカウント用) を生成
#      - my.git.extraIdentities を nix eval で読み、宣言された各 sub-identity の
#        sshIdentityFile を生成（host 側で宣言ゼロなら no-op）
#      - 公開鍵を表示し、GitHub への登録 URL を提示（自動登録はしない）
#   6. Nix 管理境界外の最小 bootstrap:
#      - fnm + 4 つの npm global (claude / ccstatusline / ccusage / diffity)
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

# Phase 20: hostname 解決ポリシー（multi-host 対応）。
#   1. 引数 $1 があればそれを使う          (./install.sh MacBook-Pro)
#   2. scutil --get LocalHostName で取得   (既設 Mac で自動解決)
#   3. 取得失敗ならエラー終了              (フレッシュ Mac は出荷時 LocalHostName が
#                                           flake の attribute と一致しないことが多いため
#                                           誤った host で switch してハマるのを避ける)
#   実在性は bootstrap_nix で nix eval により検証する。
HOST_NAME="${1:-}"
if [ -z "$HOST_NAME" ]; then
  HOST_NAME="$(scutil --get LocalHostName 2>/dev/null || true)"
fi
if [ -z "$HOST_NAME" ]; then
  echo "ERROR: ホスト名を解決できません。引数で明示してください: ./install.sh <HostName>" >&2
  echo "       例: ./install.sh private" >&2
  exit 1
fi

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

setup_local_overrides() {
  step "ホスト固有 brew/cask の skip-worktree 設定 (modules/homebrew/local.nix)"
  local local_file="modules/homebrew/local.nix"
  local full_path="$DOTFILES_DIR/$local_file"

  if [ ! -f "$full_path" ]; then
    warning "$local_file が存在しません (git pull 漏れ？) — スキップ"
    return 0
  fi

  if ! (cd "$DOTFILES_DIR" && git ls-files --error-unmatch "$local_file" >/dev/null 2>&1); then
    warning "$local_file が git tracked ではありません — skip-worktree 設定をスキップ"
    return 0
  fi

  # `git ls-files -v` の先頭が 'S' なら skip-worktree 済 (idempotent check)。
  local flag
  flag=$(cd "$DOTFILES_DIR" && git ls-files -v "$local_file" | head -c1)
  if [ "$flag" = "S" ]; then
    success "skip-worktree 既に設定済 ($local_file)"
  else
    (cd "$DOTFILES_DIR" && git update-index --skip-worktree "$local_file")
    success "skip-worktree 設定完了 ($local_file の編集は git status に出ません)"
  fi
}

bootstrap_nix() {
  step "Determinate Nix + nix-darwin"
  if ! exists nix; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install --determinate
    success "Determinate Nix インストール完了"

    # Phase 20: インストーラは /etc/{zshenv,bashrc} に PATH を仕込むだけで
    # 現在の bash プロセスには反映されない。同セッションで `nix run` を呼ぶため
    # nix-daemon プロファイルを source して PATH を取り込む。
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      # shellcheck source=/dev/null
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  else
    success "Nix 既にあり"
  fi

  # Phase 20: switch 前に flake に host attribute が存在するか軽量検証。
  # 出荷時 LocalHostName が flake と一致しないケース等で意味不明なエラーを出さないため。
  local flake_attr="$DOTFILES_DIR#darwinConfigurations.\"$HOST_NAME\""
  if ! nix eval --no-warn-dirty "$flake_attr" --apply 'x: true' >/dev/null 2>&1; then
    error "darwinConfigurations.\"$HOST_NAME\" が flake.nix に未定義"
    error "  → flake.nix の darwinConfigurations に以下を追加してください:"
    error "      \"$HOST_NAME\" = mkDarwin { hostname = \"$HOST_NAME\"; username = \"<your-user>\"; };"
    exit 1
  fi

  # 初回は flake 同梱の nix-darwin (25.11 ピン) を `nix run` で取得して switch。
  # 2 回目以降は確立した /run/current-system 配下の darwin-rebuild を直接使う。
  # ※ 旧実装は両方走っており初回 switch が 2 重 + master / 25.11 の不一致があったため整理。
  #
  # ホスト固有の brew/cask は `modules/homebrew/local.nix`（git tracked + skip-worktree）
  # で上書き可能。setup_local_overrides で skip-worktree フラグを冪等にセット済。
  if ! exists darwin-rebuild && [ ! -x "/run/current-system/sw/bin/darwin-rebuild" ]; then
    log "初回 darwin-rebuild ブートストラップ中 (flake の nix-darwin-25.11 ピンを使用、host=$HOST_NAME)..."
    sudo nix run "github:nix-darwin/nix-darwin/nix-darwin-25.11#darwin-rebuild" -- \
      switch --flake "$DOTFILES_DIR#$HOST_NAME"
  else
    log "darwin-rebuild switch (flake 一括同期、host=$HOST_NAME) 中..."
    sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "$DOTFILES_DIR#$HOST_NAME"
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
# Node 管理は fnm (home/common.nix の home.packages で配布) を使用する。
# 共通の sessionPath に `~/.local/share/fnm/aliases/default/bin` が含まれるため、
# `fnm default lts-latest` 後は `claude`/`ccusage` 等の global CLI が直接 PATH 解決される。
setup_global_npm() {
  step "グローバル npm パッケージ (Nix 管理外、fnm 経由)"

  # fnm は darwin-rebuild switch で home.packages 経由で配布される。
  # Nix profile を PATH 先頭に追加して fnm を解決可能にする。
  export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

  if ! exists fnm; then
    warning "fnm が PATH に無いため npm global packages をスキップ"
    warning "post-install: 新シェルで fnm install --lts && npm install -g claude ccstatusline ccusage diffity"
    return
  fi

  # default Node が無ければ LTS を install
  if ! fnm list 2>/dev/null | grep -q 'default'; then
    log "fnm 経由で Node LTS を install"
    fnm install --lts
    fnm default lts-latest
  fi

  # current shell の PATH に fnm-managed Node を載せる
  eval "$(fnm env --shell bash)"

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
  # 旧 ln -s ロジックは撤廃済（home/common.nix の home.file.".claude" 参照）。
}

setup_ssh_keys() {
  step "SSH 鍵 bootstrap (default + my.git.extraIdentities)"

  # darwin-rebuild 直後、user profile の bin がまだ PATH に無いことがあるため
  # jq / nix CLI が引ける位置を念のため先頭に追加（このプロセス内限定）。
  export PATH="/etc/profiles/per-user/${USER}/bin:/run/current-system/sw/bin:$PATH"

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # github.com を known_hosts に登録（初回 ssh の "yes/no" プロンプトを抑止、idempotent）
  if [ ! -f "$HOME/.ssh/known_hosts" ] \
     || ! ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" >/dev/null 2>&1; then
    log "github.com を known_hosts に追加..."
    ssh-keyscan -t ed25519,rsa github.com 2>/dev/null >> "$HOME/.ssh/known_hosts" \
      || warning "ssh-keyscan 失敗 (継続)"
  fi

  # default 鍵 (~/.ssh/id_ed25519): 既存があれば再生成しない (idempotent)。
  # ssh-keygen はパスフレーズを対話入力する。空 Enter 2 回で no passphrase。
  local default_key="$HOME/.ssh/id_ed25519"
  if [ -f "$default_key" ]; then
    log "default 鍵は既存: $default_key (再生成しない)"
  else
    log "default 鍵を生成: $default_key"
    ssh-keygen -t ed25519 -C "${USER}@$(hostname -s)" -f "$default_key" \
      || warning "ssh-keygen (default) 中断 (継続)"
  fi

  # my.git.extraIdentities を Nix から読み出す（host で宣言が無ければ {}）。
  # eval が失敗 (flake 未 build / 設定 typo 等) してもインストール全体は止めない。
  local ids_json='{}'
  if exists nix; then
    local hm_path=".#darwinConfigurations.\"$HOST_NAME\".config.home-manager.users.\"$USER\".my.git.extraIdentities"
    ids_json=$(cd "$DOTFILES_DIR" && nix eval --json --no-warn-dirty "$hm_path" 2>/dev/null) \
      || ids_json='{}'
  fi

  if [ -z "$ids_json" ] || [ "$ids_json" = "{}" ]; then
    log "my.git.extraIdentities は空 (sub-identity 鍵の生成は不要)"
  elif ! exists jq; then
    warning "jq が PATH に無いため extraIdentities のループをスキップ"
  else
    while IFS=$'\t' read -r id keyfile alias; do
      [ -z "$id" ] && continue
      if [ -z "$keyfile" ] || [ "$keyfile" = "null" ]; then
        log "extra identity '$id': sshIdentityFile 未指定 → 鍵生成スキップ"
        continue
      fi
      keyfile="${keyfile/#\~/$HOME}"   # ~ を $HOME に展開
      if [ -f "$keyfile" ]; then
        log "extra identity '$id' 鍵は既存: $keyfile (再生成しない)"
      else
        mkdir -p "$(dirname "$keyfile")"
        log "extra identity '$id' 鍵を生成: $keyfile (alias: ${alias:-<none>})"
        ssh-keygen -t ed25519 -C "${id}@$(hostname -s)" -f "$keyfile" \
          || warning "ssh-keygen ($id) 中断 (継続)"
      fi
    done < <(echo "$ids_json" | jq -r 'to_entries[] | "\(.key)\t\(.value.sshIdentityFile // "")\t\(.value.sshHostAlias // "")"')
  fi

  # 公開鍵 + 登録 URL のサマリ表示。実値の自動登録はしない（権限/2FA を強制要求しないため）。
  log ""
  log "公開鍵 (GitHub に登録):"
  shopt -s nullglob
  for pubkey in "$HOME/.ssh"/id_ed25519*.pub; do
    log "  $pubkey:"
    log "    $(cat "$pubkey")"
  done
  shopt -u nullglob
  log ""
  log "次にやること:"
  log "  1. 上記 .pub を https://github.com/settings/keys に登録"
  log "     (extra identity の鍵は対応する GitHub アカウントでログインしてから)"
  log "  2. 接続テスト:"
  log "       ssh -T git@github.com    # default"
  if [ -n "$ids_json" ] && [ "$ids_json" != "{}" ] && exists jq; then
    while IFS=$'\t' read -r id alias; do
      [ -z "$id" ] && continue
      [ -z "$alias" ] || [ "$alias" = "null" ] && continue
      log "       ssh -T git@${alias}    # extra identity '${id}'"
    done < <(echo "$ids_json" | jq -r 'to_entries[] | "\(.key)\t\(.value.sshHostAlias // "")"')
  fi
  log "  3. ~/.config/git/config.local (および config.<id>) に user.name / user.email を記入"

  success "SSH bootstrap 完了"
}

final_check() {
  step "完了"
  cat <<EOS
次のステップ:
  - 新しいターミナルで Nix fish が起動するか確認
  - 言語ランタイム別 devShell:
      nix flake init -t ~/dotfiles#laravel  (PHP)
      nix flake init -t ~/dotfiles#node     (Node)
      nix flake init -t ~/dotfiles#ruby     (Ruby)
      direnv allow
  - secrets 移行: docs/sops-migration.md 参照
  - git user.{name,email} を埋める: ~/.config/git/config.local
  - SSH 鍵 (~/.ssh/id_ed25519*.pub) を https://github.com/settings/keys に登録

日常運用:
  \$EDITOR ~/dotfiles/home/common.nix                    # 全ユーザ共通の baseline
  \$EDITOR ~/dotfiles/home/users/<username>.nix          # 個人差分 (任意)
  \$EDITOR ~/dotfiles/modules/homebrew/local.nix         # ホスト固有 brew/cask (skip-worktree で git status 非表示)
  sudo darwin-rebuild switch --flake ~/dotfiles#${HOST_NAME}

ロールバック:
  sudo darwin-rebuild --rollback
EOS
  echo "ログ: $LOG_FILE"
}

main() {
  mkdir -p "$LOG_DIR"
  log "dotfiles bootstrap 開始: $DOTFILES_DIR (host=$HOST_NAME)"
  check_system
  install_homebrew
  setup_local_overrides
  bootstrap_nix
  setup_fish_default_shell
  setup_ssh_keys
  setup_global_npm
  final_check
}

main "$@"
