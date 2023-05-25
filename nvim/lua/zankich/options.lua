vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.hidden = true
vim.opt.laststatus = 2
vim.opt.display = "lastline"
vim.opt.showmode = true
vim.opt.showcmd = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ttyfast = true
vim.opt.lazyredraw = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.wrapscan = true
vim.opt.report = 0
vim.opt.synmaxcol = 200
vim.opt.encoding = "utf-8"
-- vim.opt.noerrorbells = true
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 0
vim.opt.clipboard = "unnamedplus"
vim.opt.colorcolumn = "80"
vim.opt.wildmenu = true
vim.opt.backupdir = os.getenv("HOME") .. "/.local/state/nvim/backup//"
vim.opt.directory = os.getenv("HOME") .. "/.local/state/nvim/swap//"
vim.opt.undodir = os.getenv("HOME") .. "/.local/state/nvim//undo//"
vim.opt.backup = true
vim.opt.backupskip = ""
vim.opt.updatecount = 100
vim.opt.updatetime = 100
vim.opt.undofile = true
vim.opt.termguicolors = true
vim.g.mapleader = ","
vim.g.mapleaderlocal = ","
vim.o.timeout = true
vim.o.timeoutlen = 300

local util = require("zankich.util")
vim.api.nvim_create_autocmd("BufEnter", { command = vim.cmd.lcd(util.bufferRootDir()) })
vim.keymap.set("n", "<space>r", util.reload, { silent = true, noremap = true })

vim.keymap.set("n", "<Leader>s", ":%sno/<C-r><C-w>/<C-r><C-w>/gc<Left><Left><Left>")
vim.keymap.set("v", "<Leader>s", '"hy:%sno/<C-r>h/<C-r>h/gc<left><left><left>')
