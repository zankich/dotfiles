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
set colorcolumn=80
"set omnifunc=syntaxcomplete#Complete

" Put all temporary files under the same directory.
set backup
set backupdir   =$HOME/.vim/tmp/backup//
set backupext   =-vimbackup
set backupskip  =
set directory   =$HOME/.vim/tmp/swap//
set updatecount =100
set updatetime  =100
set undofile
set undodir     =$HOME/.vim/tmp/undo//
set viminfo     ='100,n$HOME/.vim/tmp/info/viminfo

" exit terminal insert mode with esc
tnoremap <Esc> <C-\><C-n>
command! -nargs=* T split | terminal <args>
command! -nargs=* VT vsplit | terminal <args>

call plug#begin('~/.vim/plugged')
  Plug 'preservim/nerdtree'
  Plug 'tpope/vim-vinegar'
  Plug 'scrooloose/nerdcommenter'

  Plug 'base16-project/base16-vim'

  Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  Plug 'semanser/vim-outdated-plugins'

  Plug 'neovim/nvim-lspconfig'
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-path'
  Plug 'hrsh7th/cmp-cmdline'
  Plug 'hrsh7th/nvim-cmp'

  " For vsnip users.
  Plug 'hrsh7th/cmp-vsnip'
  Plug 'hrsh7th/vim-vsnip'

  Plug 'airblade/vim-gitgutter'
  Plug 'tpope/vim-fugitive'

  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'

  Plug 'base16-project/base16-vim'
call plug#end()

if filereadable(expand("$HOME/.config/tinted-theming/set_theme.vim"))
  let base16colorspace=256
  source $HOME/.config/tinted-theming/set_theme.vim
endif

" Set leader shortcut to a comma ','. By default it's the backslash
let mapleader = ","

" set working directory to current file
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>
nnoremap <leader>cd :lcd %:p:h<CR>:pwd<CR>

"nerdtree
nnoremap <leader>n :NERDTreeToggle<CR>
"nnoremap <C-n> :NERDTree<CR>
"nnoremap <C-t> :NERDTreeToggle<CR>
"nnoremap <C-f> :NERDTreeFind<CR>

" nerdcomenter
" Comment/uncomment lines
map <leader>/ <plug>NERDCommenterToggle

"
" nvim-cmp
"
set completeopt=menu,menuone,noselect
lua <<EOF
  -- Setup nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'vsnip' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

  -- Set configuration for specific filetype.
  cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  -- Setup lspconfig.
  local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
  -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
	local nvim_lsp = require('lspconfig')

	-- setup languages 
	-- GoLang
	nvim_lsp['gopls'].setup{
		cmd = {'gopls'},
		on_attach = on_attach,
		capabilities = capabilities,
		settings = {
			gopls = {
				experimentalPostfixCompletions = true,
				analyses = {
					unusedparams = true,
					shadow = true,
				},
				staticcheck = true,
			},
		},
		init_options = {
			usePlaceholders = true,
		}
  }
EOF

" vim-go
let g:go_autodetect_gopath = 1
let g:go_list_type = "quickfix"
let g:go_term_enabled = 1
let g:go_term_mode = "split"
let g:go_fmt_experimental = 1
let g:go_bin_path = expand('~/.vim/vim-go_bin')
let g:go_jump_to_error = 0
let g:go_imports_mode = 'gosimports'
let g:go_fmt_command = 'gosimports'

let g:go_highlight_array_whitespace_error = 1
let g:go_highlight_chan_whitespace_error = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_space_tab_error = 1
let g:go_highlight_trailing_whitespace_error = 0
let g:go_highlight_operators = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_parameters = 1
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_string_spellcheck = 1
let g:go_highlight_format_strings = 1
let g:go_highlight_variable_declarations = 1
let g:go_highlight_variable_assignments = 1

autocmd FileType go nnoremap <silent> <Leader>tf :GoTestFunc! -count=1 -v<CR>
autocmd FileType go nnoremap <silent> <Leader>t :GoTest! -count=1 -v<CR>
autocmd FileType go nnoremap <silent> <Leader>b :GoBuildTags ''<CR>

" outdated-plugins
let g:outdated_plugins_silent_mode = 1

" fzf.vim
nnoremap <silent> <Leader>fd :ProjectFiles<CR>
nnoremap <silent> <Leader>rg :RG<CR>

let g:fzf_buffers_jump = 1
if exists('$TMUX')
  let g:fzf_layout = { 'tmux': $FZF_TMUX_OPTS }
else
  let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
endif

function! BufferRootDir()
  let l:root_dir = system('git -C '.expand('%:p:h').' rev-parse --show-toplevel 2> /dev/null')[:-2]

  if v:shell_error == 0
    return l:root_dir
  endif

  return resolve(expand('%:p:h'))
endfunction

"let git_root = system('git -C '.expand('%:p:h').' rev-parse --show-toplevel 2> /dev/null')[:-2]
let rg_cmd = $RG_COMMAND.' %s -- || true'
let fd_cmd = $FZF_DEFAULT_COMMAND
let fzf_options = ['--preview', '~/.vim/plugged/fzf.vim/bin/preview.sh {}']

command! -bang ProjectFiles
  \ call fzf#run(
  \   fzf#wrap(
  \     fzf#vim#with_preview({'options': fzf_options + ['--prompt', 'fd> ','--header', BufferRootDir()], 'source': fd_cmd, 'dir': BufferRootDir()})
  \   )
  \ )

function! RipgrepFzf(query, fullscreen, rg_cmd, fzf_options, prompt)
  let initial_command = printf(a:rg_cmd, shellescape(a:query))
  let reload_command = printf(a:rg_cmd, shellescape('{q}'))
  let spec = {'options': ['--prompt', a:prompt,'--header', BufferRootDir(), '--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command] + a:fzf_options, 'dir': BufferRootDir()}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0, rg_cmd, fzf_options, "rg> ")

" use ripgrep for vimgrep
set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --follow

" vim-airline
let g:airline_powerline_fonts = 1

" vim-gitgutter
highlight! link SignColumn LineNr
