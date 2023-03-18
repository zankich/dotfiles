vim.o.autoindent = true                 
vim.o.expandtab = true                 
vim.o.softtabstop = 2                 
vim.o.tabstop = 2                    
vim.o.shiftwidth = 2                
vim.o.shiftround = true            
vim.o.hidden = true                
vim.o.laststatus = 2              
vim.o.display = "lastline"       
vim.o.showmode = true           
vim.o.showcmd = true         
vim.o.incsearch = true    
vim.o.hlsearch = true            
vim.o.ttyfast = true            
vim.o.lazyredraw = true        
vim.o.splitbelow = true       
vim.o.splitright = true      
vim.o.wrapscan = true       
vim.o.report = 0           
vim.o.synmaxcol = 200     
vim.o.encoding = "utf-8"                 
vim.o.noerrorbells = true              
vim.o.number = true                 
vim.o.ignorecase =true            
vim.o.smartcase = true           
vim.o.ttimeout = true           
vim.o.ttimeoutlen = 0          
vim.o.clipboard = "unnamedplus"
vim.o.colorcolumn = 80
vim.o.wildmenu = true
vim.o.backupdir = os.getenv("HOME") .. "/.local/state/nvim/backup//"
vim.o.directory = os.getenv("HOME") .. "/.local/state/nvim/swap//"
vim.o.undodir = os.getenv("HOME") .. "/.local/state/nvim//undo//"
vim.o.backup = true
vim.o.backupskip  = ""
vim.o.updatecount = 100
vim.o.updatetime  = 100
vim.o.undofile = true
vim.g.mapleader = ","
vim.g.mapleaderlocal = ","
