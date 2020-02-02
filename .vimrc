"" You want Vim, not vi. When Vim finds a vimrc, 'nocompatible' is set anyway.
" We set it explicitely to make our position clear!
set nocompatible

filetype plugin indent on          " Load plugins according to detected filetype.
syntax on                          " Enable syntax highlighting.
set autoindent                     " Indent according to previous line.
set expandtab                      " Use spaces instead of tabs.
set softtabstop =2                 " Tab key indents by 2 spaces.
set tabstop =2                     " tab indents to 2 spaces
set shiftwidth  =2                 " >> indents by 2 spaces.
set shiftround                     " >> indents to next multiple of 'shiftwidth'.
set backspace   =indent,eol,start  " Make backspace work as you would expect.
set hidden                         " Switch between buffers without having to save first.
set laststatus  =2                 " Always show statusline.
set display     =lastline          " Show as much as possible of the last line.
set showmode                       " Show current mode in command-line.
set showcmd                        " Show already typed keys when more are expected.
set incsearch                      " Highlight while searching with / or ?.
set hlsearch                       " Keep matches highlighted.
set ttyfast                        " Faster redrawing.
set lazyredraw                     " Only redraw when necessary.
set splitbelow                     " Open new windows below the current window.
set splitright                     " Open new windows right of the current window.
set wrapscan                       " Searches wrap around end-of-file.
set report      =0                 " Always report changed lines.
set synmaxcol   =200               " Only highlight the first 200 columns.
set encoding=utf-8                 " Set default encoding to UTF-8
set noerrorbells                   " No beeps
set number                         " Show line numbers
set fileformats=unix,dos,mac       " Prefer Unix over Windows over OS 9 formats
set ignorecase                     " Search case insensitive...
set smartcase                      " ... but not it begins with upper case
set ttimeout                       " nvim esc delay issues
set ttimeoutlen=0                  " nvim esc delay issues
set clipboard^=unnamed             " enable clipboard sync
set clipboard^=unnamedplus

" Put all temporary files under the same directory.
set backup
set backupdir   =$HOME/.vim/tmp/backup//
set backupext   =-vimbackup
set backupskip  =
set directory   =$HOME/.vim/tmp/swap//
set updatecount =100
set undofile
set undodir     =$HOME/.vim/tmp/undo//
set viminfo     ='100,n$HOME/.vim/tmp/info/viminfo

call plug#begin('~/.vim/plugged')
Plug 'eiginn/netrw'
Plug 'tpope/vim-vinegar'
Plug 'scrooloose/nerdcommenter'

Plug 'chriskempson/base16-vim'

Plug 'pangloss/vim-javascript'
Plug 'vim-ruby/vim-ruby'
Plug 'rust-lang/rust.vim'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

Plug 'mileszs/ack.vim'
Plug 'ctrlpvim/ctrlp.vim'

Plug 'semanser/vim-outdated-plugins'

if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
call plug#end()

set t_Co=256
let g:rehash256 = 1
if filereadable(expand("~/.vimrc_background"))
  let base16colorspace=256
  source ~/.vimrc_background
endif

" Set leader shortcut to a comma ','. By default it's the backslash
let mapleader = ","

" nerdcomenter
" Comment/uncomment lines
map <leader>/ <plug>NERDCommenterToggle
"
" deoplete
let g:deoplete#enable_at_startup = 1

" vim-go
let g:go_fmt_command = "goimports"
let g:go_autodetect_gopath = 1
let g:go_list_type = "quickfix"

let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

let g:go_term_enabled = 1
let g:go_term_mode = "split"

call deoplete#custom#option('omni_patterns', { 'go': '[^. *\t]\.\w*' })

" ack.vim
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" outdated-plugins
let g:outdated_plugins_silent_mode = 1
