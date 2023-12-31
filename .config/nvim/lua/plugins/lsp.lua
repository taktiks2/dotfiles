return {
  {
    {
      "neovim/nvim-lspconfig",
      init_options = {
        userLanguages = {
          eelixir = "html-eex",
          eruby = "erb",
          rust = "html",
        },
      },
      opts = {
        servers = {
          bashls = {},
        },
      },
    },
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "bashls",
        "stylua",
        "selene",
        "shellcheck",
        "shfmt",
        "rust-analyzer",
        "tailwindcss-language-server",
        "typescript-language-server",
        "css-lsp",
        "eslint-lsp",
        "prettier",
        "json-lsp",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "go",
        "rust",
        "prisma",
        "toml",
        "fish",
        "c",
        "java",
        "css",
      },
    },
  },
}
