local null_ls = require("null-ls")

local sources = {
    null_ls.builtins.completion.luasnip, null_ls.builtins.completion.spell,
    null_ls.builtins.code_actions.shellcheck,
    null_ls.builtins.code_actions.gitsigns,
    null_ls.builtins.formatting.prettier, null_ls.builtins.formatting.taplo,
    null_ls.builtins.formatting.shfmt.with({
        extra_args = {"--binary-next-line", "--case-indent", "--indent", "2"}
    }), null_ls.builtins.formatting.lua_format,
    null_ls.builtins.diagnostics.golangci_lint,
    -- null_ls.builtins.diagnostics.golangci_lint.with({
    --     extra_args = {"--enable-all"}
    -- }), -- null_ls.builtins.diagnostics.shellcheck.with({
    --     -- args = {"--check-sourced", "--severity=style", "--enable=all", "--format", "json1", "--source-path=$DIRNAME", "--external-sources", "-"}
    --     extra_args = {"--check-sourced", "--severity=style", "--enable=all"}
    -- }), null_ls.builtins.diagnostics.vint,
    null_ls.builtins.diagnostics.markdownlint_cli2.with({
        condition = function(utils)
            return utils.root_has_file({".markdownlint-cli2.jsonc"})
        end
    }), null_ls.builtins.diagnostics.yamllint.with({
        condition = function(utils)
            return utils.root_has_file({".yamllint.yml"})
        end
    }), null_ls.builtins.diagnostics.shellcheck.with({
        condition = function(utils)
            return utils.root_has_file({".shellcheckrc"})
        end
    })
    -- null_ls.builtins.diagnostics.yamllint.with({
    --     args = {
    --         "-f", "parsable", "-d",
    --         "{extends: default, rules: {line-length: {level: warning}}}", "-"
    --     }
    -- })
}

-- null_ls.register(go_null_ls.gotest())
-- null_ls.register(go_null_ls.golangci_lint())

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
null_ls.setup({
    -- root_dir = nil,
    -- debug = true,
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

-- local go_null_ls = require("go.null_ls")
-- null_ls.register(go_null_ls.golangci_lint())
-- null_ls.register(go_null_ls.gotest())
-- null_ls.register(go_null_ls.gotest_action())
