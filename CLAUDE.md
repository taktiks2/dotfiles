# CLAUDE.md

このファイルは Claude Code (claude.ai/code) がこのリポジトリを操作する際のガイドです。
ユーザー向けの全体像は `README.md` を参照してください。

## Repository Overview

macOS (Apple Silicon) 用の個人 dotfiles。
**Nix (flake + nix-darwin + home-manager + Determinate Nix)** で
開発環境を宣言的に管理しています。`darwin-rebuild switch` 一発で
CLI / Homebrew / macOS defaults / `~/.config/*` の symlink まで全て同期されます。

## Architecture

完全宣言化された 6 層構造:

| レイヤ | 実体 | 場所 |
|---|---|---|
| Nix (home-manager) | CLI バンドル + Fish 4.x + plugins + tmux | `home/common.nix` (+ `home/hosts/<hostname>.nix`) |
| Homebrew (nix-darwin で宣言) | 共通 brew/cask/tap + host 固有上書き | `modules/homebrew/{default,local}.nix` |
| macOS `system.defaults` | Dock / Finder / Trackpad / NSGlobalDomain 等 | `modules/macos-defaults.nix` |
| `xdg.configFile` (live link) | `~/.config/<tool>` → dotfiles repo を `mkOutOfStoreSymlink` | `home/common.nix` |
| sops-nix | AGE 暗号化 `secrets/secrets.yaml` を `~/.config/sops-nix/secrets/` に復号 | `home/common.nix` の `sops` |
| direnv + nix-direnv | プロジェクト単位 devShell の自動有効化 | `templates/` |

### 主要ファイル

```
flake.nix                       # inputs / mkDarwin factory (extraModules / homeExtraModules で per-host 差分注入可) / devShell templates
hosts/common.nix                # 全ホスト共通: networking / system.primaryUser / programs.fish / fish 再署名 activation
home/common.nix                 # home-manager 共通 baseline: home.packages / programs.{fish,tmux,direnv} / xdg.configFile / sops / activation
home/hosts/<hostname>.nix      # ホスト固有差分 (auto-import, 任意): JAVA_HOME 等の install-specific 値
home/programs/                  # per-tool 設定: fish / git / tmux / direnv / lazygit / btop / gh-dash / terminal / cli
modules/homebrew/default.nix    # 全 PC 共通 taps / brews / casks (cleanup = "uninstall")
modules/homebrew/local.nix      # ホスト固有 (git tracked + skip-worktree、upstream は空 stub)
modules/macos-defaults.nix      # system.defaults.* (ACTIVE / OPT-IN)
templates/                      # nix flake init -t 用 devShell (default / laravel / node / ruby / rust / go / claude-project)
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
./install.sh private          # ホスト名は flake.nix の darwinConfigurations attribute と一致させる
```

新ホスト追加手順は `README.md` の「新しい Mac に導入する」を参照。

`install.sh` は **薄い orchestration** に集約:

1. macOS / Apple Silicon / Xcode CLT チェック
2. Homebrew 本体投入（nix-darwin の homebrew モジュールが `/opt/homebrew` を参照）
3. Determinate Nix install + 初回 `darwin-rebuild switch`
4. fish の chsh
5. Nix 管理境界外の最小 bootstrap (fnm 経由 Node LTS + npm global 4 本: `claude` / `ccstatusline` / `ccusage` / `diffity`)

## Daily Operations

| 何を | 編集ファイル | 適用 |
|---|---|---|
| Nix CLI | `home/common.nix` の `home.packages` (そのホストだけなら `home/hosts/<hostname>.nix`) | `sudo darwin-rebuild switch --flake ~/dotfiles#private` |
| brew formula / cask（共通） | `modules/homebrew/default.nix` の `brews` / `casks` / `taps` | 同上 |
| brew formula / cask（ホスト固有） | `modules/homebrew/local.nix`（git tracked + skip-worktree でローカル変更非追跡） | 同上 |
| macOS 設定 | `modules/macos-defaults.nix` | 同上 |
| Fish 設定 | `home/programs/fish.nix` の `programs.fish.{shellInit, interactiveShellInit, shellAliases, plugins}` (ホスト固有 alias は `home/hosts/<hostname>.nix`) | 同上 |
| tmux 設定 | `home/programs/tmux.nix` の `programs.tmux.*` | 同上 |
| 月次更新 | `nix flake update` → `darwin-rebuild switch` | — |

`modules/homebrew/local.nix` は upstream に空 stub が commit されており、`install.sh` が `git update-index --skip-worktree` を冪等にセットすることで各マシンのローカル編集を `git status` / `git diff` から隠蔽する（push されない）。skip-worktree が外れた場合は `./install.sh` 再実行で復元される。Nix の flake eval は git tracked ファイルしか読まないため、gitignore + 通常運用では成立しない（`--impure` で絶対パス参照する代替案より、skip-worktree のほうが pure-mode を保てて再現性が良い）。

### 直接編集してはいけないファイル

- `~/.config/fish/config.fish` — home-manager 生成 symlink。`home/programs/fish.nix` の `programs.fish` セクションを編集
- `~/.config/tmux/tmux.conf` — `programs.tmux` から生成される
- `/etc/profiles/per-user/taktiks2/bin/*` — Nix store の symlink

## Secrets

二系統:

- **推奨**: `secrets/secrets.yaml` を sops-nix で AGE 暗号化、git tracked。
  AGE 鍵は `~/Library/Application Support/sops/age/keys.txt`
  （Mic92/sops-nix README 推奨パス）。
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
nix flake init -t ~/dotfiles#rust       # Rust + rust-overlay (rust-toolchain.toml 尊重)
nix flake init -t ~/dotfiles#go         # Go + gopls/delve/golangci-lint

direnv allow                            # 以後 cd で自動有効化
```

`templates/claude-project/` は `cp -r` 用の Claude Code スケルトン
（CLAUDE.md / .mcp.json / .claude/{settings.json, agents/code-reviewer.md, skills/project-plan/SKILL.md} / .gitignore 同梱）。

## Common Aliases

`home/programs/fish.nix` の `programs.fish.shellAliases`:

```fish
vim, vi, v   → nvim
ghd          → gh dash
lg           → lazygit
ls, la, ll   → lsd, lsd -a, lsd -al
sls          → sbcl --load ~/.local/share/nvim/lazy/nvlime/lisp/start-nvlime.lisp
wm           → workmux
```

## Troubleshooting

- 緊急ロールバック: `sudo darwin-rebuild --rollback`
- インストールログ: `~/.dotfiles_install_logs/install_*.log`
- `~/.config/<name>` が既に別 symlink/実体だと HM が `*.hm-backup` で退避（要手動確認）
- fish 4.2.x の SIGKILL 問題は `hosts/common.nix` の
  `system.activationScripts.postActivation` で ad-hoc 再署名済（自動）

## Notes

- 対象 OS: macOS (Apple Silicon 専用)
- 言語: 日本語環境
- nixpkgs channel: `nixpkgs-unstable`
