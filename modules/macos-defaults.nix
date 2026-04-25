{ ... }:

# macOS システム設定の宣言化（nix-darwin `system.defaults.*`）。
#
# 方針:
#   - ACTIVE     : 現在の macOS 設定をそのままコード化（適用しても挙動変化なし）
#   - OPT-IN     : 開発者向けに有効と思われるが、現在の設定とは異なる値。
#                  使うなら該当行のコメントを外す。
#   - 反映タイミング: Dock/Finder は再起動 (`killall Dock` / `killall Finder`) で即時反映、
#                  グローバル設定はログアウト→ログインで完全反映。
{
  system.defaults = {

    ## ---------- Dock ----------
    dock = {
      # ACTIVE: 自動的に隠す（現状ON）
      autohide = true;

      # ACTIVE: アイコンサイズ 44px（現状値）
      tilesize = 44;

      # OPT-IN: 「最近使ったアプリ」セクションを非表示にしてDockを整理
      # show-recents = false;

      # OPT-IN: Spaces を最近使った順に並べ替えない（順序を固定）
      # mru-spaces = false;

      # OPT-IN: ウィンドウをアプリアイコンに最小化
      # minimize-to-application = true;

      # OPT-IN: 起動アニメーションを無効化
      # launchanim = false;
    };

    ## ---------- Finder ----------
    finder = {
      # ACTIVE: ステータスバー表示（現状ON）
      ShowStatusBar = true;

      # ACTIVE: デフォルト表示をリストビュー（"Nlsv" = current）
      FXPreferredViewStyle = "Nlsv";

      # OPT-IN: 全てのファイル拡張子を表示
      # AppleShowAllExtensions = true;

      # OPT-IN: 拡張子変更時の警告を無効化
      # FXEnableExtensionChangeWarning = false;

      # OPT-IN: パスバー（パンくずリスト）を表示
      # ShowPathbar = true;

      # OPT-IN: ウィンドウタイトルにフルパスを表示
      # _FXShowPosixPathInTitle = true;

      # OPT-IN: 隠しファイルをデフォルト表示
      # AppleShowAllFiles = true;
    };

    ## ---------- グローバル（NSGlobalDomain） ----------
    NSGlobalDomain = {
      # ACTIVE: ダークモード（現状）
      AppleInterfaceStyle = "Dark";

      # OPT-IN: 全てのファイル拡張子を表示（Finder と整合）
      # AppleShowAllExtensions = true;

      # OPT-IN: 自動大文字化を無効（コード入力で邪魔）
      # NSAutomaticCapitalizationEnabled = false;

      # OPT-IN: 自動ピリオド挿入を無効（ダブルスペース→ピリオド）
      # NSAutomaticPeriodSubstitutionEnabled = false;

      # OPT-IN: 自動ダッシュ置換を無効（-- → —）
      # NSAutomaticDashSubstitutionEnabled = false;

      # OPT-IN: 自動引用符置換を無効（"" → ""）
      # NSAutomaticQuoteSubstitutionEnabled = false;

      # OPT-IN: 自動スペル修正を無効
      # NSAutomaticSpellingCorrectionEnabled = false;

      # OPT-IN: キーリピート速度を最速化（最小値 2 = 30ms）
      # KeyRepeat = 2;

      # OPT-IN: リピート開始までの遅延を最短化（最小値 15 = 250ms）
      # InitialKeyRepeat = 15;

      # OPT-IN: 新規ドキュメントを iCloud に保存しない
      # NSDocumentSaveNewDocumentsToCloud = false;
    };

    ## ---------- スクリーンショット ----------
    screencapture = {
      # ACTIVE: 保存先（現状）
      location = "~/Pictures/screenshot";

      # OPT-IN: 影なし PNG 出力
      # disable-shadow = true;
      # type = "png";
    };

    ## ---------- トラックパッド ----------
    trackpad = {
      # ACTIVE: タップでクリック OFF（現状）
      Clicking = false;

      # OPT-IN: 三本指ドラッグ
      # TrackpadThreeFingerDrag = true;
    };

    ## ---------- セキュリティ / その他 ----------
    # OPT-IN: ダウンロードファイルの隔離警告を無効化（信頼境界に注意）
    # LaunchServices.LSQuarantine = false;

    # OPT-IN: 起動音を無効化
    # startup.chime = false;
  };

  # 反映後の手動再起動（nix-darwin が `activateSettings -u` を自動実行するが、
  # Dock/Finder の表示は手動 `killall Dock; killall Finder` で確実に反映可能）。
}
