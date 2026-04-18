-- diffview.nvim
-- octo.nvim の内部依存だが、push 前のローカル差分確認用に
-- 直接コマンド/キーマップを引き出して使う。
return {
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    keys = {
      -- PR 相当: 共通祖先から HEAD まで（GitHub の PR diff と同じ三点）
      { "<leader>od", "<cmd>DiffviewOpen origin/main...HEAD<cr>", desc = "Diff vs main (PR view)" },
      -- 作業ツリー（未コミット変更）
      { "<leader>oD", "<cmd>DiffviewOpen<cr>", desc = "Diff working tree" },
      -- 開いているファイルの Git 履歴
      { "<leader>oh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current)" },
      -- ブランチ全体のコミット履歴
      { "<leader>oH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch history" },
      -- 閉じる
      { "<leader>oq", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>od", desc = "diff vs main" },
        { "<leader>oD", desc = "diff working tree" },
        { "<leader>oh", desc = "file history" },
        { "<leader>oH", desc = "branch history" },
        { "<leader>oq", desc = "close diffview" },
      },
    },
  },
}
