-- Octo.nvim override
-- LazyVim extras/util/octo が pwntester/octo.nvim を既に有効化しているため、
-- ここでは picker の強制指定と PR レビュー用キーマップのみを追加する。
-- LazyVim 側の picker 自動判定は editor.telescope / editor.fzf / editor.snacks_picker
-- のいずれかの extra が必要だが、現状どれも未有効なので fzf-lua を明示する。
return {
  {
    "pwntester/octo.nvim",
    opts = function(_, opts)
      opts.picker = "fzf-lua"
      -- マージ時のデフォルト方式（プロジェクト方針に合わせる）
      opts.default_merge_method = "squash"
      -- gh dash と組み合わせるため、左サイドバーは閉じてもよい
      opts.suppress_missing_scope = { projects_v2 = true }
    end,
    keys = {
      -- レビュー
      { "<leader>ov", "<cmd>Octo review start<cr>", desc = "Start PR Review (Octo)" },
      { "<leader>oV", "<cmd>Octo review resume<cr>", desc = "Resume PR Review (Octo)" },
      -- PR 操作
      { "<leader>opl", "<cmd>Octo pr list<cr>", desc = "List PRs (Octo)" },
      { "<leader>ops", "<cmd>Octo pr search<cr>", desc = "Search PRs (Octo)" },
      { "<leader>opc", "<cmd>Octo pr checkout<cr>", desc = "Checkout PR (Octo)" },
      { "<leader>opr", "<cmd>Octo pr ready<cr>", desc = "Mark PR Ready (Octo)" },
      { "<leader>opm", "<cmd>Octo pr merge squash delete<cr>", desc = "Squash & Delete (Octo)" },
      { "<leader>opx", "<cmd>Octo pr checks<cr>", desc = "PR Checks (Octo)" },
      { "<leader>opd", "<cmd>Octo pr diff<cr>", desc = "PR Diff (Octo)" },
      -- Issue / 通知 / トップ
      { "<leader>oi", "<cmd>Octo issue list<cr>", desc = "List Issues (Octo)" },
      { "<leader>on", "<cmd>Octo notification list<cr>", desc = "List Notifications (Octo)" },
      { "<leader>oo", "<cmd>Octo<cr>", desc = "Octo Actions" },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>o", group = "octo" },
        { "<leader>op", group = "pr" },
      },
    },
  },
}
