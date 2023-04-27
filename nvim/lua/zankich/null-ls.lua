require("mason").setup()
local null_ls = require("null-ls")
local null_ls_utils = require("null-ls.utils").make_conditional_utils()
local null_ls_helpers = require("null-ls.helpers")
local null_ls_methods = require("null-ls.methods")

local gci = null_ls_helpers.make_builtin({
	name = "gci",
	meta = {
		url = "https://github.com/daixiang0/gci",
		description = "GCI, a tool that controls Go package import order and makes it always deterministic",
		notes = {},
	},
	method = null_ls_methods.internal.FORMATTING,
	filetypes = { "go" },
	generator_opts = {
		command = "gci",
		to_stdin = true,
		args = function()
			return {
				"print",
				"--section=standard",
				"--section=default",
				"--section=prefix(stash.corp.netflix.com)",
				"--section=blank",
				"--section=dot",
			}
		end,
	},
	factory = null_ls_helpers.formatter_factory,
})

local golangci_lint = null_ls_helpers.make_builtin({
	name = "golangci_lint",
	meta = {
		url = "https://golangci-lint.run/",
		description = "A Go linter aggregator.",
	},
	method = null_ls_methods.internal.DIAGNOSTICS_ON_SAVE,
	filetypes = { "go" },
	generator_opts = {
		command = "golangci-lint",
		to_stdin = true,
		from_stderr = false,
		ignore_stderr = true,
		multiple_files = true,
		args = {
			"run",
			"--fix=false",
			"--out-format=json",
			"--path-prefix",
			"$ROOT",
		},
		format = "json",
		check_exit_code = function(code)
			return code <= 2
		end,
		on_output = function(params)
			local diags = {}
			if params.output["Report"] and params.output["Report"]["Error"] then
				log:warn(params.output["Report"]["Error"])
				return diags
			end
			local issues = params.output["Issues"]
			if type(issues) == "table" then
				for _, d in ipairs(issues) do
					table.insert(diags, {
						source = string.format("golangci-lint:%s", d.FromLinter),
						row = d.Pos.Line,
						col = d.Pos.Column,
						message = d.Text,
						severity = null_ls_helpers.diagnostics.severities["warning"],
						filename = d.Pos.Filename,
					})
				end
			end
			return diags
		end,
	},
	factory = null_ls_helpers.generator_factory,
})

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
	sources = {
		null_ls.builtins.completion.luasnip,
		null_ls.builtins.completion.spell,
		null_ls.builtins.completion.tags,
		null_ls.builtins.code_actions.refactoring,
		gci,
	},
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
			local source = golangci_lint

			if not null_ls_utils.root_has_file(".golangci.yml") then
				source = source.with({
					extra_args = {
						"--config",
						vim.fn.expand("~/.config/nvim/lua/zankich/conf/.golangci.yml"),
					},
				})
			end

			null_ls.register(source)
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
