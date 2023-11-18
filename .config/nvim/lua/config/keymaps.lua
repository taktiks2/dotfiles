-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local discipline = require("taktiks2.discipline")

discipline.cowboy()

local keymap = vim.keymap

keymap.set("v", "<C-j>", "<esc>")
keymap.set("i", "<C-j>", "<esc>")
keymap.set("i", "<C-l>", "<right>")

keymap.set("n", "<Right>", "4<C-w>>")
keymap.set("n", "<Left>", "4<C-w><")
keymap.set("n", "<Up>", "4<C-w>+")
keymap.set("n", "<Down>", "4<C-w>-")

-- keymap.set("n", "<F1>", ":NvimTreeToggle<CR>")
-- keymap.set("n", "<F2>", ":TSJToggle<CR>")
-- keymap.set("n", "<F3>", ":GitBlameToggle<CR>")
-- keymap.set("n", "<F4>", ":GitBlameOpenCommitURL<CR>")
-- keymap.set("n", "<F5>", ":MarkdownPreview<CR>")
-- keymap.set("n", "<F6>", ":MarkdownPreviewStop<CR>")
-- keymap.set("n", "<F7>", ":LiveServer<CR>")
