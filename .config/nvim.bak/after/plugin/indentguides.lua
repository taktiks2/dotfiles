local status, indent = pcall(require, "ibl")
if (not status) then return end

vim.opt.list = true
vim.opt.listchars:append "space:⋅"
vim.opt.listchars:append "eol:↴"

indent.setup()
