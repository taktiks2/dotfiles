local status, packer = pcall(require, "packer")
if (not status) then
  print("Packer is not installed")
  return
end

vim.cmd [[packadd packer.nvim]]

packer.startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'neovim/nvim-lspconfig'

  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'

  use 'nvim-lualine/lualine.nvim'
  use 'Mofiqul/dracula.nvim'
  use 'akinsho/bufferline.nvim'

  use 'nvim-tree/nvim-web-devicons'
  use 'nvim-tree/nvim-tree.lua'

  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-file-browser.nvim'

  use 'onsails/lspkind.nvim'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-nvim-lsp-signature-help'
  use 'hrsh7th/cmp-nvim-lua'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/cmp-buffer'

  use 'glepnir/lspsaga.nvim'
  use 'L3MON4D3/LuaSnip'

  use 'windwp/nvim-autopairs'
  use 'windwp/nvim-ts-autotag'
  use 'numToStr/Comment.nvim'
  use "lukas-reineke/indent-blankline.nvim"

  use 'lewis6991/gitsigns.nvim'
  use 'dinhhuy258/git.nvim'
  use {
    'f-person/git-blame.nvim',
    config = function() vim.g.gitblame_enabled = 0 end,
  }

  use 'yamatsum/nvim-cursorline'

  use {
    'ggandor/leap.nvim',
    config = function() require('leap').add_default_mappings() end,
  }

  use {
    "akinsho/toggleterm.nvim",
    tag = '*',
  }

  use {
    'nvim-treesitter/nvim-treesitter',
    run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
  }
  use 'virchau13/tree-sitter-astro'
  use 'HiPhish/nvim-ts-rainbow2'

  use({
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
  })

  use 'NvChad/nvim-colorizer.lua'

  use {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  }
  use {
    "zbirenbaum/copilot-cmp",
    after = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end,
  }
end)
