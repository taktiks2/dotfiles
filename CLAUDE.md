# CLAUDE.md

このファイルは Claude Code (claude.ai/code) がこのリポジトリを操作する際のガイドです。
ユーザー向けの全体像は `README.md`、設計の経緯は `docs/` 配下を参照してください。

## Repository Overview

macOS (Apple Silicon) 用の個人 dotfiles。
**Nix (flake + nix-darwin + home-manager + Determinate Nix)** で
開発環境を宣言的に管理しています。`darwin-rebuild switch` 一発で
CLI / Homebrew / macOS defaults / `~/.config/*` の symlink まで全て同期されます。

## Architecture

完全宣言化された 6 層構造（Phase 6–16 で post-config を最小化済）:

| レイヤ | 実体 | 場所 |
|---|---|---|
| Nix (home-manager) | CLI 33 本 + Fish 4.2 + plugins + tmux | `home/taktiks2.nix` |
| Homebrew (nix-darwin で宣言) | formula 24 + cask 13 + tap 12 | `modules/homebrew.nix` |
| macOS `system.defaults` | Dock / Finder / Trackpad / NSGlobalDomain 等 | `modules/macos-defaults.nix` |
| `xdg.configFile` (live link) | `~/.config/<tool>` → dotfiles repo を `mkOutOfStoreSymlink` | `home/taktiks2.nix` |
| sops-nix | AGE 暗号化 `secrets/secrets.yaml` を `~/.config/sops-nix/secrets/` に復号 | `home/taktiks2.nix` の `sops` |
| direnv + nix-direnv | プロジェクト単位 devShell の自動有効化 | `templates/` |

### 主要ファイル

```
flake.nix                       # inputs / mkDarwin factory / devShell templates
hosts/MacBook-Air/default.nix   # networking / system.primaryUser / programs.fish / fish 再署名 activation
home/taktiks2.nix               # home.packages / programs.{fish,tmux,direnv} / xdg.configFile / sops / activation
modules/homebrew.nix            # taps / brews / casks (cleanup = "uninstall")
modules/macos-defaults.nix      # system.defaults.* (ACTIVE / OPT-IN)
templates/                      # nix flake init -t 用 devShell (default / laravel / node / ruby / claude-project)
.config/<tool>/                 # mkOutOfStoreSymlink で ~/.config/<tool> に live link される設定
```

## Setup

```bash
# 1. Determinate Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  | sh -s -- install --determinate

# 2. clone & bootstrap
git clone git@github.com:taktiks2/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` (190 行) は **薄い orchestration** に縮小済み:

1. macOS / Apple Silicon / Xcode CLT チェック
2. Homebrew 本体投入（nix-darwin の homebrew モジュールが `/opt/homebrew` を参照）
3. Determinate Nix install + 初回 `darwin-rebuild switch`
4. fish の chsh
5. Nix 管理境界外の最小 bootstrap (nodebrew + npm global 4 本: `claude` / `ccstatusline` / `ccusage` / `diffity`)

## Daily Operations

| 何を | 編集ファイル | 適用 |
|---|---|---|
| Nix CLI | `home/taktiks2.nix` の `home.packages` | `sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air` |
| brew formula / cask | `modules/homebrew.nix` の `brews` / `casks` / `taps` | 同上 |
| macOS 設定 | `modules/macos-defaults.nix` | 同上 |
| Fish 設定 | `home/taktiks2.nix` の `programs.fish.{shellInit, interactiveShellInit, shellAliases, plugins}` | 同上 |
| tmux 設定 | `home/taktiks2.nix` の `programs.tmux.*` | 同上 |
| 月次更新 | `nix flake update` → `darwin-rebuild switch` | — |

### 直接編集してはいけないファイル

- `~/.config/fish/config.fish` — home-manager 生成 symlink。`programs.fish` セクションを編集
- `~/.config/tmux/tmux.conf` — `programs.tmux` から生成される
- `/etc/profiles/per-user/taktiks2/bin/*` — Nix store の symlink

## Secrets

二系統:

- **推奨**: `secrets/secrets.yaml` を sops-nix で AGE 暗号化、git tracked。
  AGE 鍵は `~/Library/Application Support/sops/age/keys.txt`
  （Mic92/sops-nix README 推奨パス）。手順: `docs/sops-migration.md`
- **互換**: `~/.config/fish/secret-env.fish`（dotfiles repo 外、
  `home.activation.bootstrapSideEffects` がテンプレ生成。sops 移行完了後は撤廃予定）

`programs.fish.interactiveShellInit` が起動時に `~/.config/sops-nix/secrets/<KEY>`
を環境変数へ展開する（`PATH` / `HOME` 等の予約名は skip、識別子の regex で防御）。

## Templates / devShells

```bash
mkdir my-project && cd my-project

nix flake init -t ~/dotfiles            # 汎用 (templates/default)
nix flake init -t ~/dotfiles#laravel    # PHP 8.4 + Composer
nix flake init -t ~/dotfiles#node       # Node.js 22 + corepack
nix flake init -t ~/dotfiles#ruby       # Ruby 3.3 + bundler

direnv allow                            # 以後 cd で自動有効化
```

`templates/claude-project/` は `cp -r` 用の Claude Code スケルトン
（CLAUDE.md / .mcp.json / .claude/{settings.json, agents/code-reviewer.md, skills/project-plan/SKILL.md} / .gitignore 同梱）。

## Common Aliases

`home/taktiks2.nix` の `programs.fish.shellAliases`:

```fish
vim, vi, v   → nvim
ghd          → gh dash
lg           → lazygit
ls, la, ll   → lsd, lsd -a, lsd -al
sls          → sbcl --load ~/.local/share/nvim/lazy/nvlime/lisp/start-nvlime.lisp
wm           → workmux
agents       → agents.fish
css          → tmux attach-session -t shogun
csm          → tmux attach-session -t multiagent
```

## Troubleshooting

- 緊急ロールバック: `sudo darwin-rebuild --rollback`
- インストールログ: `~/.dotfiles_install_logs/install_*.log`
- `~/.config/<name>` が既に別 symlink/実体だと HM が `*.hm-backup` で退避（要手動確認）
- fish 4.2.x の SIGKILL 問題は `hosts/MacBook-Air/default.nix` の
  `system.activationScripts.postActivation` で ad-hoc 再署名済（自動）

## CI

- `.github/workflows/nix-check.yml` — push / PR ごとに `flake-checker` + `nix flake check` + `darwin-rebuild build` (macos-14)
- `.github/workflows/update-flake-lock.yml` — 毎月 1 日に `flake.lock` 更新 PR を自動生成

## Notes

- 対象 OS: macOS (Apple Silicon 専用)
- 言語: 日本語環境
- nixpkgs channel: `nixpkgs-25.11-darwin` (stable)
- 詳細: `docs/nix-adoption-report.md`（導入レポート Step 1–7） /
  `docs/nix-bestpractice-followup.md`（監査フォローアップ Phase 6–16） /
  `docs/brew-triage.md`（formula 仕分け表） /
  `docs/sops-migration.md`（sops-nix 移行手順）
