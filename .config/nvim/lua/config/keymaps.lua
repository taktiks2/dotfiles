-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local discipline = require("taktiks2.discipline")
require("taktiks2.cmp_toggle")

discipline.cowboy()

local keymap = vim.keymap

keymap.set("v", "<C-j>", "<esc>")
keymap.set("i", "<C-j>", "<esc>")
keymap.set("i", "<C-l>", "<right>")

keymap.set("n", "<Right>", "4<C-w>>")
keymap.set("n", "<Left>", "4<C-w><")
keymap.set("n", "<Up>", "4<C-w>+")
keymap.set("n", "<Down>", "4<C-w>-")

keymap.set("n", "<F1>", "<cmd>:GitBlameToggle<CR>")
keymap.set("n", "<F2>", "<cmd>:GitBlameOpenCommitURL<CR>")
keymap.set("n", "<F3>", "<cmd>:MarkdownPreview<CR>")
keymap.set("n", "<F4>", "<cmd>:MarkdownPreviewStop<CR>")
keymap.set("n", "<F5>", "<cmd>:CmpToggle<CR>")
