"==============================================================================
" dein.vim settings {{{
" install dir {{{
let s:dein_dir = expand('~/.cache/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'
" }}}

" dein installation check {{{
if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . s:dein_repo_dir
endif
" }}}

" begin settings {{{
if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  " .toml file
  let s:rc_dir = expand('~/.vim')
  if !isdirectory(s:rc_dir)
    call mkdir(s:rc_dir, 'p')
  endif
  let s:toml = s:rc_dir . '/dein.toml'

  " read toml and cache
  call dein#load_toml(s:toml, {'lazy': 0})

  " end settings
  call dein#end()
  call dein#save_state()
endif
" }}}

" plugin installation check {{{
if dein#check_install()
  call dein#install()
endif
" }}}

" plugin remove check {{{
let s:removed_plugins = dein#check_clean()
if len(s:removed_plugins) > 0
  call map(s:removed_plugins, "delete(v:val, 'rf')")
  call dein#recache_runtimepath()
endif
" }}}
"==============================================================================
"neosnippet Scripts-----------------------------
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)
imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
      \ "\<Plug>(neosnippet_expand_or_jump)"
      \: pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
      \ "\<Plug>(neosnippet_expand_or_jump)"
      \: "\<TAB>"
if has('conceal')
  set conceallevel=2 concealcursor=i
endif
let g:neosnippet#snippets_directory = '~/.vim/snippets/'
"==============================================================================
"fer-preview setup
function! s:fern_settings() abort
  nmap <silent> <buffer> p     <Plug>(fern-action-preview:toggle)
  nmap <silent> <buffer> <C-p> <Plug>(fern-action-preview:auto:toggle)
  nmap <silent> <buffer> <C-d> <Plug>(fern-action-preview:scroll:down:half)
  nmap <silent> <buffer> <C-u> <Plug>(fern-action-preview:scroll:up:half)
endfunction

augroup fern-settings
  autocmd!
  autocmd FileType fern call s:fern_settings()
augroup END
"==============================================================================
"vim-go setup
let g:go_highlight_array_whitespace_error = 1
let g:go_highlight_chan_whitespace_error = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_space_tab_error = 1
let g:go_highlight_trailing_whitespace_error = 1
let g:go_highlight_operators = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_arguments = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_variable_assignments = 1
let g:go_highlight_variable_declarations = 1
"==============================================================================
"c/c++補完
let g:clang_auto = 0
let g:clang_complete_auto = 0
let g:clang_auto_select = 0
let g:clang_use_library = 1
let g:clang_c_completeopt   = 'menuone'
let g:clang_cpp_completeopt = 'menuone'
let g:clang_exec = 'clang'
let g:clang_format_exec = 'clang-format'
let g:clang_c_options = '-std=c11'
let g:clang_cpp_options = '-std=c++1z -stdlib=libc++ -pedantic-errors'
"==============================================================================
"リンタ w0rp/sle
let g:ale_sign_column_always = 1
let g:ale_lint_on_enter = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_open_list = 1
let g:ale_keep_list_window_open = 0
let g:ale_sign_error = 'E'
let g:ale_sign_warning = 'W'
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %code: %%s [%severity%]'
let g:ale_disable_lsp = 1
let g:ale_linters = {
\   'javascript': ['eslint'],
\   'python': ['flake8'],
\	'c': ['clang'],
\	'cpp': ['clang']
\}
"==============================================================================
" setting
" 文字コードutf-8
set fenc=utf-8

" バックアップファイルを作らない
set nobackup

" 入力中のコマンドをステータスに表示
set showcmd

" スワップファイルを作らない
set noswapfile

" オートインデント文字数
set shiftwidth=4

" tab文字数
set tabstop=4


"==============================================================================
" appearance
" 行番号表示
set number

" カーソル位置を表示
set ruler

" /文字検索
set incsearch

" 検索文字ハイライト
set hlsearch

" 現在の行を強調表示
" set cursorline

" 括弧入力時に補完
set showmatch

" syntaxハイライトの有効化
syntax enable

" 空白文字を可視化
set listchars=eol:$,tab:>.,trail:_
set list

"==============================================================================
" keymap
" python自動実行
nmap <F5> :!python %

" jedi-vim docstring 表示しない
autocmd FileType python setlocal completeopt-=preview
