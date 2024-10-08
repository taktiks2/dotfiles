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
    "pwntester/octo.nvim",
    config = function()
      require("octo").setup({ enable_builtin = true })
      vim.cmd([[hi OctoEditable guibg=none]])
    end,
    keys = {
      { "<leader>O", "<cmd>Octo<CR>", desc = "OCTO" },
    },
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
      { "<leader>A", "<cmd>Atac<CR>", desc = "ATAC" },
    },
  },
}
