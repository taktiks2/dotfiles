local keymap = vim.keymap
keymap.set('v', '<C-j>', '<esc>')
keymap.set('i', '<C-j>', '<esc>')
keymap.set('i', '<C-l>', '<right>')

keymap.set('n', '<C-w><left>', '<C-w><')
keymap.set('n', '<C-w><right>', '<C-w>>')
keymap.set('n', '<C-w><up>', '<C-w>+')
keymap.set('n', '<C-w><down>', '<C-w>-')

