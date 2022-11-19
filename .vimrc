"==============================================================================
" dein.vim settings {{{
"==============================================================================
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
" vim-plug
call plug#begin('~/.vim/plugged')
Plug 'turbio/bracey.vim', {'do': 'npm install --prefix server'}
call plug#end()
"==============================================================================
" setting
"==============================================================================
" 文字コードutf-8
set fenc=utf-8

" バックアップファイルを作らない
set nobackup

" 入力中のコマンドをステータスに表示
set showcmd

" スワップファイルを作らない
set noswapfile

" インデントを考慮して改行
set smartindent

" オートインデント文字数
set shiftwidth=2

" tab文字数
set tabstop=2

autocmd FileType python setl ts=4
" tabをスペースに展開する
autocmd FileType python setl expandtab

" Undoの永続化
if has('persistent_undo')
  let undo_path = expand('~/.vim/undo')
  " ディレクトリーが存在しない場合は作成
  if !isdirectory(undo_path)
    call mkdir(undo_path,'p')
  endif
  let &undodir = undo_path
  set undofile
endif

" 無名レジスタとクリップボードレジスタを同期
set clipboard+=unnamedplus

" テキストのない部分を矩形選択可能にする
set virtualedit=block

" spellチェック
set nospell

"fcitx vi協調モード
"##### auto fcitx  ###########
let g:input_toggle = 1
function! Fcitx2en()
   let s:input_status = system("fcitx-remote")
   if s:input_status == 2
      let g:input_toggle = 1
      let l:a = system("fcitx-remote -c")
   endif
endfunction

set ttimeoutlen=150
" Leave Insert mode
autocmd InsertLeave * call Fcitx2en()
"##### auto fcitx end ######

" matchit.vimの導入
set nocompatible
filetype plugin on
runtime macros/matchit.vim
"==============================================================================
" appearance
"==============================================================================
" 行番号表示
set number

" カーソル位置を表示
set ruler

" /文字検索
set incsearch

" 検索文字ハイライト
set hlsearch

" 大文字・小文字の区別しない
set ignorecase

" 大文字を入力した場合、大文字・小文字を区別する
set smartcase

" 現在の行を強調表示
set cursorline
set cursorcolumn

" 括弧入力時に補完
set showmatch

" syntaxハイライトの有効化
syntax enable

" 空白文字を可視化
set listchars=tab:>-,trail:_
set list

" ヘルプ日本語化
set helplang=ja

" タブラインを常に表示
set showtabline=2

" コマンドラインでの入力補完
set wildmenu

" カラースキーム
colorscheme dracula

" 白源フォント GUI設定
" set guifont=HackGenNerd:h16
" set printfont=HackGenNerd:h12
set ambiwidth=double

" terminalモードの色付け
set termguicolors

"==============================================================================
" keymap
"==============================================================================
" python自動実行
nmap <F5> :!python %
" Fern-drawer起動
nmap <F2> :Fern-drawer .<CR>
" ALEのトグル
nmap <F3> :ALEToggle<CR>
" Bracey起動
nmap <F4> :Bracey<CR>
" .vimrcを編集
nmap <F6> :edit $MYVIMRC<CR>
".vim/dein.tomlを編集
nmap <F7> :edit ~/.vim/dein.toml<CR>
" .vimrcを読み込み
nmap <F8> :source $MYVIMRC<CR>
" escを使いやすくする
noremap <C-j> <esc>
noremap! <C-j> <esc>
" 挿入モード中に右へ移動する
inoremap ^L ^[la
inoremap <C-l> <Right>
