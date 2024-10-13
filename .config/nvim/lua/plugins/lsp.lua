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
        "hadolint",
        "stylua",
        "selene",
        "shellcheck",
        "shfmt",
        "rust-analyzer",
        "pyright",
        "tailwindcss-language-server",
        "typescript-language-server",
        "css-lsp",
        "eslint-lsp",
        "prettier",
        "json-lsp",
        "prisma-language-server",
        "svelte-language-server",
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
        "dockerfile",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "go",
        "rust",
        "prisma",
        "ninja",
        "python",
        "rst",
        "toml",
        "fish",
        "c",
        "css",
        "prisma",
        "svelte",
        "commonlisp",
      },
    },
  },
  {
    "nvimtools/none-ls.nvim",
    dependencies = { {
      "davidmh/cspell.nvim",
    } },
    event = "BufReadPre",
    opts = function()
      local cspell = require("cspell")
      local config = {
        cspell_config_dirs = { "~/.config/cspell" },
      }
      local sources = {
        cspell.diagnostics.with({
          config = config,
          diagnostics_postprocess = function(diagnostic)
            diagnostic.severity = vim.diagnostic.severity["HINT"]
          end,
        }),
        cspell.code_actions.with({ config = config }),
      }
      return {
        sources = sources,
        debounce = 200,
      }
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.preselect = cmp.PreselectMode.None
      opts.completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      }
      opts.mapping = cmp.mapping.preset.insert(vim.tbl_extend("force", opts.mapping, {
        ["<CR>"] = cmp.mapping.confirm({ select = false }), -- 'select = false' to only confirm explicitly selected item
      }))
      cmp.register_source("buffer", require("cmp_buffer"))
      cmp.register_source("path", require("cmp_path"))
      require("cmp_nvim_lsp").setup()
      -- for lisp
      cmp.setup.filetype({ "lisp" }, {
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "copilot" },
          { name = "nvlime" },
          { name = "nvim_lua" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
}
