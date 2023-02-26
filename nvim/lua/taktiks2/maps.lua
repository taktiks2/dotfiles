vim.cmd("autocmd!")

local keymap = vim.keymap

keymap.set('v', '<C-j>', '<esc>')
keymap.set('i', '<C-j>', '<esc>')
keymap.set('i', '<C-l>', '<right>')

keymap.set('n', '<C-w><left>', '<C-w><')
keymap.set('n', '<C-w><right>', '<C-w>>')
keymap.set('n', '<C-w><up>', '<C-w>+')
keymap.set('n', '<C-w><down>', '<C-w>-')

keymap.set('n', '<F1>', ':mksession! ~/.config/nvim/Session.vim<CR>')
keymap.set('n', '<F2>', ':source ~/.config/nvim/Session.vim<CR>')
keymap.set('n', '<F3>', ':Maison')
keymap.set('n', '<F4>', ':vsplit ~/.config/nvim/lua/taktiks2/base.lua<CR>')
keymap.set('n', '<F5>', ':vsplit ~/.config/nvim/lua/taktiks2/maps.lua<CR>')
keymap.set('n', '<F6>', ':vsplit ~/.config/nvim/lua/taktiks2/plugins.lua<CR>')
