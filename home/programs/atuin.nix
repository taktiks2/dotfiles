{ ... }:

# atuin: SQLite ベースのシェル履歴置き換え。cwd / 終了コード / 実行時間込みで保存し、
# Ctrl+R を全履歴横断のインタラクティブ検索に置き換える。
#
# - 同期サーバーは無効化（履歴はローカル SQLite のみに保持）。
#   将来複数 host で共有したくなったら settings.sync_address と `atuin login` を有効化する。
# - fish との shell integration は programs.fish.enable と連動して HM 側が自動 hook する
#   （HM 25.11 以降の挙動。direnv.nix のコメント参照）。

{
  programs.atuin = {
    enable = true;

    settings = {
      # 自前/公式サーバーへの同期は明示的に無効化。誤って機密コマンドを外に出さないため。
      auto_sync = false;
      update_check = false;

      # Ctrl+R の検索 UI を画面下に小さく出す（full-screen を避けて作業中の文脈を残す）。
      style = "compact";
      inline_height = 20;

      # cwd と session を加味した並び順 → 同じディレクトリで打った履歴を優先表示。
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "session";
      search_mode = "fuzzy";

      # 機密を含みうるコマンドは履歴 DB に保存しない。
      # 追加が必要になったら history_filter に正規表現を足す。
      history_filter = [
        "^ "                       # 先頭スペース付きコマンドは保存しない（bash の HISTCONTROL=ignorespace 相当）
        "^(op|aws) .*--password"
        "^echo .*(TOKEN|SECRET|API_KEY|PASSWORD)"
      ];
    };
  };
}
