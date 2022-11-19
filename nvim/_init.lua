---------------------------------------------------------------------------------
--dein.vimの設定-----------------------------------------------------------------
---------------------------------------------------------------------------------
local api = vim.api

local dein_dir = vim.fn.expand('~/.cache/dein')
local dein_repo_dir = dein_dir..'/repos/github.com/Shougo/dein.vim'

vim.o.runtimepath = dein_repo_dir..','..vim.o.runtimepath

-- dein install check
if (vim.fn.isdirectory(dein_repo_dir) == 0) then
  os.execute('git clone https://github.com/Shougo/dein.vim '..dein_repo_dir)
end

-- begin settings
if (vim.fn['dein#load_state'](dein_dir) == 1) then
  local rc_dir = vim.fn.expand('~/.config/nvim')
  local toml = rc_dir..'/dein.toml'
  vim.fn['dein#begin'](dein_dir)
  vim.fn['dein#load_toml'](toml, { lazy = 0 })
  vim.fn['dein#end']()
  vim.fn['dein#save_state']()
end

-- plugin install check
if (vim.fn['dein#check_install']() ~= 0) then
  vim.fn['dein#install']()
end

-- plugin remove check
local removed_plugins = vim.fn['dein#check_clean']()
if vim.fn.len(removed_plugins) > 0 then
  vim.fn.map(removed_plugins, "delete(v:val, 'rf')")
  vim.fn['dein#recache_runtimepath']()
end
---------------------------------------------------------------------------------
--appearance設定-----------------------------------------------------------------
---------------------------------------------------------------------------------
--ヘルプの日本語化
vim.o.helplang = 'ja,en'
--検索時に大文字・小文字の違いを無視
vim.o.ignorecase = true
--検索時に大文字がある場合は区別する
vim.o.smartcase = true
vim.o.splitright = true
vim.o.hidden = true
vim.bo.autoread = true
vim.wo.number = true
vim.wo.signcolumn = 'yes'
vim.wo.cursorline = true
vim.wo.cursorcolumn = true
vim.cmd 'set clipboard+=unnamedplus'
---------------------------------------------------------------------------------
--keymap設定---------------------------------------------------------------------
---------------------------------------------------------------------------------
