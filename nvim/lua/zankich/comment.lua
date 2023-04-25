require("Comment").setup({ mappings = false })

vim.api.nvim_set_keymap(
	"n",
	"<leader>/",
	":lua require('Comment.api').toggle.linewise.current(); vim.cmd('normal j')<CR>",
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
	"v",
	"<leader>/",
	":lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
	{ noremap = true }
)
