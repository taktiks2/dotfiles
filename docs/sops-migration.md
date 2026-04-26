# sops-nix 移行ガイド (Phase 13)

`~/.config/fish/secret-env.fish` の平文トークン管理を、AGE 暗号化された
`secrets/secrets.yaml` (git tracked) + sops-nix での復号配置に切り替える手順。

## 全体像

```
secret-env.fish (平文, gitignore)
    ↓ 移行
secrets/secrets.yaml (AGE 暗号化, git tracked)
    ↓ darwin-rebuild switch
~/.config/sops-nix/secrets/<KEY>  (各キーが個別ファイルに復号)
    ↓ fish interactiveShellInit
$KEY 環境変数として設定される
```

## 手順

### 1. AGE 鍵を生成

Darwin では Apple File System Programming Guide に従い `~/Library/Application Support/sops/age/keys.txt` に置く（Mic92/sops-nix README 準拠）。

```fish
mkdir -p "$HOME/Library/Application Support/sops/age"
nix run nixpkgs#age -- -k > "$HOME/Library/Application Support/sops/age/keys.txt"
chmod 600 "$HOME/Library/Application Support/sops/age/keys.txt"
```

別端末で復号する場合は keys.txt を安全な手段で持ち運ぶ。
GitHub などにコミットすると終わるので絶対やらない。

### 2. 公開鍵を取得して `.sops.yaml` に埋める

```fish
nix run nixpkgs#age -- -y "$HOME/Library/Application Support/sops/age/keys.txt"
# 出力例: age1xxxx... を控えておく
```

`.sops.yaml` の `AGE_PUBLIC_KEY_PLACEHOLDER` を実際の `age1xxxx...` に置換。

### 3. `secrets/secrets.yaml` を新規作成して暗号化

```fish
mkdir -p ~/dotfiles/secrets
cd ~/dotfiles
nix run nixpkgs#sops -- secrets/secrets.yaml
```

エディタが起動するので、`secret-env.fish` の内容を YAML 形式で書く。例:

```yaml
GITHUB_TOKEN: ghp_xxxxxxxxxxxxxxxxxxxx
OPENAI_API_KEY: sk-xxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY: sk-ant-xxxxxxxxxxxxx
```

保存して閉じると自動暗号化される (中身を `cat` しても暗号文だけが見える)。

### 4. `home/taktiks2.nix` の `sops.secrets` にキーを登録

```nix
sops = lib.mkIf (builtins.pathExists ../secrets/secrets.yaml) {
  defaultSopsFile = ../secrets/secrets.yaml;
  # Darwin パス (Mic92/sops-nix README 準拠)
  age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
  secrets = {
    GITHUB_TOKEN     = {};
    OPENAI_API_KEY   = {};
    ANTHROPIC_API_KEY = {};
    # ... secret-env.fish に書いてあった全キーを列挙
  };
};
```

### 5. switch して動作確認

```fish
darwin-rebuild build --flake .#MacBook-Air
sudo darwin-rebuild switch --flake .#MacBook-Air

# 復号配置の確認
ls -la ~/.config/sops-nix/secrets/
# 例: GITHUB_TOKEN OPENAI_API_KEY ... が並んでいること

# 新規 fish session で環境変数チェック
exec fish
echo $GITHUB_TOKEN  # 復号値が出ること
```

### 6. 旧 `secret-env.fish` を削除

新方式が動作したら平文ファイルを消す:

```fish
rm ~/.config/fish/secret-env.fish
```

### 7. `home.activation.bootstrapSideEffects` の secret-env.fish 生成ブロックを削除

`home/taktiks2.nix` の以下を削除:

```nix
SECRET_ENV="$HOME/.config/fish/secret-env.fish"
if [ ! -f "$SECRET_ENV" ]; then
  ...
fi
```

`programs.fish.interactiveShellInit` の旧 `source ~/.config/fish/secret-env.fish` 部分も削除。

最後に再度 switch + commit。

## トラブルシューティング

- **`sops: failed to load AGE keys`** → `~/Library/Application Support/sops/age/keys.txt` のパーミッションが 600 か確認
- **`~/.config/sops-nix/secrets/` が空** → `home/taktiks2.nix` の `sops.secrets` にキーを登録し忘れ
- **`Permission denied` で switch 失敗** → `keys.txt` が user 権限で読めるか確認 (root 所有になっていないか)
- **別 Mac で復号できない** → `keys.txt` をその Mac にも配置する必要がある
