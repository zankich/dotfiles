require("go").setup({
	lsp_inlay_hints = { enable = false },
	icons = { breakpoint = "x", currentpos = ">" },
	lsp_diag_virtual_text = { space = 0, prefix = "" },
	luasnip = true,
	goimport = "gopls",
	gofmt = "gopls",
	lsp_keymaps = false,
	lsp_gofumpt = true,
	lsp_cfg = { settings = { gopls = { ["local"] = "stash.corp.netflix.com" } } },
	run_in_floatterm = true,
	null_ls_document_formatting_disable = false,
	trouble = true,
	gopls_remote_auto = false,
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

-- require("go.format").gofmt()
-- require("go.format").goimport()

-- vim.cmd('autocmd BufWritePre (InsertLeave?) <buffer> lua vim.lsp.buf.formatting_sync(nil,500)')

-- vim.api.nvim_exec(
--     [[ autocmd BufWritePre *.go :silent! lua vim.lsp.buf.formatting_sync(nil,500) ]],
--     false)
-- -- Run gofmt + goimport on save
-- local format_sync_grp = vim.api.nvim_create_augroup("GoImport", {})
-- vim.api.nvim_create_autocmd("BufWritePre", {
--     pattern = "*.go",
--     callback = function() require('go.format').goimport() end,
--     group = format_sync_grp
-- })
