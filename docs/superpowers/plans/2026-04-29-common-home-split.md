# Phase 21: home/common.nix + home/users/&lt;username&gt;.nix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `home/taktiks2.nix` を `home/common.nix` (全ユーザ共通 baseline) と `home/users/<username>.nix` (個人差分、auto-import) に分離し、別 username の Mac (会社配布 PC など) を `flake.nix` の `darwinConfigurations` に 1 ブロック追加するだけで導入できる構造にする。

**Architecture:** `flake.nix` の `mkDarwin` factory に `homeExtraModules ? [ ]` 引数を追加し、`home-manager.users.${username}` に `[ ./home/common.nix ]` + 自動 import される `./home/users/<username>.nix` (optional) + `homeExtraModules` を imports として渡す。既存の per-tool 分割 (`home/programs/*.nix`) は無修正。

**Tech Stack:** Nix flakes, nix-darwin, home-manager 25.11, Determinate Nix。

**Spec:** `docs/superpowers/specs/2026-04-29-common-home-design.md`

**実装方針:** リファクタリングのため build artifact (closure) は不変であるべき。各 commit 後に `nix eval` で代表値 (JAVA_HOME / LANG / sessionPath / packages 数) を確認し、commit 1 → 2 → 3 のいずれの中間状態でも `darwin-rebuild build` が pass することを検証する。

---

### Task 0: ベースライン値のキャプチャ

**Files:**
- なし (検証用コマンドのみ)

- [ ] **Step 1: 現状の eval 値を保存**

Run:
```bash
cd ~/dotfiles
mkdir -p /tmp/phase21-baseline
nix eval --raw '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionVariables.JAVA_HOME' \
  > /tmp/phase21-baseline/JAVA_HOME.txt
nix eval --raw '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionVariables.LANG' \
  > /tmp/phase21-baseline/LANG.txt
nix eval --json '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionPath' \
  > /tmp/phase21-baseline/sessionPath.json
nix eval --json '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.packages' --apply 'pkgs: builtins.length pkgs' \
  > /tmp/phase21-baseline/packages_count.json
echo "baseline captured:"
ls -la /tmp/phase21-baseline/
cat /tmp/phase21-baseline/JAVA_HOME.txt
cat /tmp/phase21-baseline/LANG.txt
cat /tmp/phase21-baseline/packages_count.json
```

Expected output:
- `JAVA_HOME.txt` → `/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home`
- `LANG.txt` → `en_US.UTF-8`
- `packages_count.json` → 数値（参考: 25 前後）
- `sessionPath.json` → 配列 JSON

- [ ] **Step 2: ドライビルドで現状が緑であることを確認**

Run: `sudo darwin-rebuild build --flake ~/dotfiles#MacBook-Air`
Expected: ビルド成功、`./result` が作られる。エラーが出る場合は本実装に進まずベースラインを直す。

Run: `rm -f ~/dotfiles/result`
Expected: 後続検証用に削除（残しておくと git status を汚す）。

---

### Task 1: home/common.nix を home/taktiks2.nix のコピーとして作成 + flake.nix の import 切り替え

**Files:**
- Create: `home/common.nix` (内容は `home/taktiks2.nix` と完全同一)
- Modify: `flake.nix:43-49, 60-68`
- Delete: `home/taktiks2.nix`

このコミット時点では JAVA_HOME はまだ `home/common.nix` 側に残る。flake.nix だけ「common.nix を読む / homeExtraModules / auto-import users/」構造に切り替え、行動は完全不変。

- [ ] **Step 1: common.nix を taktiks2.nix の完全コピーとして作成**

Run: `cp ~/dotfiles/home/taktiks2.nix ~/dotfiles/home/common.nix`
Expected: コピー成功。

Verify:
```bash
diff ~/dotfiles/home/taktiks2.nix ~/dotfiles/home/common.nix
```
Expected: 差分なし (exit 0)。

- [ ] **Step 2: flake.nix の mkDarwin にシグネチャ拡張 + auto-import 実装**

Edit `~/dotfiles/flake.nix`:

`mkDarwin` の引数定義 (現在は 43-49 行) を以下に置換:

```nix
      mkDarwin =
        { hostname
        , username
        , dotfilesRoot ? "/Users/${username}/dotfiles"
        , system ? "aarch64-darwin"
        , extraModules ? [ ]
        , homeExtraModules ? [ ]
        }:
        let
          userFile = ./home/users + "/${username}.nix";
        in
        nix-darwin.lib.darwinSystem {
```

`home-manager.users.${username}` の代入行 (現在 67 行: `home-manager.users.${username} = import ./home/${username}.nix;`) を以下に置換:

```nix
              home-manager.users.${username} = { lib, ... }: {
                imports =
                  [ ./home/common.nix ]
                  ++ lib.optional (builtins.pathExists userFile) userFile
                  ++ homeExtraModules;
              };
```

- [ ] **Step 3: 旧 home/taktiks2.nix を削除**

Run: `rm ~/dotfiles/home/taktiks2.nix`
Expected: 削除成功。

- [ ] **Step 4: 評価チェック (auto-import の optional 性検証)**

`home/users/taktiks2.nix` はまだ存在しないので、`pathExists` が false を返し、common.nix のみが import される状態。JAVA_HOME は common.nix 側に残っているので値は不変なはず。

Run:
```bash
cd ~/dotfiles
nix eval --raw '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionVariables.JAVA_HOME'
```
Expected: `/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home`（baseline と一致）

Run: `cat /tmp/phase21-baseline/JAVA_HOME.txt`
Expected: 上記と同じ値。

- [ ] **Step 5: ドライビルド**

Run: `sudo darwin-rebuild build --flake ~/dotfiles#MacBook-Air`
Expected: ビルド成功。

Run: `rm -f ~/dotfiles/result`

- [ ] **Step 6: コミット**

```bash
cd ~/dotfiles
git add home/common.nix flake.nix
git rm home/taktiks2.nix
git status
```

確認したら:
```bash
git commit -m "$(cat <<'EOF'
refactor(nix): Phase 21 step 1 - home/common.nix へ rename + auto-import 配線

home/taktiks2.nix の中身を home/common.nix へそのまま移し、flake.nix の
mkDarwin に homeExtraModules 引数追加 + home/users/<username>.nix の
auto-import を実装。本コミット時点では home/users/<username>.nix は
未作成のため pathExists=false で skip され、ビルド成果物は完全不変。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: JAVA_HOME を home/users/taktiks2.nix へ抽出 + LANG を mkDefault 化

**Files:**
- Create: `home/users/taktiks2.nix`
- Modify: `home/common.nix` の `home.sessionVariables` ブロック (JAVA_HOME 削除、LANG を `lib.mkDefault` でラップ)

- [ ] **Step 1: home/users ディレクトリと taktiks2.nix を作成**

Run: `mkdir -p ~/dotfiles/home/users`

Create `~/dotfiles/home/users/taktiks2.nix` with:

```nix
{ ... }:

# Phase 21: taktiks2 個人の install-specific 差分。
# home/common.nix の baseline を override する形で hard-coded path 等を上書きする。
# 中身は最小スタート (YAGNI)。今後の追加候補:
#   - 個人用追加 packages (home.packages = with pkgs; [ ... ])
#   - 個人 alias (programs.fish.shellAliases.foo = "bar")
#   - 個人 git identity (programs.git.includes に gitdir 条件)

{
  # Zulu JDK 17 を使う install 環境への hard-coded path。
  # 別 username の Mac で別 JDK を使うなら、その user file 側で同様に上書きする。
  home.sessionVariables.JAVA_HOME =
    "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home";
}
```

- [ ] **Step 2: home/common.nix から JAVA_HOME を削除し、LANG を mkDefault 化**

Edit `~/dotfiles/home/common.nix` の `home.sessionVariables` ブロック。

old_string:
```nix
  home.sessionVariables = {
    ANDROID_SDK_ROOT           = "${config.home.homeDirectory}/Library/Android/sdk";
    JAVA_HOME                  = "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home";
    ATAC_MAIN_DIR              = "${config.home.homeDirectory}/.config/atac";
    ATAC_THEME                 = "${config.home.homeDirectory}/.config/atac/settings/theme.toml";
    ATAC_KEY_BINDINGS          = "${config.home.homeDirectory}/.config/atac/settings/key.toml";
    GH_PAGER                   = "delta";
    VIRTUAL_ENV_DISABLE_PROMPT = "1";
    LANG                       = "en_US.UTF-8";
    DYLD_LIBRARY_PATH          = "/opt/homebrew/opt/mysql@8.0/lib";
    RBENV_SHELL                = "fish";
  };
```

new_string:
```nix
  # Phase 21: install-specific な hard-coded path (JAVA_HOME など) は home/users/<username>.nix へ移譲。
  # LANG はロケール変更があり得るため lib.mkDefault でラップし、user 側で `mkForce` 不要で上書き可能にする。
  home.sessionVariables = {
    ANDROID_SDK_ROOT           = "${config.home.homeDirectory}/Library/Android/sdk";
    ATAC_MAIN_DIR              = "${config.home.homeDirectory}/.config/atac";
    ATAC_THEME                 = "${config.home.homeDirectory}/.config/atac/settings/theme.toml";
    ATAC_KEY_BINDINGS          = "${config.home.homeDirectory}/.config/atac/settings/key.toml";
    GH_PAGER                   = "delta";
    VIRTUAL_ENV_DISABLE_PROMPT = "1";
    LANG                       = lib.mkDefault "en_US.UTF-8";
    DYLD_LIBRARY_PATH          = "/opt/homebrew/opt/mysql@8.0/lib";
    RBENV_SHELL                = "fish";
  };
```

(JAVA_HOME 行を削除し、LANG 行を `lib.mkDefault` で包む。コメントを上に追加。)

- [ ] **Step 3: 評価チェック (JAVA_HOME と LANG が両方期待値を返すこと)**

Run:
```bash
cd ~/dotfiles
echo "JAVA_HOME (期待: zulu-17 path):"
nix eval --raw '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionVariables.JAVA_HOME'
echo
echo "LANG (期待: en_US.UTF-8):"
nix eval --raw '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionVariables.LANG'
echo
```
Expected:
- JAVA_HOME → `/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home`（user file から）
- LANG → `en_US.UTF-8`（mkDefault のデフォルト値）

両方の値を baseline と比較:
```bash
diff <(nix eval --raw '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionVariables.JAVA_HOME') /tmp/phase21-baseline/JAVA_HOME.txt && echo "JAVA_HOME OK"
diff <(nix eval --raw '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionVariables.LANG') /tmp/phase21-baseline/LANG.txt && echo "LANG OK"
```
Expected: 両方 `OK`。

- [ ] **Step 4: auto-import が外れた場合に JAVA_HOME が unset になることを確認**

`home/users/taktiks2.nix` を一時退避:
```bash
mv ~/dotfiles/home/users/taktiks2.nix /tmp/phase21-taktiks2.nix.bak
```

Run:
```bash
cd ~/dotfiles
nix eval --raw '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionVariables.JAVA_HOME' 2>&1 | head -5
```
Expected: エラー (`error: attribute 'JAVA_HOME' missing` 等)。これにより common.nix から JAVA_HOME が抜け、user file からのみ供給されることが検証される。

復元:
```bash
mv /tmp/phase21-taktiks2.nix.bak ~/dotfiles/home/users/taktiks2.nix
nix eval --raw '.#darwinConfigurations."MacBook-Air".config.home-manager.users.taktiks2.home.sessionVariables.JAVA_HOME'
```
Expected: 復元後は zulu-17 path が返る。

- [ ] **Step 5: ドライビルド**

Run: `sudo darwin-rebuild build --flake ~/dotfiles#MacBook-Air`
Expected: ビルド成功。

Run: `rm -f ~/dotfiles/result`

- [ ] **Step 6: closure 差分が無いことを確認**

このコミット前後で生成 closure の中身が一致するはず（JAVA_HOME 値は同じ、提供元が common から user に変わっただけ）。

Run:
```bash
cd ~/dotfiles
sudo darwin-rebuild build --flake .#MacBook-Air
nix store diff-closures /run/current-system ./result
```
Expected: 差分が現在世代との比較なので、本リファクタ起因の closure 差分は無いか、あっても home-manager の generation メタデータ程度のみ。`+` 行で実 package 増減が出ないこと。

Run: `rm -f ~/dotfiles/result`

- [ ] **Step 7: コミット**

```bash
cd ~/dotfiles
git add home/common.nix home/users/taktiks2.nix
git status
```

確認したら:
```bash
git commit -m "$(cat <<'EOF'
refactor(nix): Phase 21 step 2 - JAVA_HOME を home/users/taktiks2.nix へ抽出

install-specific な hard-coded path である JAVA_HOME を home/common.nix から
home/users/taktiks2.nix へ移譲。別 username の Mac で別 JDK を使う場合は
その user file 側で同様に上書きする運用へ。

LANG は ロケール変更があり得るため lib.mkDefault でラップし、user 側で
mkForce 不要で上書き可能にした。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: install.sh / README.md / CLAUDE.md の更新

**Files:**
- Modify: `install.sh:189-210` (final_check ヒント文)
- Modify: `README.md` (ディレクトリツリー / 「別 username」節 / 「ホスト固有モジュール」節 / Daily Operations 表)
- Modify: `CLAUDE.md` (Architecture 表 / Daily Operations 表 / 主要ファイル一覧)

- [ ] **Step 1: install.sh の final_check ヒント文を更新**

Edit `~/dotfiles/install.sh`。

old_string (203 行付近):
```
日常運用:
  \$EDITOR ~/dotfiles/home/<username>.nix
  sudo darwin-rebuild switch --flake ~/dotfiles#${HOST_NAME}
```

new_string:
```
日常運用:
  \$EDITOR ~/dotfiles/home/common.nix              # 全ユーザ共通の baseline
  \$EDITOR ~/dotfiles/home/users/<username>.nix    # 個人差分 (任意)
  sudo darwin-rebuild switch --flake ~/dotfiles#${HOST_NAME}
```

- [ ] **Step 2: README.md の「ファイル構成」ツリーを更新**

Edit `~/dotfiles/README.md`。

old_string:
```
├── home/
│   └── taktiks2.nix              # home-manager: Nix CLI / programs.fish / direnv / activation
```

new_string:
```
├── home/
│   ├── common.nix                # home-manager 共通 baseline (全ユーザ): Nix CLI / programs.* / activation
│   ├── users/                    # ユーザ単位の個人差分 (auto-import される)
│   │   └── taktiks2.nix          # taktiks2 の差分 (JAVA_HOME 等)
│   └── programs/                 # per-tool 設定 (fish / git / tmux / direnv / lazygit / ...)
```

- [ ] **Step 3: README.md の Daily Operations 表 (「Nix CLI」「Fish 設定」行) を更新**

Edit `~/dotfiles/README.md` の「### 何かを足したい」表。

old_string:
```
| Nix CLI | `home/taktiks2.nix` の `home.packages` | `sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air` |
| brew formula / cask | `modules/homebrew.nix` の `brews` / `casks` | 同上 |
| macOS 設定 | `modules/macos-defaults.nix` | 同上 |
| Fish 設定 | `home/taktiks2.nix` の `programs.fish.{shellInit, interactiveShellInit, shellAliases}` | 同上 |
```

new_string:
```
| Nix CLI | `home/common.nix` の `home.packages` (個人だけなら `home/users/<username>.nix`) | `sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air` |
| brew formula / cask | `modules/homebrew.nix` の `brews` / `casks` | 同上 |
| macOS 設定 | `modules/macos-defaults.nix` | 同上 |
| Fish 設定 | `home/programs/fish.nix` の `programs.fish.{shellInit, interactiveShellInit, shellAliases}` (個人 alias は `home/users/<username>.nix`) | 同上 |
```

- [ ] **Step 4: README.md の「Fish 設定の編集」節を更新**

old_string:
```
### Fish 設定の編集

`~/.config/fish/config.fish` は **Nix 生成 symlink** のため直接編集してはいけません。`home/taktiks2.nix` の `programs.fish` セクションを編集してください。
```

new_string:
```
### Fish 設定の編集

`~/.config/fish/config.fish` は **Nix 生成 symlink** のため直接編集してはいけません。共通設定は `home/programs/fish.nix`、個人 alias / 関数は `home/users/<username>.nix` の `programs.fish.*` セクションを編集してください（後者は HM が set/list を merge するため追加方向は `mkForce` 不要）。
```

- [ ] **Step 5: README.md の「sops 編集」節を更新**

old_string:
```
# home/taktiks2.nix の sops.secrets に各 KEY を列挙して switch
```

new_string:
```
# home/common.nix の sops.secrets に各 KEY を列挙して switch
```

- [ ] **Step 6: README.md の「別 username の Mac を追加する」節を更新**

old_string:
```
### 別 username の Mac を追加する

```bash
# 1. home/<username>.nix を新規作成（既存をコピー）
cp home/taktiks2.nix home/foo.nix

# 2. flake.nix に新 username でブロック追加
#    "MacBook-Foo" = mkDarwin { hostname = "MacBook-Foo"; username = "foo"; };

# 3. dotfilesRoot を ~/dotfiles 以外に置くなら引数で上書き
#    "MacBook-Foo" = mkDarwin {
#      hostname = "MacBook-Foo";
#      username = "foo";
#      dotfilesRoot = "/Users/foo/code/dotfiles";
#    };
```
```

new_string:
````
### 別 username の Mac を追加する（会社配布 PC など）

```bash
# 1. flake.nix の darwinConfigurations に新 username のブロックを 1 行追加
#    "Company-MBP" = mkDarwin { hostname = "Company-MBP"; username = "firstname.lastname"; };

# 2. 個人差分が必要なら home/users/<username>.nix を新規作成（auto-import される）
$EDITOR home/users/firstname.lastname.nix
```

`home/common.nix` の baseline はそのまま使い回し、JAVA_HOME / proxy / 業務固有 packages 等の差分だけを user file に書く運用です。`home/users/<username>.nix` は **存在すれば自動 import**、無ければ skip されます。

例: 会社配布 PC で JDK / proxy / awscli を上書きする `home/users/firstname.lastname.nix`:

```nix
{ lib, pkgs, ... }:
{
  home.sessionVariables = {
    JAVA_HOME = "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home";
    HTTPS_PROXY = "http://proxy.corp:8080";
  };

  home.packages = with pkgs; [ awscli2 ];

  programs.git.includes = [
    { path = "~/.config/git/config.work";
      condition = "gitdir:~/work/"; }
  ];
}
```

`dotfilesRoot` を `~/dotfiles` 以外に置くなら引数で上書き:

```nix
"Company-MBP" = mkDarwin {
  hostname = "Company-MBP";
  username = "firstname.lastname";
  dotfilesRoot = "/Users/firstname.lastname/code/dotfiles";
};
```
````

- [ ] **Step 7: README.md の「ホスト固有モジュールを差し込みたい」節を更新**

old_string:
```
### ホスト固有モジュールを差し込みたい

`flake.nix` の `mkDarwin` は `extraModules ? []` 引数を持ちます。例えば 1 ホストだけに開発用 systemd サービスや brew 追加 cask を入れる場合:

```nix
"MacBook-Pro" = mkDarwin {
  hostname = "MacBook-Pro";
  username = "taktiks2";
  extraModules = [
    ({ ... }: {
      homebrew.casks = [ "logi-options-plus" ];
    })
  ];
};
```
```

new_string:
````
### ホスト固有モジュールを差し込みたい

`flake.nix` の `mkDarwin` は 2 種類の引数を持ちます:

- `extraModules ? []` — **darwin-level** (homebrew / system.defaults / networking 等)
- `homeExtraModules ? []` — **home-manager-level** (home.packages / programs.* / sessionVariables 等)。ファイルを作らず inline で済ませたい場合用。基本は `home/users/<username>.nix` を使う

```nix
"MacBook-Pro" = mkDarwin {
  hostname = "MacBook-Pro";
  username = "taktiks2";
  extraModules = [
    # darwin-level: ホスト限定 cask
    ({ ... }: {
      homebrew.casks = [ "logi-options-plus" ];
    })
  ];
  homeExtraModules = [
    # home-manager-level: ホスト限定 alias など (file に切り出すほどでもない時)
    ({ ... }: {
      programs.fish.shellAliases.dock = "open -a Docker";
    })
  ];
};
```
````

- [ ] **Step 8: CLAUDE.md の Architecture 表を更新**

Edit `~/dotfiles/CLAUDE.md`。

old_string:
```
| Nix (home-manager) | CLI 33 本 + Fish 4.2 + plugins + tmux | `home/taktiks2.nix` |
```

new_string:
```
| Nix (home-manager) | CLI 33 本 + Fish 4.2 + plugins + tmux | `home/common.nix` (+ `home/users/<username>.nix`) |
```

- [ ] **Step 9: CLAUDE.md の主要ファイル一覧を更新**

old_string:
```
hosts/common.nix                # 全ホスト共通: networking / system.primaryUser / programs.fish / fish 再署名 activation
home/taktiks2.nix               # home.packages / programs.{fish,tmux,direnv} / xdg.configFile / sops / activation
modules/homebrew.nix            # taps / brews / casks (cleanup = "uninstall")
```

new_string:
```
hosts/common.nix                # 全ホスト共通: networking / system.primaryUser / programs.fish / fish 再署名 activation
home/common.nix                 # home-manager 共通 baseline: home.packages / programs.{fish,tmux,direnv} / xdg.configFile / sops / activation
home/users/<username>.nix       # ユーザ個人差分 (auto-import, 任意): JAVA_HOME 等の install-specific 値
home/programs/                  # per-tool 設定: fish / git / tmux / direnv / lazygit / btop / gh-dash / terminal / cli
modules/homebrew.nix            # taps / brews / casks (cleanup = "uninstall")
```

- [ ] **Step 10: CLAUDE.md の Daily Operations 表を更新**

old_string:
```
| Nix CLI | `home/taktiks2.nix` の `home.packages` | `sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air` |
| brew formula / cask | `modules/homebrew.nix` の `brews` / `casks` / `taps` | 同上 |
| macOS 設定 | `modules/macos-defaults.nix` | 同上 |
| Fish 設定 | `home/taktiks2.nix` の `programs.fish.{shellInit, interactiveShellInit, shellAliases, plugins}` | 同上 |
| tmux 設定 | `home/taktiks2.nix` の `programs.tmux.*` | 同上 |
```

new_string:
```
| Nix CLI | `home/common.nix` の `home.packages` (個人だけなら `home/users/<username>.nix`) | `sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air` |
| brew formula / cask | `modules/homebrew.nix` の `brews` / `casks` / `taps` | 同上 |
| macOS 設定 | `modules/macos-defaults.nix` | 同上 |
| Fish 設定 | `home/programs/fish.nix` の `programs.fish.{shellInit, interactiveShellInit, shellAliases, plugins}` (個人 alias は `home/users/<username>.nix`) | 同上 |
| tmux 設定 | `home/programs/tmux.nix` の `programs.tmux.*` | 同上 |
```

- [ ] **Step 11: CLAUDE.md の「直接編集してはいけないファイル」節を更新**

old_string:
```
- `~/.config/fish/config.fish` — home-manager 生成 symlink。`programs.fish` セクションを編集
```

new_string:
```
- `~/.config/fish/config.fish` — home-manager 生成 symlink。`home/programs/fish.nix` の `programs.fish` セクションを編集
```

- [ ] **Step 12: 旧 `home/taktiks2.nix` 参照が残っていないことを確認**

Run:
```bash
cd ~/dotfiles
grep -rn 'home/taktiks2.nix' . --exclude-dir=.git --exclude-dir=docs/superpowers
```
Expected: ヒット 0 件。docs/superpowers/specs/2026-04-29-common-home-design.md には旧名が登場するが、設計の経緯として残すので除外で OK。

`docs/superpowers/specs/` 以外で言及が残っていたら Step 8-11 と同じ要領で書き換える（特に `docs/nix-bestpractice-followup.md` 等の旧 doc に痕跡があれば修正）。

- [ ] **Step 13: ドライビルド + flake check**

Run:
```bash
cd ~/dotfiles
nix flake check
sudo darwin-rebuild build --flake .#MacBook-Air
```
Expected: いずれも成功。

Run: `rm -f ~/dotfiles/result`

- [ ] **Step 14: コミット**

```bash
cd ~/dotfiles
git add install.sh README.md CLAUDE.md
# Step 12 で他 doc の修正があれば追加 git add
git status
```

確認したら:
```bash
git commit -m "$(cat <<'EOF'
docs: Phase 21 step 3 - install.sh / README / CLAUDE.md を common+users 構造へ追従

home/taktiks2.nix → home/common.nix + home/users/<username>.nix の分離に合わせ、
- install.sh final_check のヒント文 (共通 / 個人差分の編集先)
- README ディレクトリツリー / Daily Operations 表 / 「別 username の Mac 追加」節 / 「ホスト固有モジュール」節
- CLAUDE.md Architecture 表 / 主要ファイル / Daily Operations 表 / 編集禁止ファイル節
を更新。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: 実環境への適用 + smoke test

**Files:**
- なし (検証実行のみ)

- [ ] **Step 1: switch を実行して新世代を活性化**

Run: `sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Air`
Expected: 「activating system... done」で正常終了。

- [ ] **Step 2: 環境変数 smoke test**

新規 fish セッションで:
```bash
fish -i -c 'echo "JAVA_HOME=$JAVA_HOME"; echo "LANG=$LANG"; echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"'
```
Expected:
- `JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home`
- `LANG=en_US.UTF-8`
- `ANDROID_SDK_ROOT=/Users/taktiks2/Library/Android/sdk`

- [ ] **Step 3: PATH と CLI 配布の smoke test**

Run:
```bash
fish -i -c 'which rg fd jq gh'
```
Expected: いずれも `/etc/profiles/per-user/taktiks2/bin/...` 配下。

- [ ] **Step 4: xdg / claude live link の smoke test**

Run:
```bash
ls -la ~/.config/nvim ~/.claude
```
Expected: いずれも `~/dotfiles/.config/nvim` および `~/dotfiles/.claude` への symlink になっている。

- [ ] **Step 5: git config 確認**

Run:
```bash
git config --get init.defaultBranch
git config --get user.email
```
Expected:
- `init.defaultBranch` → `main`
- `user.email` → 既存の値（`~/.config/git/config.local` 由来、本リファクタで影響しないはず）

- [ ] **Step 6: ロールバック準備の確認 (失敗時の保険)**

Run: `sudo darwin-rebuild --list-generations | tail -3`
Expected: 直前の世代 (Phase 21 適用前) が一覧に残っている。万一の不具合時は `sudo darwin-rebuild --rollback` で即座に戻せる。

- [ ] **Step 7: ベースラインのクリーンアップ**

Run: `rm -rf /tmp/phase21-baseline`
Expected: 削除成功。

---

## Self-Review Notes

### Spec Coverage チェック

| Spec の要件 | 対応 task |
|---|---|
| `home/common.nix` 新規作成 | Task 1 Step 1 |
| `home/users/<username>.nix` 新規作成 | Task 2 Step 1 |
| `home/taktiks2.nix` 削除 | Task 1 Step 3 |
| `mkDarwin` に `homeExtraModules` 追加 | Task 1 Step 2 |
| `home-manager.users.${username}` を `imports` ラッパに変更 + auto-import | Task 1 Step 2 |
| JAVA_HOME を user file へ移譲 | Task 2 Step 1, 2 |
| LANG を `lib.mkDefault` でラップ | Task 2 Step 2 |
| `install.sh` のヒント文更新 | Task 3 Step 1 |
| `README.md` 更新 (ツリー / 「別 username」節 / 「ホスト固有モジュール」節 / Daily Ops 表) | Task 3 Steps 2-7 |
| `CLAUDE.md` 更新 (Architecture 表 / 主要ファイル / Daily Ops 表 / 編集禁止節) | Task 3 Steps 8-11 |
| validation: `nix flake check` / `darwin-rebuild build` | Task 1 Step 5, Task 2 Step 5, Task 3 Step 13 |
| validation: 環境変数 / PATH / symlink smoke test | Task 4 Steps 2-5 |
| risk: auto-import の optional 性検証 | Task 2 Step 4 |
| risk: 旧ファイル参照漏れ | Task 3 Step 12 (`grep` で網羅) |

### Notes

- 各コミット後に `darwin-rebuild build` で検証することで、3 commit のいずれの中間状態でも CI が通る状態を担保
- Task 4 (smoke test) は実環境への apply を含むので、commit 後の最終検証として実行
- ベースライン値 (`/tmp/phase21-baseline/`) は Task 0 で取得して全 task で参照、Task 4 Step 7 でクリーンアップ
