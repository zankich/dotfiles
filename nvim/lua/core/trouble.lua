require("trouble").setup({})

vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = false,
    update_in_insert = false,
    severity_sort = true
})

-- vim.cmd [[autocmd! CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false, scope="cursor"})]]
-- You will likely want to reduce updatetime which affects CursorHold
-- note: this setting is global and should be set only once
-- vim.o.updatetime = 250
-- vim.cmd [[autocmd! CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]
