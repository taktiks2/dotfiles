# Nix 導入レポート — taktiks2/dotfiles

**作成日:** 2026-04-25
**対象機:** MacBook Air (Apple Silicon, macOS 26.3.1)
**対象リポジトリ:** `~/dotfiles`
**目的:** 既存の Homebrew + `install.sh` ベース構成に Nix を統合し、宣言的・再現可能な開発環境管理へ段階移行する。

---

## 1. エグゼクティブサマリー

- **dotfiles で Nix を管理するのは 2026 年時点のベストプラクティス**。ただし「全部 Nix 化」は罠。aarch64-darwin のビルド事情と GUI アプリの事情から、**Nix / Homebrew / 手動の三層併用**が現実解。
- 本機は **Nix インストール済（Determinate Systems installer 経由）**・Homebrew は formula 206 + cask 13 という規模。**ゼロから入れる段階は終了済**で、次は「dotfiles に統合し `install.sh` を段階的に縮小する」フェーズ。
- 推奨スタックは **flakes + nix-darwin + home-manager + nix-homebrew**。
- 移行は 7 ステップに分割し、**PHP / MySQL / 既存 .config 中身は当面さわらない**ことでリスクを抑える。

---

## 2. 現状調査結果

| 項目 | 状態 |
|---|---|
| OS | macOS 26.3.1 (Darwin 25.3.0, arm64) |
| Shell | `/bin/zsh`（Fish はログインシェル外で運用） |
| Nix | **インストール済** (`/nix/var/nix/profiles/default/bin/nix`、Determinate `nix-installer` の `receipt.json` あり) |
| Homebrew | 5.1.7 / formula **206本** / cask **13本** |
| dotfiles 規模 | `install.sh` 588 行、`.config/` に 20+ ツール設定 |
| 主要言語環境 | PHP/Composer/Laravel, MySQL 8.0, Node (nodebrew), Ruby (rbenv), Rust (rustup), Common Lisp |

---

## 3. Nix エコシステム最新動向 (2026 早期)

### インストーラ
- **Determinate Nix Installer**: 2026 早期から **Determinate Nix（独自ディストリ）専用**になった。upstream CppNix を入れるには `--determinate=false` か **公式 installer (`nix.dev`)** を使う。
- 本機は Determinate 経由で導入済 → **そのまま継続推奨**（macOS アップグレード耐性が最も高い）。

### 主要コンポーネント
- **nix-darwin**: `LnL7` 個人 repo から **`nix-darwin/nix-darwin` org** に移管され、複数メンテナ体制 + nixpkgs リリース連動の安定ブランチ（例 `nix-darwin-25.11`）あり。
- **home-manager**: `nix-community` 配下で活発。**nix-darwin モジュールとして組み込む**のが標準（standalone CLI は非 darwin 用）。
- **Flakes**: 上流仕様上はまだ `experimental-features` フラグ付きだが、**事実上の標準**。Determinate Nix では既定で有効。

### 周辺
- **Lix**: CppNix 2.18 ベースのフォーク。コミュニティ伸長中だが **macOS dotfiles のブートストラップに 2026 時点で選ぶ強い理由はない**。
- **flake-parts (hercules-ci)**: flake の構造化ヘルパとして主流。Snowfall Lib も健在だが規模は小さめ。
- **nix-homebrew (zhaofengli)**: nix-darwin から Homebrew を宣言的にブートストラップする標準的な選択肢。

### 出典
- https://github.com/DeterminateSystems/nix-installer
- https://determinate.systems/blog/installer-dropping-upstream/
- https://github.com/nix-darwin/nix-darwin
- https://nix-community.github.io/home-manager/
- https://wiki.nixos.org/wiki/Flakes
- https://github.com/zhaofengli/nix-homebrew
- https://lix.systems/

---

## 4. 推奨アーキテクチャ

### リポジトリ構成

```
dotfiles/
├── flake.nix              # inputs: nixpkgs, nix-darwin, home-manager, nix-homebrew
├── flake.lock
├── hosts/
│   └── MacBook-Air/
│       └── default.nix    # nix-darwin: system.defaults / homebrew.casks / services
├── home/
│   └── taktiks2.nix       # home-manager: CLIパッケージ + xdg.configFile symlink
├── modules/               # 共通モジュール（必要時）
├── overlays/              # 必要時
└── .config/               # 既存ファイル群（中身は触らずsymlinkで配布）
```

切替コマンド: `darwin-rebuild switch --flake .#MacBook-Air`

### 設計原則
- **`.config/*` の中身は Nix DSL に書き直さない**。home-manager の `xdg.configFile."nvim".source = ./.config/nvim;` で symlink するだけ。
- ホストごとの設定は `hosts/<hostname>/`、ユーザごとは `home/<user>.nix`。将来 2 台目を導入しても拡張可能。
- flake input は最小限から。`flake-parts` は規模が増えてから検討。

---

## 5. 役割分担マトリクス

| 領域 | 担当 | 理由 |
|---|---|---|
| CLI ツール (ripgrep, lsd, fd, fzf, gh, gh-dash, lazygit, delta, tmux, jq, btop, bat, neovim) | **Nix (home-manager)** | aarch64-darwin で即座に動く・宣言的管理の最大効用 |
| GUI cask 13本 (Alacritty, Ghostty, Chrome, Slack, Docker Desktop 等) | **nix-darwin + nix-homebrew** | 宣言的に保ちつつ署名・自動更新は brew に委譲 |
| macOS システム設定 (Dock, Finder, キーリピート, 入力ソース) | **`system.defaults.*`** | Nix の最大の勝ち筋。GUI 手動設定が消える |
| **PHP / Composer / Laravel** | **Homebrew のまま** | aarch64-darwin で PHP 拡張のローカルビルドが極めて高コスト |
| **MySQL 8.0** | **`brew services` のまま** | nix-darwin `services.mysql` は動くが macOS では事故率高 |
| Rust / Node / Ruby のグローバル | 当面据え置き、新規プロジェクトは **devShell + direnv (`nix-direnv`)** | rustup / nodebrew / rbenv からの段階脱却 |
| `.config/*` 設定ファイル | home-manager `xdg.configFile` で **symlink** | 二重管理回避 |
| Fish | `programs.fish` で plugin だけ宣言、`config.fish` は `source` | 既存資産そのまま活用 |
| Fonts | nixpkgs `nerd-fonts.*` (home-manager) | aarch64-darwin で動作良好 |

### Apple Silicon 上の注意
- 一部パッケージは aarch64-darwin バイナリキャッシュが薄く、ローカルビルドで時間を消費（PHP 拡張、古い Python wheel、旧 XCode SDK 依存物など）。
- **Determinate Cache** または `cachix` を有効化すると緩和される。

---

## 6. 段階的移行プラン

| Step | 内容 | 状態 | `install.sh` への影響 |
|---|---|---|---|
| 0 | Nix インストール (Determinate) | ✅ 完了 | — |
| 1 | flake 雛形 + nix-darwin + home-manager + nix-homebrew を最小構成で起動。CLI 3 ツール程度で `darwin-rebuild switch` 成功を検証 | 未着手 | 変更なし |
| 2 | CLI ツール群（formula 約 60〜80 本）を home-manager に移行 | 未着手 | brew install 該当行を削除 |
| 3 | `system.defaults.*` で macOS 設定を宣言化 | 未着手 | 新規の勝ち（手動 GUI 設定が消える） |
| 4 | cask 13 本を `nix-darwin.homebrew.casks` に移管（`nix-homebrew` で brew 自体も宣言的に） | 未着手 | brew install --cask 行を削除 |
| 5 | `.config/*` の symlink ロジックを home-manager に移譲 | 未着手 | symlink セクション削除 |
| 6 | 新規プロジェクトから **devShell + nix-direnv** を採用 | 未着手 | rustup / nodebrew / rbenv は共存維持 |
| 7 | 余剰の brew formula 棚卸し → 不要なものを削除 | 未着手 | brew のサイズが大幅減 |

**最終形:** `install.sh` は「**Nix 入れる → repo clone → `darwin-rebuild switch`**」に縮小。PHP / MySQL の brew ブートストラップだけ残す。

### 当面さわらない方針（重要）
- PHP / Composer / Laravel
- MySQL 8.0
- rbenv 管理の Ruby
- 動いている `.config/*` の中身そのもの

---

## 7. リスクと緩和策

| リスク | 緩和策 |
|---|---|
| `darwin-rebuild switch` 失敗で環境が壊れる | nix-darwin は **世代管理**あり。`darwin-rebuild --rollback` で即時戻せる |
| brew と Nix で同名コマンドが衝突 | PATH 順序を nix-darwin で明示。重複を発見次第 brew 側を削除 |
| aarch64-darwin で長時間ビルド | Determinate Cache / cachix を併用。問題パッケージは brew に残す |
| flake input のバージョン乖離 | `flake.lock` を git 管理。`nix flake update` は意図的に運用 |
| 既存 `.config/*` を Nix DSL に書き直して破綻 | **書き直さない**。symlink 方式を厳守 |

---

## 8. 期待される効果

- macOS 再セットアップ時間が **数時間 → 数分**（ビルド済キャッシュ前提）
- システム設定（Dock / Finder / キーボード等）の **GUI 手動操作ゼロ化**
- ツールバージョンの **ホスト間完全一致**（将来 2 台目導入時に効く）
- `install.sh` の保守コスト **大幅低下**（588 行 → 100 行未満が射程）
- プロジェクトごとの開発環境を **devShell** で分離し、グローバル汚染を解消

---

## 9. 次アクション

**Step 1（flake 雛形作成）から着手することを推奨。**

- 最小構成: `flake.nix` + `hosts/MacBook-Air/default.nix` + `home/taktiks2.nix`
- 試験対象: `ripgrep`, `lsd`, `jq` の 3 つだけを home-manager 経由で導入
- 既存 brew・`.config`・`install.sh` には一切手を加えない
- `darwin-rebuild switch --flake .#MacBook-Air` の成功を確認した時点で commit

任意で先に **「formula 206 本の仕分けリスト」**（Nix 行き / brew 残留 の分類）を作成すると、Step 2 以降の手戻りを最小化できる。

---

## 10. 実施履歴

### Step 1: flake 雛形 + 最小ブートストラップ（2026-04-25 完了）

#### 作成ファイル
| ファイル | 行数 | 役割 |
|---|---|---|
| `flake.nix` | 36 | inputs (nixpkgs unstable / nix-darwin / home-manager) と `darwinConfigurations.MacBook-Air` |
| `flake.lock` | 自動 | nixpkgs 2026-04-23, nix-darwin 2026-04-01, home-manager 2026-04-25 |
| `hosts/MacBook-Air/default.nix` | 29 | nix-darwin システムモジュール |
| `home/taktiks2.nix` | 16 | home-manager ユーザモジュール（CLIツール3本） |

#### 実施内容
1. `flake.nix` で aarch64-darwin / `darwinConfigurations.MacBook-Air` を定義
2. ホスト側で **Determinate Nix と共存**するため `nix.enable = false` を設定
3. `system.primaryUser = "taktiks2"` および `users.users.taktiks2.home = "/Users/taktiks2"` を宣言
4. home-manager を nix-darwin モジュールとして組み込み（`useGlobalPkgs / useUserPackages = true`）
5. 試験パッケージ `ripgrep / lsd / jq` の 3 本のみ追加
6. `nix flake check` パス → `nix build` 成功
7. `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#MacBook-Air` でブートストラップ
8. home-manager 修復のため `sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/dotfiles#MacBook-Air` を再実行

#### ハマりどころと対処
| 現象 | 原因 | 対処 |
|---|---|---|
| `home.homeDirectory` が `null` でビルド失敗 | nix-darwin の `users.users.<name>.home` 未定義 | ホスト側に `users.users.taktiks2 = { name; home; }` を追加し、home-manager 側からは `home.homeDirectory` 指定を削除 |
| `~/.nix-profile` が dangling symlink | `useUserPackages = true` ではパッケージは `/etc/profiles/per-user/<user>/bin/` に配置される（仕様）。`~/.nix-profile` リンクは無害な遺物 | 無視可。実体は `/etc/profiles/per-user/taktiks2/bin/` |
| `sudo nix run` 起動時に `$HOME ('/Users/taktiks2') is not owned by you` 警告 | sudo が HOME 環境変数を保持しつつ Nix 内部で root 文脈と衝突 | `darwin-rebuild` 単体（`sudo /run/current-system/sw/bin/darwin-rebuild switch ...`）で再実行すれば解消 |
| 一見 brew 版が引かれる | 既存シェルセッションが switch 前から起動されており PATH 未更新 | 新シェル起動 or Step 2 の Fish PATH 統合で恒久解決 |

#### 検証結果
- `/run/current-system` → 新システムを指す
- `/etc/profiles/per-user/taktiks2/bin/{rg, lsd, jq}` → Nix 版確認（`rg 15.1.0` vs brew `14.1.0`）
- `darwin-rebuild` コマンド利用可能（`/run/current-system/sw/bin/`）
- 既存 brew / `.config/*` / `install.sh` への副作用なし

---

### Step 2: Fish PATH 統合 + brew 31本の Nix 移行（2026-04-25 完了）

#### Step 2a: Fish PATH 統合
- 編集: `.config/fish/config.fish` 末尾に Nix 経路の**再プリペンド**ブロックを追加
  ```fish
  for nix_path in /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin
      if test -d $nix_path; and not contains $nix_path $PATH
          set -gx PATH $nix_path $PATH
      end
  end
  ```
- 既存の `set PATH /opt/homebrew/bin $PATH` 等の後に追加することで、Nix が brew より優先される
- 検証: 新 Fish セッションで `which rg/lsd/jq/darwin-rebuild` が Nix 版を返す

#### Step 2b: brew leaves 仕分け
- 作成: `docs/brew-triage.md`
- `brew leaves` の **57 本**を `MOVE / KEEP / LATER` に三分類
- MOVE: 31 本（純粋 CLI、aarch64-darwin キャッシュ確度高）
- KEEP: 言語ランタイム・DB サービス・第三者 tap・ベンダー CLI など 22 本
- LATER: `tbls / joshuto / clisp / fisher` の 4 本

#### Step 2c: home/taktiks2.nix 拡張（3本 → 31本）

カテゴリ別追加：

| カテゴリ | パッケージ |
|---|---|
| 検索 / ファイル | `ripgrep, fd, fzf, bat, lsd, tree, broot, fswatch` |
| Git / 開発フロー | `gh, delta, git-filter-repo, lazygit, lazydocker, cocogitto` |
| エディタ / マルチプレクサ | `neovim, tmux` |
| JSON / テキスト | `jq, gnused` |
| ネットワーク / シェル | `wget, bash, bats` |
| ビジュアル / システム | `btop, graphviz, television` |
| 言語ランタイム / ビルド | `zig, deno, uv, sbcl, cargo-binstall` |
| AI / その他 | `aichat, just` |

#### Step 2d: 適用と検証
- `nix build` 成功（全パッケージがバイナリキャッシュからフェッチ、ローカルビルドゼロ）
- `sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/dotfiles#MacBook-Air` 適用
- 31/31 本が `/etc/profiles/per-user/taktiks2/bin/` で解決を確認

#### 注意事項
1. **`sed` が GNU sed に置換**される（Nix の `gnused` パッケージが `sed` を直接提供）。BSD 専用フラグ依存スクリプトに注意
2. **`bash`** は `/run/current-system/sw/bin/` 配下に配置（システムレベル）。`#!/bin/bash` シバンは絶対パスのため影響なし
3. **brew 側のパッケージは未削除**。Nix 版安定動作確認後（数日後）に `brew uninstall` 実施推奨
4. パッケージ名 ≠ バイナリ名: `television → tv`, `cocogitto → cog`, `graphviz → dot/neato`, `gnused → sed`

---

### Step 3: macOS システム設定の宣言化（2026-04-25 完了）

#### 作成ファイル
| ファイル | 内容 |
|---|---|
| `modules/macos-defaults.nix` (新規, 119行) | `system.defaults.*` 設定モジュール |
| `hosts/MacBook-Air/default.nix` (更新) | `imports = [ ../../modules/macos-defaults.nix ]` 追加 |

#### 設計方針
- **ACTIVE**: 現状の macOS 設定をそのままコード化 → 適用しても挙動変化なし（非破壊）
- **OPT-IN**: 開発者向けに有効と思われる候補をコメント形式で同梱 → 必要な行のみ uncomment で有効化

#### ACTIVE 項目（現状を Nix に固定）
| ドメイン | キー | 値 |
|---|---|---|
| `dock` | `autohide` | `true` |
| `dock` | `tilesize` | `44` |
| `finder` | `ShowStatusBar` | `true` |
| `finder` | `FXPreferredViewStyle` | `"Nlsv"` (List) |
| `NSGlobalDomain` | `AppleInterfaceStyle` | `"Dark"` |
| `screencapture` | `location` | `"~/Pictures/screenshot"` |
| `trackpad` | `Clicking` | `false` |

#### OPT-IN 候補（コメントアウト形式で同梱）
- Dock: `show-recents`, `mru-spaces`, `minimize-to-application`, `launchanim`
- Finder: `AppleShowAllExtensions`, `FXEnableExtensionChangeWarning`, `ShowPathbar`, `_FXShowPosixPathInTitle`, `AppleShowAllFiles`
- Global: 自動補正系5つ（Capitalization / Period / Dash / Quote / Spelling）、`KeyRepeat = 2`, `InitialKeyRepeat = 15`, `NSDocumentSaveNewDocumentsToCloud`
- Screencapture: `disable-shadow`, `type = "png"`
- Trackpad: `TrackpadThreeFingerDrag`
- Security: `LSQuarantine`, `startup.chime`

#### ハマりどころと対処
| 現象 | 原因 | 対処 |
|---|---|---|
| `system.activationScripts.postUserActivation` がエラー | 新しい nix-darwin で削除済（全アクティベーションが root で行われるよう変更） | カスタムスクリプトを削除。nix-darwin が `activateSettings -u` を自動実行するため不要 |

#### 検証結果
- `darwin-rebuild switch` 中に `user defaults...` / `restarting Dock...` ログを確認
- `defaults read` で全 ACTIVE 項目が宣言通りに反映を確認
- 世代: `system-1 → 2 → 3` と積み上がり、ロールバック可能

---

### Step 4: Homebrew cask の宣言化（2026-04-25 完了）

#### 設計判断
- **`nix-homebrew` は採用見送り**: brew 自体の所有権移管が必要で侵襲度が高い。既存 `/opt/homebrew` を維持する方針。
- nix-darwin 標準の `homebrew` モジュールを利用。`brew bundle` 相当の冪等同期。
- **`onActivation.cleanup = "none"`**: 未宣言パッケージを削除しない（Step 2 で Nix 化したが brew 側に残っている 31 本の誤削除を防止）。
- `autoUpdate = false` / `upgrade = false`: switch のたびに brew 全体を更新しない。

#### 作成ファイル
| ファイル | 内容 |
|---|---|
| `modules/homebrew.nix` (新規, 50行) | nix-darwin `homebrew` モジュール設定 |
| `hosts/MacBook-Air/default.nix` (更新) | imports に追加 |

#### 宣言した cask（13本）
```
arto, bruno, copilot-cli, devtoys, font-hack-nerd-font,
font-hackgen-nerd, ghostty, godot, ngrok, utm,
visual-studio-code, warp, zulu@17
```

#### 宣言した tap（2 つ）
- `arto-app/tap` (arto 配布元)
- `ngrok/ngrok` (ngrok 配布元)
- ※ `homebrew/cask` 標準配下のものは tap 不要

#### 検証結果
- `darwin-rebuild switch` のログに以下を確認:
  ```
  Homebrew bundle...
  Using arto-app/tap / Using ngrok/ngrok
  Using arto / Using bruno / ... / Using zulu@17
  `brew bundle` complete! 15 Brewfile dependencies now installed.
  ```
- 全 13 cask + 2 tap が `Using`（既存を認識、変更なし）= **no-op で宣言完了**
- 副作用: なし

#### 今後の展開
- 新規 cask 追加は `modules/homebrew.nix` に 1 行追加 + switch のみで完結
- `cleanup = "uninstall"` への切替は Step 2 follow-up（brew formula 31本の uninstall）と同時実施予定
- brew formula（KEEP 22 本）の宣言化は Step 4b として後続

---

### Step 4b: brew formula と tap の完全宣言化（2026-04-25 完了）

#### 追加宣言
- **brew formula 27 本**（`docs/brew-triage.md` の KEEP + LATER 全て）
  - 言語ランタイム: composer, luarocks, nodebrew, python@3.10, rbenv
  - DB: mysql, mysql@8.0, postgresql@14
  - 重量ビルド: bundletool, clisp, openapi-generator, qemu
  - ベンダー CLI: azure-cli, docker, fastlane, gemini-cli, supabase
  - Fish: fisher
  - 第三者 tap formula: carlocab/personal/unrar, heroku/brew/heroku, julien-cpsn/atac/atac, osx-cross/avr/avr-gcc@9, qmk/qmk/qmk, raine/workmux/workmux
  - LATER: joshuto, rogue, tbls
- **tap 12 個**（cask + formula 用すべて）

#### 検証結果
```
Homebrew bundle...
Using arto-app/tap / Using carlocab/personal / ... (全 12 tap)
Using composer / Using luarocks / ... (全 27 formula)
Using arto / Using bruno / ... (全 13 cask)
`brew bundle` complete! 52 Brewfile dependencies now installed.
```
- 全 52 件が `Using` = no-op で宣言完了
- brew 状態の **完全な宣言化**を達成

#### 効果
- 新規マシンでの brew パッケージ復元が `darwin-rebuild switch` 一発で完結
- 何が手で入って何が宣言で入っているかの混乱が解消
- `cleanup = "uninstall"` への切替準備完了（Step 2 follow-up と同期で実施）

---

### Step 5: dotfiles symlink の home-manager 移譲（2026-04-25 完了）

#### 重要な発見（方針転換）
当初想定: `xdg.configFile` で `.config/*` を**個別に** symlink 管理
実際の状態: **`~/.config` 自体が単一 symlink** (`~/.config -> ~/dotfiles/.config`) で運用中

→ 個別管理化は逆に複雑化を招く（home-manager の `xdg.configFile.*` 機構と単一 symlink アーキテクチャの衝突）。
→ **既存アーキテクチャを尊重**し、install.sh の `setup_symlinks` 相当を home-manager の `home.activation` で冪等に保証する方針に変更。

#### 管理対象 symlink（2 件）
1. `~/.config` → `~/dotfiles/.config` （ディレクトリ全体）
2. `~/Library/Application Support/lazygit/config.yml` → `~/dotfiles/config.yml`

#### 実装
`home/taktiks2.nix` に `home.activation.dotfilesSymlinks` を追加：
- `lib.hm.dag.entryAfter [ "writeBoundary" ]` で home-manager のリンク生成後に実行
- ヘルパ関数 `ensure_symlink` で 3 状態を判別:
  - 既に正しい symlink → no-op
  - 別の何か（通常ファイル等）が存在 → WARN を出してスキップ（破壊回避）
  - 何も無い → 親ディレクトリ作成 + symlink 生成

#### 副次的発見: lazygit config の schema drift
- `~/dotfiles/config.yml` (repo): 旧 schema `paging:`
- `~/Library/Application Support/lazygit/config.yml` (live): 新 schema `pagers:`
- → live が auto-migrate された結果、内容が乖離していた
- → activation は正しく WARN を出しスキップ（防御的設計が機能）
- → repo 側の更新を別タスクとして識別

#### 検証結果（switch ログ）
```
Activating dotfilesSymlinks
WARN: /Users/taktiks2/Library/Application Support/lazygit/config.yml が予期しない状態のためスキップ（手動対応要）
```
- `.config` symlink: 既に正しい → 無音通過 ✅
- lazygit: WARN 通り保護的スキップ ✅
- 既存環境への破壊: ゼロ

#### install.sh への影響
- 当面は install.sh `setup_symlinks` も並存させる（二重防御 / 冪等）
- 将来の install.sh クリーンアップで該当箇所を削除可能

#### Step 5 follow-up: lazygit schema 修復と activation 改良（同日）
1. `~/dotfiles/config.yml` を旧 schema (`paging:`) → 新 schema (`pagers:`) へ更新
2. live ファイル削除 → switch でも別プロセスが空ファイルを再生成し WARN 継続
3. `ensure_symlink` を改良: **空ファイル (`-f && ! -s`) は安全に置換**するロジック追加
4. 再 switch で `replaced empty file with symlink: ... -> ~/dotfiles/config.yml` を確認
5. ✅ 完全 symlink 化達成（`lrwxr-xr-x ... config.yml -> /Users/taktiks2/dotfiles/config.yml`）

学び: ファイルロック / 自動再生成は外部プロセスで頻繁に起こるため、activation スクリプトは **「空ファイルは安全に置換可能」というヒューリスティック**を持つと堅牢になる。

---

### Step 6: direnv + nix-direnv + devShell テンプレート（2026-04-25 完了）

#### 作成・変更
| ファイル | 内容 |
|---|---|
| `home/taktiks2.nix` (更新) | `programs.direnv` 有効化（`enableFishIntegration = false`） |
| `.config/fish/config.fish` (更新) | `direnv hook fish | source` を追加 |
| `templates/default/flake.nix` (新規) | 汎用 devShell テンプレ |
| `templates/default/.envrc` (新規) | `use flake` |
| `templates/default/.gitignore` (新規) | `.direnv/`, `result*` |
| `flake.nix` (更新) | `templates.default` 出力を追加 |
| `.gitignore` (更新) | `.config/direnv/`, `.direnv/`, `result*` を除外 |

#### 設計判断
- **Fish 統合は手動フック**: `programs.fish` を有効化していないため、home-manager の自動統合は使わず `config.fish` に hook を直書き
- **devShell テンプレートを `templates/default` で提供**: `nix flake init -t ~/dotfiles` で任意プロジェクトに投入可能
- **`flake-utils.eachDefaultSystem`** を採用: aarch64-darwin / x86_64-darwin / x86_64-linux 等を一発カバー

#### ハマりどころと対処
| 現象 | 原因 | 対処 |
|---|---|---|
| `nix build` が direnv のテストフェーズで hang（`zsh ./test/direnv-test.zsh` 無限待ち） | direnv 2.37.1 の zsh test が aarch64-darwin sandbox で interactive 動作期待 | `programs.direnv.package = pkgs.direnv.overrideAttrs (_: { doCheck = false; })` でテストスキップ |
| 複数 build 重複によるロック競合 | デバッグ中の builds を kill しきれず残存 | 全プロセス kill 後に単独実行 |

#### 検証結果
- ✅ `direnv 2.37.1` 配置: `/etc/profiles/per-user/taktiks2/bin/direnv`
- ✅ Fish hook ロード: `functions __direnv_export_eval` が ACTIVE
- ✅ `~/.config/direnv/lib/` に nix-direnv stdlib 配置
- ✅ `nix flake init -t ~/dotfiles` で template 3ファイル正常展開（flake.nix, .envrc, .gitignore）
- ✅ `.config/direnv/` は gitignore で除外済（dotfiles repo を汚染しない）

#### 使用方法（プロジェクト側）
```bash
mkdir my-project && cd my-project
nix flake init -t ~/dotfiles      # 汎用 devShell テンプレを投入
direnv allow                       # .envrc を承認
# 以後、cd するだけで自動的に devShell が有効化
```

---

### Step 7 (Part A): brew uninstall 31本 + cleanup="uninstall" 化（2026-04-25 完了）

#### 事前検証
- 削除候補 30 本（jq は brew leaf ではなかったため対象外）に対し `brew uses --installed` で被参照を確認 → KEEP 27 本との衝突なし
- `brew autoremove --dry-run` で孤児ゼロ確認
- `bash` の衝突確認: `/bin/bash` (system, 不変) / `/etc/profiles/per-user/...bash` (Nix) / `/opt/homebrew/bin/bash` (削除予定) → 安全

#### 実装
`modules/homebrew.nix` で `cleanup = "none"` → `cleanup = "uninstall"` に変更。次の `darwin-rebuild switch` で brew bundle が宣言外パッケージを自動削除。

#### 検証結果
- ✅ `brew leaves` 57 本 → **27 本**に減少（KEEP セットと完全一致）
- ✅ 30 本全て削除確認
- ✅ Nix 版 14 種（rg/lsd/jq/lazygit/nvim/direnv/tmux/fzf/bat/gh/delta/deno/uv/sbcl）が `/etc/profiles/per-user/taktiks2/bin/` で動作
- ✅ Fish の type -p で正しく Nix 経路に解決
- ✅ 世代: system-9
- ✅ 既存 PHP/MySQL/Ruby/Node 環境への副作用なし

---

### Step 7 (Part B): install.sh 重複処理の削除（2026-04-25 完了）

#### 削除した関数（Nix が代替）
| 関数 | 行数 | 代替 |
|---|---|---|
| `install_brew_packages` | 約42行 | `modules/homebrew.nix` の `homebrew.brews` 宣言 |
| `install_brew_casks` | 約40行 | `modules/homebrew.nix` の `homebrew.casks` 宣言 |
| `setup_symlinks` | 約33行 | `home/taktiks2.nix` の `home.activation.dotfilesSymlinks` |

#### 追加した関数
- **`bootstrap_nix`** (約30行)
  - Determinate Nix を未インストールならインストール
  - 初回ブートストラップは `sudo nix run nix-darwin/master#darwin-rebuild`
  - 通常 switch は `sudo /run/current-system/sw/bin/darwin-rebuild switch`

#### 保持した関数（brew install を超えた post-config）
`setup_php_environment` (Laravel installer) / `install_rust` (rustup) / `setup_nodejs` (nodebrew install latest) / `setup_ruby` (rbenv install) / `setup_fish` (Fisher + bobthefish + chsh + secret-env テンプレ) / `setup_tmux` (TPM clone) / `setup_neovim` (`:Lazy install`)

#### main() の新フロー
```
check_system → install_homebrew → bootstrap_nix
   → setup_php_environment → install_rust → setup_nodejs → setup_ruby
   → setup_fish → setup_tmux → setup_neovim → final_check
```

#### 結果
- 行数: **588 → 501** （約 15% 削減）
- bash 構文チェック: ✅ パス
- 関数数: 16 (旧: 18)
- 「Nix 入れる → switch」が `bootstrap_nix` ひとつにまとまり、レポート初期目標「100行未満が射程」への基盤完成

---

### Step 7 follow-up: 第二陣 brew→Nix 移行 + post-config の home.activation 化

#### 移行: tbls + joshuto を Nix へ
- `home/taktiks2.nix` の `home.packages` に `tbls`, `joshuto` を追加
- `modules/homebrew.nix` の `brews` から削除（`rogue` のみ残置：Nix 版なし）
- 結果: `brew leaves` 27 → **25**、`Uninstalled 2 formulae` を確認

#### post-config 移譲: TPM + secret-env を `home.activation` へ
新規 activation: `home.activation.bootstrapSideEffects`
- **TPM (tmux plugin manager)** の初回 git clone を冪等管理
- **`secret-env.fish` テンプレート**を `~/dotfiles/.config/fish/` に存在しなければ生成

`install.sh` 側:
- `setup_tmux` を **15行 → 4行**（TPM ロジック削除、操作ヒントだけ残す）
- `setup_fish` から secret-env テンプレ生成ブロックを削除
- 行数: 501 → **475**（合計 588 → 475、**19% 削減**）

#### 検証
- ✅ `tbls 1.94.4`, `joshuto 0.9.9` が Nix 版で動作
- ✅ `bootstrapSideEffects` 実行ログ: 既存検出スキップで無音通過（冪等）
- ✅ `install.sh` シンタックス OK

---

### Step 7 follow-up 第二弾: install.sh 更なる削減（2026-04-26 完了）

#### `home.activation.bootstrapSideEffects` に追加移譲した 3 件
1. **Fisher (Fish プラグインマネージャ)**: `~/.config/fish/functions/fisher.fish` 不在時のみ実行
2. **bobthefish テーマ**: `fish_prompt.fish` 不在時のみ実行
3. **Laravel Installer**: `~/.composer/vendor/bin/laravel` 不在時のみ実行

#### install.sh の変更
| 関数 | Before | After |
|---|---|---|
| `setup_php_environment` | Laravel installer ブロック含む | MySQL PATH と composer PATH のみ |
| `setup_fish` | Fisher + bobthefish + chsh + secret-env | chsh のみ（他は activation） |

#### 行数推移
| 段階 | 行数 |
|---|---|
| 開始時 | 588 |
| Step 7 (Part B) 後 | 501 |
| Step 7 follow-up 第一弾後 | 475 |
| **Step 7 follow-up 第二弾後** | **456** |
| 削減合計 | **132 行 (-22.4%)** |

#### install.sh に残置した bootstrap 専用関数
重い / ネットワーク多 / 対話 / 特殊起動が必要なため activation には不適：
- `install_rust`: rustup-init.sh の curl + 実行
- `setup_nodejs`: `nodebrew install-binary stable`（数十 MB ダウンロード）
- `setup_ruby`: `rbenv install <latest>`（Ruby ソースコンパイル、5-10分）
- `setup_fish` の chsh 部分: `sudo` + 対話確認
- `setup_neovim`: `nvim +Lazy +qall` の TUI 起動
- `setup_php_environment` の `brew services start mysql@8.0`: 対話確認
- `final_check`: ツール一覧の確認出力

これらは新規マシン bootstrap 時の 1 回のみ走れば良い処理であり、毎回 switch で冗長に走らせる価値は薄い。

#### 検証結果
- `bootstrapSideEffects` 5 項目（TPM, secret-env, Fisher, bobthefish, Laravel installer）全て既存検出 → スキップ → 無音通過 ✅
- bash syntax check: ✅
- `darwin-rebuild switch` 28.2 秒で完了

---

### 累計成果（Step 1〜7 + 全 follow-up 完了時点）

- **CLI ツール 33 本を Nix 化**（第一陣 31 + 第二陣 tbls/joshuto = 33）
- **dotfiles リポジトリ構造の確立**: `flake.nix` / `hosts/MacBook-Air/` / `home/taktiks2.nix` / `modules/{macos-defaults,homebrew}.nix` / `templates/default/` / `docs/`
- **Fish PATH 統合完了**: 既存 `config.fish` を壊さず Nix を最優先化（行 82–84）
- **macOS システム設定を宣言化**（ACTIVE 7 項目 + OPT-IN 多数 / 拡張子・隠しファイル表示は working-tree で uncomment 中・未 switch）
- **Homebrew 完全宣言化**: tap 12 + formula 25 + cask 13 = 計 50 件（第二陣で tbls/joshuto を Nix 移行のため formula は 27→25）
- **`cleanup = "uninstall"` 化済**: 未宣言の brew パッケージを switch 時に自動削除
- **dotfiles symlink を home-manager 管理化**: `home.activation.dotfilesSymlinks` で冪等保証
- **post-config の home.activation 移譲**: TPM / secret-env / Fisher / bobthefish / Laravel installer を `bootstrapSideEffects` で初回のみ実行
- **direnv + nix-direnv 統合 + devShell テンプレート提供**: `nix flake init -t ~/dotfiles` で投入可能
- **brew leaves が 57 → 25 本に整理**
- **install.sh が 588 → 456 行に削減**（-22.4%）: 重複処理削除 + Nix bootstrap 統合 + post-config 6 件を home.activation 化
- **ロールバック可能性確保**: nix-darwin の世代管理が完全動作
- **既存環境への副作用ゼロ**: PHP / MySQL / Ruby / Node 含め全て従来通り動作

---

*このレポートは Claude Code (Opus 4.7) による調査・実装記録。エコシステム動向は 2026 年 4 月時点。実施: Step 1 → 2 → 3 → 4 → 4b → 5 → 6 → 7 → 7 follow-up（2026-04-25）。レポートは 2026-04-26 時点の実測値で再構成。*

---

## 11. 現状アセスメント（2026-04-26 再構成）

Step 1〜7 + 全 follow-up 完了時点での **「いま実機がどう構成されているか / どう使えばよいか」** を実測値で再整理した版。前版（2026-04-25 追記）は Step 7 直前のスナップショットで世代・パッケージ数・brew uninstall ステータスがズレていたため、本節で完全に置き換える。

### 11.1 実測スナップショット（2026-04-26）

| 項目 | 実測値 | 確認方法 |
|---|---|---|
| Nix バージョン | **2.34.6**（Determinate Nix） | `nix --version` |
| 現在の system 世代 | **system-11**（`darwin-system-26.05.06648f4`） | `ls /nix/var/nix/profiles/system` |
| 過去世代数 | system-1 〜 system-11（11 世代積み上がり） | `/nix/var/nix/profiles/system-*-link` |
| ユーザプロファイルのバイナリ数 | **86 バイナリ / 33 パッケージ** | `ls /etc/profiles/per-user/taktiks2/bin \| wc -l` |
| Nix flake inputs (lock) | nixpkgs 2026-04-23 / nix-darwin 2026-04-01 / home-manager 2026-04-25 | `flake.lock` |
| Homebrew leaves | **25 本** | `brew leaves \| wc -l` |
| Homebrew 全 formula（dep 含む） | 159 本 | `brew list --formula \| wc -l` |
| Homebrew tap | **12** / cask **13** | `brew tap` / `brew list --cask` |
| 宣言ファイル状態 | tap 12 / formula 25 / cask 13（`modules/homebrew.nix`） | `awk` 抽出 |
| `cleanup` 設定 | **`"uninstall"`**（未宣言は switch 時に自動削除） | `modules/homebrew.nix:20` |
| install.sh | **456 行** / 関数 16 個 | `wc -l install.sh` |
| `~/.config` symlink | `~/dotfiles/.config` 健全 | `ls -la ~/.config` |
| lazygit symlink | `~/dotfiles/config.yml` 健全 | `ls -la "~/Library/Application Support/lazygit/config.yml"` |
| direnv | `/etc/profiles/per-user/taktiks2/bin/direnv` 配置済 + Fish hook 動作中 | `which direnv` / `config.fish:91` |
| home.activation | `dotfilesSymlinks` + `bootstrapSideEffects`（5 件のサイドエフェクト管理） | `home/taktiks2.nix:68,94` |
| ロールバック | `sudo darwin-rebuild --rollback` で system-10 へ戻し可能 | — |

### 11.2 リポジトリ状態（git）

| 項目 | 値 |
|---|---|
| カレントブランチ | **`feat/nix`**（main から **10 commits 先行・未マージ**） |
| 含まれるコミット | Step 1 → 2 → 3 → 4 → 4b → 5 → 6 → 7 → Step 7 follow-up x2 |
| 未コミット差分 | `modules/macos-defaults.nix`（後述） |

#### 未コミット / 未 switch の作業差分（要処理）

working tree で 3 項目が OPT-IN コメントを外した状態になっているが、`darwin-rebuild switch` が走っていないため **`defaults read` では未反映**（domain pair が存在しない状態）：

- `finder.AppleShowAllExtensions = true`
- `finder.AppleShowAllFiles = true`
- `NSGlobalDomain.AppleShowAllExtensions = true`

→ **対応 2 択**: ① そのまま `switch` してから commit する（採用するなら ACTIVE に昇格）／ ② `git checkout -- modules/macos-defaults.nix` で破棄する。

### 11.3 役割分担の現実（実装後）

```
┌────────────────────────────────────────────────────────────┐
│ Nix (home-manager)             … CLI 33本 + direnv         │
│   /etc/profiles/per-user/taktiks2/bin/  (86 binaries)      │
├────────────────────────────────────────────────────────────┤
│ Homebrew (nix-darwin で宣言)   … cask 13 + formula 25      │
│   /opt/homebrew/                                           │
│   ├ PHP/MySQL/rbenv/nodebrew/postgres/python はここ        │
│   ├ qmk/atac/heroku/avr-gcc 等の第三者 tap formula         │
│   └ rogue (Nix 版なし・嗜好で残置)                         │
│   cleanup = "uninstall" により未宣言は switch で自動削除   │
├────────────────────────────────────────────────────────────┤
│ macOS system.defaults          … Dock/Finder/Trackpad 等   │
│   ACTIVE 7 + OPT-IN 多数（uncomment で発動）               │
├────────────────────────────────────────────────────────────┤
│ home-manager activation        … 冪等な側付け処理           │
│   ├ dotfilesSymlinks: ~/.config と lazygit の symlink      │
│   └ bootstrapSideEffects:                                  │
│        TPM / secret-env / Fisher / bobthefish / Laravel    │
├────────────────────────────────────────────────────────────┤
│ direnv + nix-direnv            … プロジェクト単位の隔離     │
│   templates/default で `nix flake init -t ~/dotfiles`      │
└────────────────────────────────────────────────────────────┘
```

### 11.4 残作業 / 未着手

| 項目 | 状況 | 優先度 |
|---|---|---|
| `modules/macos-defaults.nix` の working-tree 差分処理 | switch して commit するか revert するか未決定 | **高** |
| `feat/nix` ブランチを main にマージ | PR 未作成。10 commits 蓄積中 | **高** |
| `modules/homebrew.nix` 冒頭コメントの整合 | 旧 `cleanup="none"` の文面が残存（実体は `uninstall`）。section header も `（27 本）`が残る（実数 25） | 中 |
| `.config/*` 個別の `xdg.configFile` 化 | **意図的に見送り**（`~/.config` 全体 symlink 運用を維持） | — |
| `clisp` の廃止判断 | sbcl で代替可、好みで残置 | 低 |
| `cachix` / Determinate Cache の有効化 | 未設定。aarch64-darwin の重量ビルド時に効く | 低（必要時） |
| 第二マシンでの再現テスト | 未実施（機会次第） | 低 |

### 11.5 日常運用フロー

#### 月次メンテ
```bash
cd ~/dotfiles
nix flake update                                   # inputs を全更新
sudo darwin-rebuild switch --flake .#MacBook-Air   # 適用
# 何か壊れたら即時:
sudo darwin-rebuild --rollback
```

#### 新しい CLI を試す → 採用する
```bash
# ① 試用（PATH に一時導入）
nix shell nixpkgs#hyperfine
hyperfine --version
exit

# ② 採用（常駐化）
$EDITOR ~/dotfiles/home/taktiks2.nix      # home.packages に hyperfine を追加
sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air
git -C ~/dotfiles commit -am "add hyperfine"
```

#### GUI アプリ（cask）追加
```bash
$EDITOR ~/dotfiles/modules/homebrew.nix   # casks に追記
sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air
```
※ `cleanup="uninstall"` のため、宣言から外した cask は次の switch で削除される。

#### macOS 設定の変更
```bash
$EDITOR ~/dotfiles/modules/macos-defaults.nix   # OPT-IN を uncomment
sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air
# Dock/Finder の再起動が走り即反映。
```

#### 新規プロジェクトの devShell
```bash
mkdir ~/work/new-project && cd $_
nix flake init -t ~/dotfiles      # templates/default を展開
$EDITOR flake.nix                  # packages に必要なランタイムを追加
direnv allow                       # 以後 cd で自動有効化
```

#### 別マシンへの再現
```bash
# 1) Determinate Nix
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
# 2) リポジトリ
git clone <repo> ~/dotfiles
cd ~/dotfiles
# 3) 初回 bootstrap（install.sh の bootstrap_nix が同等処理を実施）
sudo /nix/var/nix/profiles/default/bin/nix run nix-darwin/master#darwin-rebuild -- \
  switch --flake ~/dotfiles#MacBook-Air
# 4) 以後の更新
sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air
```

### 11.6 トラブルシュート

| 症状 | 対処 |
|---|---|
| `darwin-rebuild` が見つからない | 新シェル起動。または `/run/current-system/sw/bin/darwin-rebuild` で直叩き |
| `switch` が失敗する | エラー読む → `sudo darwin-rebuild --rollback` → 修正 → 再 switch |
| brew 版を強制したいコマンドがある | `command /opt/homebrew/bin/<cmd>` で明示指定 |
| flake input を巻き戻したい | `flake.lock` を `git checkout` → switch |
| ストアが肥大 | `nix-collect-garbage -d`（古い世代も削除） |
| symlink activation が WARN を出す | `home.activation.dotfilesSymlinks` が「予期しない実体」を保護スキップしている。手動で内容確認後、必要なら repo 側へ移植 → live を削除 → 再 switch |

### 11.7 完成度評価

| 観点 | 評価 | コメント |
|---|---|---|
| 再現性 | ★★★★★ | tap/formula/cask が `cleanup="uninstall"` で完全同期。install.sh は post-config の orchestration だけ |
| 宣言性 | ★★★★★ | brew/Nix/macOS/symlink/post-config 全てが git 配下 |
| ロールバック性 | ★★★★★ | system-1〜11 の世代が残存、`--rollback` 即時 |
| 既存環境との共存 | ★★★★★ | PHP/MySQL/Ruby/Node が brew 経由で従来通り |
| 学習コスト | ★★★☆☆ | flake / home-manager の最小限 DSL を学べば十分 |
| 日常運用負荷 | ★★★★☆ | switch 1 コマンドで完結。月次の `flake update` が定型作業 |
| **ドキュメント整合性** | ★★★★☆ | 本再構成で改善。`modules/homebrew.nix` 冒頭コメントは未追従 |

### 11.8 結論

- **Nix 統合は実用フェーズに到達**。Step 1〜7 は完了し、`feat/nix` ブランチを main にマージするだけ。
- **日常は `$EDITOR home/taktiks2.nix → switch → commit` の 3 ステップ**で完結。
- **新規プロジェクトには `nix flake init -t ~/dotfiles`**。グローバル汚染を避ける標準フロー。
- **緊急時は `sudo darwin-rebuild --rollback`**。最大のセーフティネット。
- 直近の処理候補は **(1) `macos-defaults.nix` の working-tree 差分を確定 → (2) `modules/homebrew.nix` 冒頭コメントの追従 → (3) `feat/nix` を main にマージ** の 3 つ。

---

## 12. 監査フォローアップ（2026-04-26 完了）

Step 1〜7 完了後、レポートと実コードを 2026 年のベストプラクティスに照合し、5 件の改善を実施。

### 12.1 Determinate nix-darwin module 採用（Phase 1）

**変更前**: `nix.enable = false` を `hosts/MacBook-Air/default.nix` に手書き
**変更後**: `determinate.darwinModules.default` + `determinateNix.enable = true`

```nix
# flake.nix
inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
modules = [
  determinate.darwinModules.default
  ({ ... }: { determinateNix.enable = true; })
  ./hosts/${hostname}
  ...
];
```

`/etc/nix/nix.custom.conf` 経由で GC スケジュールや `extra-substituters` を将来宣言可能になる。
既存 `/etc/nix/nix.custom.conf` (Determinate `nix-installer` 設置) との衝突は `*.before-nix-darwin` で退避して解消。Determinate 3.18.1 が解決された。

### 12.2 `nixpkgs.config.allowUnfreePredicate` 予防 allowlist（Phase 2）

`flake.nix` に空 allowlist を追加。将来 `vscode` 等を Nix 化する際の編集ポイントを明示。

```nix
({ lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [];
})
```

### 12.3 Fish 本格宣言化（Phase 3）

最大の作業。`~/.config -> ~/dotfiles/.config` 単一 symlink を解体し、`programs.fish` を full に有効化。

#### 12.3.1 アーキテクチャ転換

| 項目 | Before | After |
|---|---|---|
| `~/.config` | 単一 symlink → `~/dotfiles/.config` | 個別 symlink 12 + 実 dir (fish, runtime state) |
| Fish 設定 | `~/dotfiles/.config/fish/config.fish` 手書き | `programs.fish.{shellInit, interactiveShellInit, shellAliases}` |
| Fish plugins | Fisher (curl パイプ for bobthefish/z/bass) | `programs.fish.plugins = [ fishPlugins.{bobthefish,z,bass} ]` |
| Fish 本体 | brew formula `fish` | Nix `home-manager.programs.fish.enable` |
| `/etc/shells` | 未登録 | `environment.shells = [ pkgs.fish ]` で登録 |
| Terminal config | `/opt/homebrew/bin/fish` ハードコード | `/run/current-system/sw/bin/fish`（Nix 安定経路） |
| Fisher | brew formula | **削除**（plugins は Nix 直接管理） |

#### 12.3.2 ~/.config 解体手順

1. `mv ~/.config ~/.config.symlink-backup` で旧 symlink 退避
2. `mkdir ~/.config` 後、git tracked 12 dir を個別 symlink (alacritty/atac/btop/ccstatusline/cspell/gh-dash/ghostty/git/mcphub/nvim/tmux/workmux)
3. dotfiles repo に紛れ込んでいた untracked runtime state 10 dir (Battle.net/broot/configstore/direnv/gh/github-copilot/gtk-2.0/wireshark/yarn/yaru) を `~/dotfiles/.config/<dir>` から `~/.config/<dir>` へ物理移動 → repo 作業ツリーが浄化
4. `secret-env.fish` (実 GITHUB_PERSONAL_ACCESS_TOKEN 含む) を `~/.config/fish/secret-env.fish` に配置（mode 600、dotfiles repo 外）

#### 12.3.3 ハマりどころ

| 現象 | 原因 | 対処 |
|---|---|---|
| `ln -s` 後に `~/.config/ccstatusline/ccstatusline -> dotfiles dir` という入れ子 symlink が発生 | バックグラウンドの ccstatusline plugin プロセスがディレクトリを先に新規作成し、`ln -s` がターゲット内にリンクを作る挙動になった | 入れ子削除 → 新規 settings.json 退避 → symlink 再作成 |
| `darwin-rebuild switch` 時に brew が `fisher` を uninstall する際、依存先の `fish` 本体も連鎖削除 | `cleanup="uninstall"` + brew autoremove の挙動 | `home-manager.programs.fish.enable = true` で Nix 版 fish を確保。Alacritty/Ghostty config を `/run/current-system/sw/bin/fish` に切替 |
| `/etc/shells` に Nix fish が登録されない | `programs.fish.enable = true` (system level) は登録しない仕様 | `environment.shells = [ pkgs.fish ]` を nix-darwin に追加 |

#### 12.3.4 削除した orphan ファイル（21 ファイル）

```
.config/fish/config.fish              (programs.fish.{shell,interactive}Init に移植)
.config/fish/fish_plugins             (Nix の plugins 宣言で代替)
.config/fish/fish_variables           (起動時 cache、再生成される)
.config/fish/functions/*.fish (16)    (fishPlugins で再生成)
.config/fish/conf.d/multi-agent-shogun.fish (shellAliases に移植)
.config/fish/conf.d/z.fish            (fishPlugins.z で代替)
```

`feat/nix` ブランチ通算で **23 files / -2973 lines** のクリーンアップ。

#### 12.3.5 検証結果（新 fish プロセスにて）

| 項目 | 結果 |
|---|---|
| fish 4.6.0 (Nix 版) 起動 | ✅ |
| bobthefish プロンプト関数 (`fish_prompt`) 定義 | ✅ |
| z plugin (autojump) `function z` | ✅ |
| bass plugin `function bass` | ✅ |
| 12 alias (lg/vim/ls/css/csm 等) | ✅ |
| PATH 順序: rbenv shims → Nix → brew → Android SDK → ... | ✅ |
| 言語ランタイム: php / node / rbenv / composer | ✅ |
| Nix CLI: rg / jq / lazygit / direnv | ✅ |
| `secret-env.fish` 読み込み（GITHUB_PERSONAL_ACCESS_TOKEN 解決） | ✅ |
| direnv hook (`__direnv_export_eval`) 注入 | ✅ |
| workmux completions ロード | ✅ |
| rbenv shim 関数定義 | ✅ |

### 12.4 細部整合（Phase 4 / 5）

- `home/taktiks2.nix` の direnv `overrideAttrs` に upstream tracking コメント追記
- `modules/homebrew.nix` 冒頭コメントを `cleanup="uninstall"` 実体に追従、formula セクション header を 25→24 本に修正

### 12.5 累計成果（Step 1〜7 + 監査フォローアップ完了時点）

- **CLI ツール 33 本 + Fish plugin manager 1 本 = 34 本相当を Nix 化**
- **Fish 本体・全 plugin・config が Nix 完全宣言化**（Fisher 撤廃）
- **`~/.config` を git tracked 12 dir + home-manager 管理 fish + 実 dir runtime state に三層化**
- **dotfiles repo から 21 fish 関連ファイル + 10 untracked dir を排除**
- **Determinate nix-darwin module 採用**で `nix.custom.conf` ベースの宣言可能化
- **`/etc/shells` に Nix fish を登録** → chsh で fish へ切替可能
- **`brew leaves` が 25 → 24 本に減少**
- **Alacritty / Ghostty が Nix 安定経路 (`/run/current-system/sw/bin/fish`) を参照**

---

*監査フォローアップ実施日: 2026-04-26（同日中の Phase 1→2→3→4→5 一括完了）。検証は実マシン上で fish 4.6.0 直接起動による動作確認で実施。*
