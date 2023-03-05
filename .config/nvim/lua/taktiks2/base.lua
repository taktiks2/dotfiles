vim.cmd("autocmd!")

local opt = vim.opt

opt.encoding = 'utf-8'
opt.number = true
opt.title = true

opt.autoindent = true
opt.smartindent = true
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.wrapscan = true

opt.list = true

opt.showmatch = true

opt.mouse = 'a'

opt.swapfile = false

opt.splitbelow = true
opt.splitright = true

opt.shell = 'fish'
