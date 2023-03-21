local null_ls = require("null-ls")

local sources = {
    null_ls.builtins.completion.luasnip, null_ls.builtins.completion.spell,
    null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.code_actions.shellcheck, null_ls.builtins.formatting.shfmt,
    null_ls.builtins.formatting.lua_format, null_ls.builtins.diagnostics.vint,
}

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({
    sources = sources,
    debounce = 1000,
    default_timeout = 5000,
    on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({group = augroup, buffer = bufnr})
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format({bufnr = bufnr})
                end
            })
        end
    end
})
