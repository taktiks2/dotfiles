return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
  {
    "f-person/git-blame.nvim",
    opts = function()
      vim.g.gitblame_enabled = 0
    end,
  },
  {
    "ruifm/gitlinker.nvim",
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("gitlinker").setup()
    end,
  },
  {
    "NachoNievaG/atac.nvim",
    dependencies = { "akinsho/toggleterm.nvim" },
    config = function()
      require("atac").setup({
        dir = "~/.config/atac",
      })
    end,
    keys = {
      { "<leader>A", "<cmd>Atac<CR>", desc = "Atac" },
    },
  },
  {
    "sindrets/diffview.nvim",
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diffview" },
      { "<leader>gD", "<cmd>DiffviewFileHistory<CR>", desc = "DiffviewFileHistory" },
      { "<leader>gC", "<cmd>DiffviewClose<CR>", desc = "DiffviewClose" },
    },
  },
}
