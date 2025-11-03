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
      servers = {
        emmet_language_server = {
          filetypes = {
            "html",
            "blade",
            "css",
            "sass",
            "scss",
            "less",
            "javascript",
            "typescript",
            "markdown",
          },
        },
        phpactor = {
          filetypes = { "php", "blade" },
          init_options = {
            ["language_server_phpstan.enabled"] = true,
            ["language_server_psalm.enabled"] = false,
          },
          -- プロジェクトルートの検出パターン
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("composer.json", ".git", ".phpactor.yml")(fname)
          end,
        },
        html = {
          filetypes = { "html", "blade" },
        },
        cssls = {
          filetypes = { "css", "scss", "less", "blade" },
        },
        tailwindcss = {
          filetypes = {
            "html",
            "css",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "vue",
            "blade",
          },
        },
      },
      opts = {
        servers = {
          bashls = {},
        },
      },
    },
    "mason-org/mason.nvim",
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
        "html-lsp",
        "eslint-lsp",
        "prettier",
        "json-lsp",
        "prisma-language-server",
        "svelte-language-server",
        "phpactor",
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
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "css",
        "http",
        "markdown",
        "php",
        "php_only",
        "phpdoc",
        "rust",
        "vue",
        "blade",
      })
    end,
  },
  {
    "EmranMR/tree-sitter-blade",
    ft = "blade",
    config = function()
      vim.filetype.add({
        pattern = {
          [".*%.blade%.php"] = "blade",
        },
      })
    end,
  },
}
