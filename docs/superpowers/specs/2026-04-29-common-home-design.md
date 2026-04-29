# Phase 21: home/common.nix + home/users/&lt;username&gt;.nix への分離

**Date:** 2026-04-29
**Status:** Approved (design)
**Scope:** home-manager 構成のリファクタリング（multi-user 対応）

## Goal

`home/taktiks2.nix` を **user-agnostic な `home/common.nix`** と **user-specific な `home/users/<username>.nix`** に分離し、会社配布 PC など別 username の Mac をクリーンに追加できるようにする。

## Non-Goals

- darwin-level (`modules/homebrew.nix` / `modules/macos-defaults.nix`) の multi-user 対応 — 既に `flake.nix` の `extraModules` で吸収可能
- `home/programs/*.nix` (per-tool 設定) の構造変更 — 現状の per-tool 分割を維持
- 同一 PC 内の git 複数 identity 対応 — `programs.git.includes` で個別解決（本 spec の対象外）
- fork 利用（他人がこの repo をベースに別 dotfiles を組む）— 自分の別アカウント運用にスコープを絞る

## Background

現状の制約:
- `home/taktiks2.nix` は username が固定で、別 username の Mac を追加するには丸ごとコピーが必要
- README には「`cp home/taktiks2.nix home/foo.nix`」というコピー運用が書かれており、ベースライン更新時に複数ファイルへ追従する必要がある
- 会社配布 PC は username が会社規定で固定されることが多く、taktiks2 と必ずしも揃えられない

ユーザの要望:
- 会社 PC でこの dotfiles を使えるようにしたい
- 将来的に同一 PC 内の git 複数アカウント管理もしたい（これは別レイヤで解決）
- ファイル単位 (B) で user 差分を切り出したい

## Design

### ディレクトリ構造

```
home/
├── common.nix                  # 全ユーザ共通の baseline (旧 home/taktiks2.nix の中身から install-specific を抜いたもの)
├── users/                      # ユーザ単位の個人差分（任意）
│   └── taktiks2.nix            # taktiks2 の個人差分
└── programs/                   # per-tool 設定（既存、無修正）
    ├── direnv.nix
    ├── fish.nix
    └── ...
```

### `flake.nix` mkDarwin 拡張

```nix
mkDarwin =
  { hostname
  , username
  , dotfilesRoot ? "/Users/${username}/dotfiles"
  , system ? "aarch64-darwin"
  , extraModules ? [ ]            # 既存: darwin-level
  , homeExtraModules ? [ ]        # 新規: home-manager-level の inline 用 escape hatch
  }:
  let
    userFile = ./home/users + "/${username}.nix";
  in
  nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = { inherit inputs username hostname dotfilesRoot; };
    modules = [
      determinate.darwinModules.default
      ({ ... }: { determinateNix.enable = true; })
      ./hosts/common.nix
      home-manager.darwinModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = { inherit username dotfilesRoot; };
        home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
        home-manager.users.${username} = { lib, ... }: {
          imports =
            [ ./home/common.nix ]
            ++ lib.optional (builtins.pathExists userFile) userFile
            ++ homeExtraModules;
        };
      }
      # ... 既存 nixpkgs config / overlays ...
    ] ++ extraModules;
  };
```

**設計判断**:
- `home/users/<username>.nix` は **存在すれば自動 import**（optional）。新規ユーザは「ファイル作らない選択」も「個人差分だけ書く」も両方できる
- `homeExtraModules` は host 固有の one-off 用（ファイルを増やしたくない場合の escape hatch）
- 順序: `common → users/<username> → homeExtraModules`。後勝ちで override 可能
- `import ./home/${username}.nix` 直渡しではなく `imports = [...]` ラッパに変更することで、自動 import + 引数注入を両立

### `home/common.nix` の責務

旧 `home/taktiks2.nix` から **install-specific な hard-coded path** だけ抜いた中身。具体的には:

- imports（`./programs/*.nix`）
- `home.stateVersion`
- `programs.home-manager.enable`
- sops 設定（`defaultSopsFile` / `age.keyFile` ともに generic）
- `home.sessionPath` — 全部 `$HOME` ベースで generic
- `home.sessionVariables` — JAVA_HOME を **除いた** 残り（ANDROID_SDK_ROOT, ATAC_*, GH_PAGER, VIRTUAL_ENV_DISABLE_PROMPT, LANG, DYLD_LIBRARY_PATH, RBENV_SHELL）
- `home.packages` — generic CLI バンドル全部（sbcl/zig など趣味系も harmless なので残す）
- `xdg.configFile` — generic（`dotfilesRoot` ベース）
- `home.file.".claude"` — generic
- `home.activation.bootstrapSideEffects` — generic（secret-env.fish テンプレ生成）

### `home/users/taktiks2.nix` の責務（最小スタート）

```nix
{ lib, config, ... }:
{
  # 個人 install 環境の hard-coded path
  home.sessionVariables.JAVA_HOME =
    "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home";
}
```

将来追加候補（YAGNI のため初期は最小）:
- 個人用追加 packages
- 個人 alias
- 個人 git identity（`programs.git.includes` の gitdir 条件）

### `lib.mkDefault` 戦略

「**list/set は何もしない、scalar で上書き頻度が高いものだけ mkDefault**」の方針。

| 値 | 扱い | 理由 |
|---|---|---|
| `home.sessionVariables.JAVA_HOME` | common から削除し user 側へ | install path に強く依存。デフォルト無し方針 |
| `home.sessionVariables.LANG` | mkDefault (common 側) | ロケール変更があり得る |
| その他 sessionVariables | そのまま | 上書き不要 or `lib.mkForce` で対応 |
| `home.packages` (list) | そのまま | HM が concat。追加方向は何もしなくて OK |
| `programs.fish.shellAliases` (set) | そのまま | HM が merge。同名上書きだけ `lib.mkForce` |

### 会社 PC 用の典型運用

```nix
# flake.nix の darwinConfigurations
"Company-MBP" = mkDarwin {
  hostname = "Company-MBP";
  username = "firstname.lastname";
  # → home/users/firstname.lastname.nix を作って差分を書く（自動 import される）
};
```

`home/users/firstname.lastname.nix`:
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

darwin-level 差分（cask 追加など）は従来どおり `extraModules`、home-manager-level 差分は `home/users/<username>.nix`。完全に直交して使い分け可能。

## Affected Files

| 場所 | 変更内容 |
|---|---|
| `home/taktiks2.nix` | 削除（中身は `home/common.nix` と `home/users/taktiks2.nix` に分離） |
| `home/common.nix` | 新規（旧 `home/taktiks2.nix` から JAVA_HOME を抜いた内容、LANG を `mkDefault` でラップ） |
| `home/users/taktiks2.nix` | 新規（JAVA_HOME のみ） |
| `flake.nix` | `mkDarwin` シグネチャに `homeExtraModules ? [ ]` 追加、`home-manager.users.${username}` を `imports` ラッパに変更、auto-import ロジック追加 |
| `install.sh` | final_check のヒント文を「共通: `home/common.nix`、個人差分: `home/users/<username>.nix`」に更新 |
| `README.md` | ディレクトリツリー / 「別 username の Mac を追加する」節 / 「ホスト固有モジュール」節 / Daily Operations 表の編集ファイルパス |
| `CLAUDE.md` | Architecture 表 / Daily Operations 表 / 主要ファイル一覧 |
| `.github/workflows/nix-check.yml` | 影響なし（host attribute 単位の build 検証） |

## Validation

1. `nix flake check` が pass
2. `sudo darwin-rebuild build --flake .#MacBook-Air` が pass
3. `nix store diff-closures /run/current-system ./result` で挙動差分が **無い** ことを確認（リファクタリングのため closure は同一になるはず）
4. `sudo darwin-rebuild switch --flake .#MacBook-Air` 適用後、以下が壊れていないこと:
   - `echo $JAVA_HOME` → zulu-17 path
   - `echo $LANG` → en_US.UTF-8
   - `which rg` → Nix profile 配下
   - `cat ~/.config/git/config` に user.{name,email} 以外の設定が反映
   - `ls -la ~/.claude` → dotfiles 配下への symlink
5. `home/users/taktiks2.nix` を一時的に削除した状態で build できることを確認（auto-import の optional 性検証）

## Risks & Mitigations

| リスク | 緩和策 |
|---|---|
| auto-import の `pathExists` が evaluation 順序で意図せず false 化 | `builtins.pathExists` は purely 評価される。flake が tracked file を参照する限り問題なし。git untracked の user file は `git add` 必須（README に明記） |
| ベースライン更新時に user file 側の override が壊れる | `lib.mkDefault` の付け忘れによる conflict は CI の `nix flake check` で検出。新規上書き対象は `mkDefault` 化を PR レビューで明示 |
| 旧 `home/taktiks2.nix` 参照が install ログ等に残存 | `install.sh` / README / CLAUDE.md を本 spec で全更新。`grep -r 'home/taktiks2.nix'` で漏れチェック |
| `dotfilesRoot` から見た import の相対パス変更 | `flake.nix` 内の `./home/...` は変更後も flake root 起点で安定。home-manager 内部の `import ../secrets/...` 等は影響なし |

## Migration Path

リファクタリング 1 PR で完結:
1. `home/common.nix` 新規作成（`home/taktiks2.nix` から JAVA_HOME を抜いた内容、LANG を `mkDefault` 化）
2. `home/users/taktiks2.nix` 新規作成（JAVA_HOME のみ）
3. `home/taktiks2.nix` 削除
4. `flake.nix` 改修
5. ドキュメント更新（README / CLAUDE.md / install.sh）
6. `nix flake check` + `darwin-rebuild build` で検証
7. ローカルで `darwin-rebuild switch` 適用、validation 全項目確認
8. commit & push、CI green を確認

## Future Work

- `home/users/<username>.nix` が育ったら、`programs.fish.shellAliases.{sls, wm}` 等の opinionated alias を common から user 側へ段階的に移管検討
- 同 username で複数 host の差分が出てきたら `home/hosts/<hostname>.nix` パターン追加（C パターンへの後退オプション）
- darwin-level (`modules/homebrew.nix`) も brew 嗜好を multi-user 対応する場合は別 spec
