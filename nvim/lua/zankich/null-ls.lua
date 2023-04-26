require("mason").setup()
local null_ls = require("null-ls")
local null_ls_utils = require("null-ls.utils").make_conditional_utils()
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({
	debug = true,
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr })
				end,
			})
		end
	end,
})

require("mason-null-ls").setup({
	ensure_installed = {
		"stylua",
		"prettier",
		"yamllint",
		"golangci_lint",
		"shfmt",
		"shellcheck",
	},
	automatic_installation = true,
	handlers = {
		yamllint = function()
			if null_ls_utils.root_has_file(".yamllint.yml") then
				null_ls.register(null_ls.builtins.diagnostics.yamllint)
			else
				null_ls.register(null_ls.builtins.diagnostics.yamllint.with({
					extra_args = {
						"-c",
						vim.fn.expand("~/.config/nvim/lua/zankich/conf/.yamllint.yml"),
					},
				}))
			end
		end,
		shfmt = function()
			null_ls.register(null_ls.builtins.formatting.shfmt.with({
				extra_args = {
					"--binary-next-line",
					"--case-indent",
					"--indent",
					"2",
				},
			}))
		end,
		shellcheck = function()
			null_ls.register(null_ls.builtins.code_actions.shellcheck)

			if null_ls_utils.root_has_file(".shellcheckrc") then
				null_ls.register(null_ls.builtins.diagnostics.shellcheck)
			else
				null_ls.register(null_ls.builtins.diagnostics.shellcheck.with({
					cwd = function()
						return vim.fn.expand("~/.config/nvim/lua/zankich/conf")
					end,
				}))
			end
		end,
		golangci_lint = function()
			if null_ls_utils.root_has_file(".golangci.yml") then
				null_ls.register(null_ls.builtins.diagnostics.golangci_lint)
			else
				null_ls.register(null_ls.builtins.diagnostics.golangci_lint.with({
					extra_args = {
						"--config",
						vim.fn.expand("~/.config/nvim/lua/zankich/conf/.golangci.yml"),
					},
				}))
			end
		end,
	},
})

if null_ls_utils.root_has_file(".markdownlint-cli2.jsonc") then
	null_ls.register(null_ls.builtins.diagnostics.markdownlint_cli2.with({
		args = { "$FILENAME" },
	}))
else
	null_ls.register(null_ls.builtins.diagnostics.markdownlint_cli2.with({
		args = { "$FILENAME" },
		cwd = function()
			return vim.fn.expand("~/.config/nvim/lua/zankich/conf")
		end,
	}))
end

null_ls.register({
	null_ls.builtins.completion.luasnip,
	null_ls.builtins.completion.spell,
	null_ls.builtins.completion.tags,
	null_ls.builtins.code_actions.refactoring,
})
