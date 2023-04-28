require("go").setup({
	gofmt = "gopls",
	goimport = "gopls",
	gopls_remote_auto = false,
	icons = { breakpoint = "x", currentpos = ">" },
	lsp_cfg = false,
	lsp_codelens = true,
	lsp_diag_virtual_text = { space = 0, prefix = "" },
	lsp_gofumpt = true,
	lsp_inlay_hints = { enable = false },
	lsp_keymaps = false,
	luasnip = false,
	null_ls_document_formatting_disable = false,
	run_in_floatterm = true,
	trouble = true,
	lsp_diag_hdlr = false,
})

-- Run gofmt + goimport on save
local format_sync_grp = vim.api.nvim_create_augroup("GoImport", {})
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.go",
	callback = function()
		require("go.format").goimport()
	end,
	group = format_sync_grp,
})
