vim.cmd("autocmd!")

vim.g.mapleader = ' '

local keymap = vim.keymap

keymap.set('v', '<C-j>', '<esc>')
keymap.set('i', '<C-j>', '<esc>')
keymap.set('i', '<C-l>', '<right>')

keymap.set('n', '<C-w><left>', '<C-w><')
keymap.set('n', '<C-w><right>', '<C-w>>')
keymap.set('n', '<C-w><up>', '<C-w>+')
keymap.set('n', '<C-w><down>', '<C-w>-')

keymap.set('n', '<F1>', ':NvimTreeToggle<CR>')
keymap.set('n', '<F2>', ':GitBlameToggle<CR>')
keymap.set('n', '<F3>', ':GitBlameOpenCommitURL<CR>')
keymap.set('n', '<F4>', ':MarkdownPreview<CR>')
keymap.set('n', '<F5>', ':MarkdownPreviewStop<CR>')
keymap.set('n', '<F6>', ':mksession! ~/.config/nvim/Session.vim<CR>')
keymap.set('n', '<F7>', ':source ~/.config/nvim/Session.vim<CR>')
keymap.set('n', '<F8>', ':Maison<CR>')
keymap.set('n', '<F9>', ':PackerSync<CR>')
