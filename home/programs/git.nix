{ lib, config, ... }:

# Phase 17: ~/.gitconfig + .config/git/ignore + lazygit pagers/git connection を programs.git / programs.delta に統合。
# Phase 19: user.{name,email} を ~/.config/git/config.local に分離（公開リポ上の平文露出を回避、
#           sops-nix 移行後はそちらに集約）。
# Phase 22: my.git.extraIdentities option を追加。各 host の per-user 設定から conditional な
#           git identity (includeIf) と SSH host alias を 1 ブロックで宣言できるようにする。
#           例: 社用 PC で「dotfiles 等 taktiks2 所有 repo だけ taktiks2 アカウントでコミット」。

let
  identities = config.my.git.extraIdentities;
  homeDir    = config.home.homeDirectory;

  hasAnySsh = lib.any (i: i.sshHostAlias != null) (lib.attrValues identities);

  identityIncludes = lib.mapAttrsToList (id: idCfg: {
    condition = idCfg.condition;
    path      = "${homeDir}/.config/git/config.${id}";
  }) identities;

  identityMatchBlocks = lib.mapAttrs'
    (id: idCfg: lib.nameValuePair idCfg.sshHostAlias {
      hostname       = idCfg.sshHostname;
      user           = "git";
      identityFile   = idCfg.sshIdentityFile;
      identitiesOnly = true;
    })
    (lib.filterAttrs (_: i: i.sshHostAlias != null) identities);
in
{
  options.my.git.extraIdentities = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        condition = lib.mkOption {
          type    = lib.types.str;
          example = "hasconfig:remote.*.url:git@github-taktiks2:taktiks2/**";
          description = ''
            git includeIf 条件。推奨は
              hasconfig:remote.*.url:git@<sshHostAlias>:<owner>/**
            （リモート URL ベース、リポを移動しても追従、git 2.36+）。
            その他: gitdir:~/path/, onbranch:foo
          '';
        };
        sshHostAlias = lib.mkOption {
          type    = lib.types.nullOr lib.types.str;
          default = null;
          example = "github-taktiks2";
          description = ''
            SSH host alias 名。指定すると programs.ssh.matchBlocks に派生する。
            null の場合は SSH 設定を生成しない（URL 振替 insteadOf 派向け）。
          '';
        };
        sshIdentityFile = lib.mkOption {
          type    = lib.types.nullOr lib.types.str;
          default = null;
          example = "~/.ssh/id_ed25519_taktiks2";
          description = "対応する SSH 秘密鍵パス。sshHostAlias 指定時は必須。";
        };
        sshHostname = lib.mkOption {
          type        = lib.types.str;
          default     = "github.com";
          description = "実接続先 (GHE 等の場合は github.example.com 等で上書き)。";
        };
      };
    });
    default     = {};
    description = ''
      conditional git identity の宣言。各 attr name `<id>` が:
        - ~/.config/git/config.<id>     (out-of-repo の include ファイル、初回 switch で雛形生成)
        - programs.git.includes に { condition; path } を 1 件追加
        - sshHostAlias 指定時は programs.ssh.matchBlocks.<alias> を生成
      にマップされる。
      identity の値 (user.name / user.email / signingkey) は config.<id> に手書きで入れる。
      公開 repo に email を露出させないための分離設計。
    '';
  };

  config = {
    programs.git = {
      enable = true;

      # 旧 .config/git/ignore (4 行) を Nix 化。
      ignores = [
        ".worktree"
        ".DS_Store"
        "**/.claude/settings.local.json"
      ];

      # 旧 ~/.gitconfig 内容を 1:1 移植。HM 25.11 で userName/userEmail/extraConfig は
      # settings に統合された (settings.user.name / settings.user.email / settings.<section>.<key>)。
      # delta 関連は programs.delta が interactive.diffFilter / pager.* / [delta] navigate
      # 等を自動で注入するため重複定義しない。
      # user.{name,email} はローカル include ファイル（後述 bootstrap）に分離。
      settings = {
        init.defaultBranch  = "main";
        core.editor         = "nvim";
        merge.conflictstyle = "diff3";
        diff.colorMoved     = "default";
        # Phase 22: identity 解決失敗時に $USER@$HOSTNAME 由来の偽 identity でコミットさせない。
        # extraIdentities の include がリモート URL 不整合等で外れた状態でのコミット試行を fail-fast に。
        # mkDefault で個別 host が必要なら無効化可。
        user.useConfigOnly  = lib.mkDefault true;
      };

      # ~/.config/git/config.local（dotfiles repo 外、git 追跡対象外）が default identity。
      # extraIdentities で宣言された conditional include を末尾に連結。
      # git は include 先が無くても無害に無視する。
      includes =
        [ { path = "${homeDir}/.config/git/config.local"; } ]
        ++ identityIncludes;
    };

    # delta 本体（HM 25.11 で programs.git.delta から programs.delta へ昇格）。
    programs.delta = {
      enable = true;
      enableGitIntegration = true;  # 25.11 以降は明示指定が必要
      options = {
        navigate     = true;
        side-by-side = true;
        line-numbers = true;
      };
    };

    # extraIdentities が 1 件以上 sshHostAlias を持つ場合のみ programs.ssh を有効化し、
    # 既存の手書き ~/.ssh/config を破壊しない（hasAnySsh = false なら無効）。
    programs.ssh = lib.mkIf hasAnySsh {
      enable      = true;
      matchBlocks = identityMatchBlocks;
    };

    # 旧 ~/.gitconfig が残っていると XDG 側 (~/.config/git/config) より優先されるため、
    # 一度だけリネームして HM に主導権を渡す。idempotent。
    home.activation.migrateLegacyGitconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
        $DRY_RUN_CMD mv "$HOME/.gitconfig" "$HOME/.gitconfig.pre-hm.bak"
        echo "moved legacy ~/.gitconfig to ~/.gitconfig.pre-hm.bak (programs.git took over via ~/.config/git/config)"
      fi
    '';

    # Phase 19: user.{name,email} を含むローカル include を bootstrap。dotfiles repo 外なので tracked にならない。
    # 既存ファイルがあれば上書きしない（ホスト毎の上書きを尊重）。
    # Phase 20: 公開リポにメールを含めないため雛形は generic な TODO 行のみ。
    #           初回 switch 後にユーザが手動で埋める運用。
    home.activation.bootstrapGitLocalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      LOCAL_CFG="$HOME/.config/git/config.local"
      if [ ! -f "$LOCAL_CFG" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$LOCAL_CFG")"
        cat > "$LOCAL_CFG" <<'EOF'
# default git identity (host-specific, out-of-repo, NOT tracked).
# user.{name,email} など、公開リポに露出させたくない値をここに記述する。
[user]
  # name  = your-name
  # email = your-email@example.com
EOF
        $DRY_RUN_CMD chmod 600 "$LOCAL_CFG"
        echo "git/config.local template created at $LOCAL_CFG (please fill user.name / user.email)"
      fi
    '';

    # Phase 22: extraIdentities 各 <id> につき ~/.config/git/config.<id> の雛形を bootstrap。
    # 既存ファイルがあれば上書きしない。
    home.activation.bootstrapGitExtraIdentities = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.concatStringsSep "\n" (lib.mapAttrsToList (id: idCfg: ''
        EXTRA_CFG="$HOME/.config/git/config.${id}"
        if [ ! -f "$EXTRA_CFG" ]; then
          $DRY_RUN_CMD mkdir -p "$(dirname "$EXTRA_CFG")"
          cat > "$EXTRA_CFG" <<'EOF'
# git identity for "${id}" (out-of-repo, NOT tracked).
# applied when: ${idCfg.condition}
[user]
  # name  = your-${id}-name
  # email = your-${id}@example.com
  # signingkey = ~/.ssh/id_ed25519_${id}.pub
EOF
          $DRY_RUN_CMD chmod 600 "$EXTRA_CFG"
          echo "git/config.${id} template created at $EXTRA_CFG (please fill user.name / user.email)"
        fi
      '') identities)
    );
  };
}
