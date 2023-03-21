require('go').setup({
    lsp_inlay_hints = {enable = false},
    icons = {breakpoint = 'x', currentpos = '>'},
    lsp_diag_virtual_text = {space = 0, prefix = ''},
    luasnip = true,
    lsp_config = false
})

-- Run gofmt + goimport on save
local format_sync_grp = vim.api.nvim_create_augroup("GoImport", {})
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function() require('go.format').goimport() end,
    group = format_sync_grp
})
