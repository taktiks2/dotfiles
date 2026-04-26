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

完全宣言化された 6 層構造（Phase 6–16 で post-config を最小化済）:

```
┌────────────────────────────────────────────────────────────────┐
│ Nix (home-manager)        CLI 33 + Fish 4.x + plugins + tmux   │
│   /etc/profiles/per-user/taktiks2/bin/                         │
├────────────────────────────────────────────────────────────────┤
│ Homebrew (nix-darwin で宣言)  formula 24 + cask 13 + tap 12    │
│   /opt/homebrew/  (cleanup="uninstall" で git に完全同期)      │
├────────────────────────────────────────────────────────────────┤
│ macOS system.defaults     Dock / Finder / Trackpad 等          │
├────────────────────────────────────────────────────────────────┤
│ xdg.configFile            ~/.config/<tool> を mkOutOfStoreSymlink │
│                           で dotfiles repo に live link        │
├────────────────────────────────────────────────────────────────┤
│ sops-nix                  AGE 暗号化 secrets/secrets.yaml を    │
│                           ~/.config/sops-nix/secrets/ に復号    │
├────────────────────────────────────────────────────────────────┤
│ direnv + nix-direnv       プロジェクト単位の devShell 自動有効化 │
└────────────────────────────────────────────────────────────────┘
```

`install.sh` (190 行) の役割は最小 orchestration のみ:
1. macOS / Apple Silicon / Xcode CLT チェック → 2. Homebrew 本体投入 →
3. Determinate Nix install + 初回 `darwin-rebuild switch` → 4. fish chsh →
5. Nix 管理境界外の npm global (claude / ccstatusline / ccusage / diffity)。

## 📦 管理される内容

### Nix (home-manager) — CLI 33 本 + Fish

検索/ファイル: ripgrep, fd, fzf, bat, lsd, tree, broot, fswatch, joshuto
Git/開発: gh, delta, git-filter-repo, lazygit, lazydocker, cocogitto, tbls
エディタ/マルチプレクサ: neovim, tmux
JSON/テキスト: jq, gnused
ネットワーク/シェル: wget, bash, bats, fish 4.2 (system 由来)
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

### xdg.configFile + home.activation

- `xdg.configFile.<name>.source = mkOutOfStoreSymlink` で `~/.config/{nvim, git, alacritty, atac, btop, ccstatusline, cspell, gh-dash, ghostty, mcphub, workmux}` の 11 ディレクトリを live link（`darwin-rebuild` 不要で編集即反映）
- `home.file."Library/Application Support/lazygit/config.yml"` で lazygit のみ別管理
- `home.activation.bootstrapSideEffects`: `~/.config/fish/secret-env.fish` のテンプレ生成のみ（最小化済、sops-nix 移行完了後は削除予定）

### secrets (sops-nix)

- `.sops.yaml` で AGE 公開鍵を宣言、`secrets/secrets.yaml` を AGE 暗号化のうえ git tracked
- AGE 秘密鍵は `~/Library/Application Support/sops/age/keys.txt`（Mic92/sops-nix README 推奨パス）
- 起動時に `programs.fish.interactiveShellInit` が `~/.config/sops-nix/secrets/<KEY>` を環境変数へ展開
- 旧 `secret-env.fish` との併用フェーズ（移行手順は `docs/sops-migration.md`）

### Nix 管理境界外 (install.sh の post-config)

- npm global 4 本（`claude` / `ccstatusline` / `ccusage` / `diffity`）— upstream の更新が頻繁なため意図的に npm 直管理
- `nodebrew` 最小 bootstrap（上記 npm 用の土台。本格的な Node 利用は `templates/node` devShell）
- `fish` の chsh
- Neovim プラグインの初回展開は手動（`nvim +Lazy +qa`）

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
│   ├── default/                  # 汎用 devShell (`nix flake init -t ~/dotfiles`)
│   ├── laravel/                  # PHP 8.4 + Composer (MySQL は brew 側で常駐)
│   ├── node/                     # Node.js 22 + corepack
│   ├── ruby/                     # Ruby 3.3 + bundler
│   └── claude-project/           # 新規プロジェクト Claude Code セットアップ雛形 (cp -r 用)
├── .config/
│   ├── nvim/                     # Neovim (LazyVim) 設定
│   ├── alacritty/                # Alacritty 設定
│   ├── ghostty/                  # Ghostty 設定
│   ├── git/                      # Git 設定
│   ├── atac/                     # ATAC (API クライアント) 設定
│   ├── ccstatusline/             # Claude Code statusline 設定
│   ├── btop/  cspell/  gh-dash/  mcphub/  workmux/
│   ├── (fish は programs.fish 直管理。dotfiles repo の .config/fish/ は不要)
│   └── (tmux も programs.tmux 直管理。.config/tmux/ は Phase 8 で撤廃済)
├── secrets/
│   └── secrets.yaml              # AGE 暗号化 (sops-nix 管理)
├── .sops.yaml                    # sops creation_rules
├── config.yml                    # Lazygit 設定 (~/Library/Application Support/lazygit/ に symlink)
├── install.sh                    # Nix bootstrap + post-config orchestration (190 行)
├── .github/workflows/
│   ├── nix-check.yml             # CI: flake-checker + nix flake check + darwin build
│   └── update-flake-lock.yml     # 月次 flake.lock 自動更新 PR
└── docs/
    ├── nix-adoption-report.md    # Nix 導入レポート (Step 1〜7)
    ├── nix-bestpractice-followup.md # 監査フォローアップ実装レポート (Phase 6–16)
    ├── brew-triage.md            # brew formula 仕分け表
    └── sops-migration.md         # sops-nix 移行手順
```

秘匿情報の二系統:

- **推奨**: `secrets/secrets.yaml` を sops-nix で AGE 暗号化、git tracked。AGE 鍵だけ別端末配布（`docs/sops-migration.md`）
- **互換維持**: `~/.config/fish/secret-env.fish`（dotfiles repo 外、`bootstrapSideEffects` がテンプレ生成。sops 移行完了後は削除予定）

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

### 秘匿情報の管理（sops-nix 推奨）

```bash
# 初回セットアップ
mkdir -p "$HOME/Library/Application Support/sops/age"
nix run nixpkgs#age -- -k > "$HOME/Library/Application Support/sops/age/keys.txt"
chmod 600 "$HOME/Library/Application Support/sops/age/keys.txt"
nix run nixpkgs#age -- -y "$HOME/Library/Application Support/sops/age/keys.txt"
# → 出力された公開鍵を .sops.yaml の AGE_PUBLIC_KEY_PLACEHOLDER に置換

# secrets を編集
nix run nixpkgs#sops -- secrets/secrets.yaml

# home/taktiks2.nix の sops.secrets に各 KEY を列挙して switch
```

詳細手順は `docs/sops-migration.md`。

### 新規プロジェクトの devShell

```bash
mkdir my-project && cd my-project

# 言語別テンプレートから投入
nix flake init -t ~/dotfiles            # 汎用
nix flake init -t ~/dotfiles#laravel    # PHP 8.4 + Composer
nix flake init -t ~/dotfiles#node       # Node.js 22
nix flake init -t ~/dotfiles#ruby       # Ruby 3.3

direnv allow                            # 以後 cd で自動有効化
```

### 新規プロジェクトの Claude Code セットアップ

```bash
cd my-project
cp -r ~/dotfiles/templates/claude-project/. .
$EDITOR CLAUDE.md                 # プロジェクト説明・スタック・規約を埋める
$EDITOR .mcp.json                 # 不要な MCP サーバーは削除、必要なものを追加
```

`templates/claude-project/` には CLAUDE.md スケルトン、`.mcp.json` (context7 / playwright)、
`.claude/{settings.json, agents/code-reviewer.md, skills/project-plan/SKILL.md}`、`.gitignore` が同梱されています。

### 月次メンテ

```bash
cd ~/dotfiles
nix flake update                                  # 全 input を最新化
sudo darwin-rebuild switch --flake .#MacBook-Air  # 適用
```

## 📘 Nix 運用ガイド（実践編）

dotfiles 全体は **「git に宣言されていなければ、存在しないのと同じ」** で運用します。
新しいツール / 設定 / 環境変数を足すときは必ず **宣言 → 検証 → 切替** の順を踏み、`darwin-rebuild --rollback` でいつでも前世代に戻せる状態を保ちます。

### 1. どこに何を書くか早見表

| やりたいこと | 編集する場所 | 代表例 |
|---|---|---|
| CLI を入れる（Nix 化が第一選択） | `home/taktiks2.nix` の `home.packages` | ripgrep, fd, jq, neovim |
| CLI を入れる（重量 / 商用 / cache 弱） | `modules/homebrew.nix` の `brews` | mysql, docker, azure-cli |
| GUI を入れる | `modules/homebrew.nix` の `casks` | ghostty, warp, vscode |
| ツールが `programs.<tool>` を持つ | `home/taktiks2.nix` の `programs.<tool>` | fish, tmux, direnv |
| 任意の dotfile を `~/.config/<name>` に置きたい | `.config/<name>/` を repo に置く + `xdg.configFile.<name> = link "<name>"` | nvim, btop, ghostty |
| `~/.config` 外のパスに置きたい | `home.file."<path>".source` | `Library/Application Support/lazygit/` |
| 環境変数 | `home.sessionVariables` | `JAVA_HOME`, `LANG` |
| PATH 追加 | `home.sessionPath` | `~/.cargo/bin` |
| fish エイリアス / 関数 | `programs.fish.shellAliases` / `.functions` | `lg = "lazygit"` |
| macOS の defaults | `modules/macos-defaults.nix` | Dock 自動隠し |
| 新しい言語の devShell | `templates/<name>/` + `flake.nix` の `templates` | `templates/python/` |
| 新ホスト | `flake.nix` の `darwinConfigurations` に `mkDarwin {...}` を 1 行 + `hosts/<name>/default.nix` | MacBook-Pro |

### 2. 新しい設定ファイル（`~/.config/<tool>`）を足す

最も頻度の高いオペレーション。原則 `programs.<tool>` で書ければそちら優先（バリデーション可・純宣言）、対応してなければ **`mkOutOfStoreSymlink` で live link** します。

#### 手順（例: `~/.config/zellij/` を新規追加）

```bash
# 1. dotfiles repo にディレクトリと初期 config を作る
mkdir -p ~/dotfiles/.config/zellij
$EDITOR ~/dotfiles/.config/zellij/config.kdl
```

```nix
# 2. home/taktiks2.nix:140 付近の xdg.configFile に 1 行追加
xdg.configFile = let
  configRoot = "${dotfilesRoot}/.config";
  link = name: { source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/${name}"; };
in {
  alacritty    = link "alacritty";
  # ... 既存
  workmux      = link "workmux";
  zellij       = link "zellij";   # ← 追加
};
```

```bash
# 3. ドライビルド → 切替
cd ~/dotfiles
sudo darwin-rebuild build  --flake .#MacBook-Air   # 評価＋ビルドのみ（切替なし）
sudo darwin-rebuild switch --flake .#MacBook-Air   # 適用

# 4. symlink を確認
ls -la ~/.config/zellij
# → ~/dotfiles/.config/zellij への symlink になっていれば OK
```

以後 `~/dotfiles/.config/zellij/` を直接編集すると `darwin-rebuild` 不要で即反映されます（`mkOutOfStoreSymlink` の live link 性質）。**Pure な再現性が欲しいときだけ** `source = ./.config/<name>` に書き換えると nix store にコピーされます（編集ごとに rebuild 必須）。

#### 既に `~/.config/<name>` がある場合

home-manager は実体ファイル / 別 symlink を `~/.config/<name>.hm-backup` に退避してから新規 symlink を貼ります。switch 後に `find ~/.config -name '*.hm-backup'` で確認し、必要なら repo へ移植してから削除してください。

#### `~/.config` の外（例: `Library/Application Support/...`）

`home.file` を直接使います（既存例: lazygit）:

```nix
home.file."Library/Application Support/lazygit/config.yml".source =
  config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/config.yml";
```

#### `programs.<tool>` と `xdg.configFile` の使い分け

| 観点 | `xdg.configFile` (live link) | `programs.<tool>` (HM 生成) |
|---|---|---|
| 編集即反映 | ⭕ rebuild 不要 | ❌ rebuild 必須 |
| バリデーション | ❌ typo は実行時に判明 | ⭕ `nix flake check` で検出 |
| 設定 DSL | そのツール本来の DSL（Lua / KDL / TOML…） | Nix で書く |
| 推奨対象 | DSL 編集が頻繁なもの（nvim / ghostty / btop） | 枯れた設定（fish / tmux / git） |

本リポジトリは **fish / tmux** は `programs.*`、**nvim / btop / ghostty 等の 11 個** は live link というハイブリッド戦略。

### 3. 検証 → 適用 → ロールバック

```bash
cd ~/dotfiles

# ① 評価 lint（option typo / 未定義参照を検出）
nix flake check

# ② ドライビルド（store には作るが /run/current-system は変えない）
sudo darwin-rebuild build --flake .#MacBook-Air

# ③ 次世代と現行の closure 差分を見る（何が増減するか可視化）
nix store diff-closures /run/current-system ./result

# ④ 適用
sudo darwin-rebuild switch --flake .#MacBook-Air

# ⑤ 失敗 / 違和感があれば即ロールバック
sudo darwin-rebuild --rollback                 # 直前の世代へ
sudo darwin-rebuild --list-generations         # 世代一覧
sudo darwin-rebuild --switch-generation 42     # 特定世代へ
```

`./result` は ② を打った直後のディレクトリに作られる symlink。④ の switch 後は不要なので `rm result` で消して OK。

### 4. パッケージ / オプションを探す

```bash
nix search nixpkgs ripgrep        # CLI から
brew search <name>                # Homebrew
```

ブラウザの一次資料:

- [search.nixos.org/packages](https://search.nixos.org/packages?channel=25.11) — nixpkgs パッケージ検索
- [home-manager-options.extranix.com](https://home-manager-options.extranix.com/?release=release-25.11) — `programs.*` オプション一覧
- [nix-darwin manual](https://daiderd.com/nix-darwin/manual/index.html) — `system.defaults.*` / `homebrew.*` / `services.*` 等
- [docs.determinate.systems](https://docs.determinate.systems/) — Determinate Nix の `determinateNix.*` 設定

### 5. unfree パッケージを解禁する

`flake.nix:62-67` の `allowUnfreePredicate` に **パッケージ名** を追記（一括許可ではなく allowlist）:

```nix
nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem (lib.getName pkg) [
    "vscode"
    "claude-code"
  ];
```

### 6. 一時的に overlay でパッケージを書き換える

`flake.nix` の `nixpkgs.overlays` に追記。現状は direnv の test を sandbox 内で skip するためだけに 1 個常駐（[nixpkgs#82606](https://github.com/NixOS/nixpkgs/issues/82606)）。**workaround を入れるときは必ず TODO + 撤去条件をコメントに残す** ルール。

### 7. flake.lock の更新

```bash
nix flake update                  # 全 input を更新
nix flake update nixpkgs          # 単独更新
nix flake update determinate      # Determinate Nix だけ更新
sudo darwin-rebuild switch --flake .#MacBook-Air
```

毎月 1 日に `update-flake-lock.yml` が自動 PR を出すので、CI が緑のままレビューしてマージするのが既定運用です。

### 8. ディスクを掃除する

```bash
# 30 日以上前の世代を削除（system + user profile + nix store の roots）
sudo nix-collect-garbage --delete-older-than 30d

# nix store の現在量
du -sh /nix/store

# darwin の世代一覧
sudo darwin-rebuild --list-generations | tail -20
```

Determinate Nix は `determinateNix.customSettings` で自動 GC スケジュールを宣言できます（[公式](https://docs.determinate.systems/guides/nix-darwin/)）。

### 9. よくある詰まり

| 症状 | 原因 | 対処 |
|---|---|---|
| `~/.config/<name>` が `.hm-backup` に退避された | 既存実体と新規 symlink の競合 | 必要な内容を repo に取り込み、`*.hm-backup` を削除 |
| `darwin-rebuild switch` が TCC エラーで落ちる | macOS Sequoia + HM の既知 issue ([nix-community/home-manager#8336](https://github.com/nix-community/home-manager/issues/8336)) | Settings → Privacy & Security → App Management でターミナルを許可 |
| fish が `Killed: 9` で起動しない | fish 4.2 の codesign 問題 | `hosts/MacBook-Air/default.nix` の `postActivation` で自動 ad-hoc 再署名済（手動対応不要） |
| `nix flake check` で direnv が失敗 | macOS sandbox 内で fish/zsh test SIGKILL | `flake.nix` の `doCheck = false` overlay で回避済 |
| switch 後に新しい CLI が PATH に出ない | 既存シェルが古い PATH を保持 | `exec fish` か新規ターミナルを開く |
| `error: experimental Nix feature 'flakes' is disabled` | Determinate 以外の Nix が混入 | Determinate Nix で再インストール（`install.sh` 参照） |
| `homebrew` モジュールが意図せず uninstall した | `cleanup = "uninstall"` で `brews` から外したものを刈り取った | 戻したいなら `modules/homebrew.nix` に再宣言、または依存関係に組み込む |

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
mkdir my-project && cd my-project
nix flake init -t ~/dotfiles#laravel   # PHP 8.4 + Composer devShell
direnv allow
brew services start mysql@8.0          # MySQL は brew で常駐管理
composer create-project laravel/laravel .
php artisan serve
```

`templates/laravel` には `pkgs.php84 / php84Packages.composer` が同梱され、
`direnv allow` するとプロジェクト固有の PATH に切り替わります（MySQL は dotfiles 全体で
共通の `brew services start mysql@8.0` を使う構成）。

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

### xdg.configFile activation の競合

既存の `~/.config/<name>` が同ターゲットへの symlink でない場合、HM が `*.hm-backup` で退避してから新規 symlink を貼ります。`hm-backup` ファイルが残ったら内容を確認のうえ削除してください。

### CI（GitHub Actions）

- `nix-check.yml`: push / PR ごとに `flake-checker` → `nix flake check` → `darwin-rebuild build` を macos-14 ランナーで実行
- `update-flake-lock.yml`: 毎月 1 日に `flake.lock` を更新する PR を自動生成（生成された PR で `nix-check.yml` が再実行されるため、ビルドが通った状態でレビュー可能）

## 📚 詳細ドキュメント

- [docs/nix-adoption-report.md](./docs/nix-adoption-report.md) — Nix 導入レポート（Step 1〜7）
- [docs/nix-bestpractice-followup.md](./docs/nix-bestpractice-followup.md) — 監査フォローアップ実装レポート（Phase 6–16）
- [docs/brew-triage.md](./docs/brew-triage.md) — brew formula 仕分け表
- [docs/sops-migration.md](./docs/sops-migration.md) — sops-nix 移行手順
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
