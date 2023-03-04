local status, telescope = pcall(require, "telescope")
if (not status) then return end
local builtin = require('telescope.builtin')
local actions = require('telescope.actions')

telescope.setup({
  defaults = {
    mappings = {
      ["n"] = {
        ["q"] = actions.close
      },
    },
  },
  extensions = {
    file_browser = {
      hijack_netrw = true,
    },
  },
})

telescope.load_extension("file_browser")

vim.keymap.set('n', ';f', builtin.find_files, {})
vim.keymap.set('n', ';g', builtin.live_grep, {})
vim.keymap.set('n', ';b', builtin.buffers, {})
vim.keymap.set('n', ';h', builtin.help_tags, {})
vim.keymap.set('n', ';t', telescope.extensions.file_browser.file_browser, {})
