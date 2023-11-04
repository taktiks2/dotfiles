local status, treesitter = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

treesitter.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = true,
    disable = {},
  },
  ensure_installed = {
    "go",
    "rust",
    "prisma",
    "astro",
    "toml",
    "markdown",
    "markdown_inline",
    "fish",
    "bash",
    "c",
    "java",
    "typescript",
    "tsx",
    "python",
    "vim",
    "json",
    "yaml",
    "css",
    "html",
    "lua",
    "javascript",
  },
  autotag = {
    enable = true,
  },
  -- 一回で保存できないため、一時的にコメントアウト
  -- rainbow = {
  --   enable = true,
  -- },
}

local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
