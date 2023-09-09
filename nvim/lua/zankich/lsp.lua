local settings = require("zankich.settings")
local util = require("zankich.util")

local lsp_status = require("lsp-status")
lsp_status.config({
	current_function = false,
	indicator_ok = "",
	status_symbol = "",
	diagnostics = false,
})

lsp_status.register_progress()

local mason = require("mason")
mason.setup({})

local mason_lspconfig = require("mason-lspconfig")
local lspconfig = require("lspconfig")
local cmp_nvim_capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Set default client capabilities plus window/workDoneProgress
cmp_nvim_capabilities = vim.tbl_extend("keep", cmp_nvim_capabilities, lsp_status.capabilities)

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local opts = { buffer = ev.buf }
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
		vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
		vim.keymap.set("n", "<space>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, opts)
		vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
		vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "<space>f", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
	end,
})

local go_imports = function(client, bufnr)
	local params = vim.lsp.util.make_range_params(0, vim.lsp.util._get_offset_encoding(bufnr))
	params.context = { only = { "source.organizeImports" } }

	local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 5000)
	for _, res in pairs(result or {}) do
		for _, r in pairs(res.result or {}) do
			if r.edit then
				vim.lsp.util.apply_workspace_edit(r.edit, vim.lsp.util._get_offset_encoding(bufnr))
			end
		end
	end

	local gci_output = vim.fn.systemlist(
		vim.list_extend({
			"gci",
			"print",
		}, settings.go.gci_flags),
		vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
	)

	if not vim.v.shell_error == 1 then
		-- Get the current buffer and set its contents to the output
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, gci_output)
	end
end

vim.diagnostic.config({
	virtual_text = true,
	float = {
		source = "always",
		border = "rounded",
		style = "minimal",
	},
	signs = true,
	underline = false,
	severity_sort = true,
})

require("mason-tool-installer").setup({
	ensure_installed = {
		"golangci-lint",
		"efm",
		"gopls",
		"stylua",
		"gofumpt",
		"shellcheck",
		"shfmt",
		"yamllint",
	},
	auto_update = true,
	run_on_start = true,
})

mason_lspconfig.setup({
	automatic_installation = true,
	ensure_installed = { "efm" },
	handlers = {
		function(server_name) -- default handler (optional)
			lspconfig[server_name].setup({
				capabilities = cmp_nvim_capabilities,
				on_attach = function(client, bufnr)
					lsp_status.on_attach(client)
				end,
			})
		end,
		["efm"] = function()
			local augroup = vim.api.nvim_create_augroup("efm", {})
			lspconfig.efm.setup({
				cmd = {
					"efm-langserver",
					"-loglevel=4",
					"-logfile=" .. vim.fs.normalize("~/.local/state/nvim/efm.log"),
				},
				filetypes = { "lua", "typescript", "javascript", "sh" },
				init_options = {
					documentFormatting = true,
					documentRangeFormatting = true,
					hover = true,
					documentSymbol = true,
					codeAction = true,
					completion = true,
				},
				capabilities = cmp_nvim_capabilities,
				on_attach = function(client, bufnr)
					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							if util.value_in_array(vim.api.nvim_buf_get_option(bufnr, "filetype"), { "lua", "sh" }) then
								vim.lsp.buf.format({ bufnr = bufnr, id = client.id })
							end
						end,
					})

					lsp_status.on_attach(client)
				end,
				settings = {
					rootMarkers = { ".git/" },
					languages = {
						sh = {
							{
								lintCommand = "shellcheck --color=never --format=gcc --external-sources -",
								lintStdin = true,
								lintIgnoreExitCode = true,
								lintFormats = {
									"-:%l:%c: %trror: %m",
									"-:%l:%c: %tarning: %m",
									"-:%l:%c: %tote: %m",
								},
							},
							{
								formatCommand = "shfmt --case-indent --binary-next-line --indent 2 -",
								formatStdin = true,
							},
						},
						lua = {
							{
								formatCommand = "stylua -",
								formatStdin = true,
							},
						},
						typescript = {
							{
								formatCommand = "n exec 20 npx -y prettier-eslint-cli --stdin --stdin-filepath ${INPUT} -",
								formatStdin = true,
								rootMarkers = {
									"eslint.config.js",
									".eslintrc",
									".eslintrc.js",
									".eslintrc.cjs",
									".eslintrc.yaml",
									".eslintrc.yml",
									".eslintrc.json",
									"package.json",
									"eslint.config.js",
									".tsconfig.json",
								},
								requireMarkers = true,
							},
							{
								lintCommand = "n exec 20 npx -y eslint_d --cache=true --no-color --format visualstudio --stdin --stdin-filename ${INPUT} -",
								lintFormats = { "%f(%l,%c): %trror %m", "%f(%l,%c): %tarning %m" },
								lintStdin = true,
								lintIgnoreExitCode = true,
								rootMarkers = {
									"eslint.config.js",
									".eslintrc",
									".eslintrc.js",
									".eslintrc.cjs",
									".eslintrc.yaml",
									".eslintrc.yml",
									".eslintrc.json",
									"package.json",
									".tsconfig.json",
								},
								requireMarkers = true,
							},
						},
					},
				},
			})
		end,
		["cucumber_language_server"] = function()
			lspconfig.cucumber_language_server.setup({
				-- running a forked version of the language server https://github.com/zankich/cucumber-language-server
				-- see https://github.com/cucumber/language-server/pull/74
				cmd = {
					"n",
					"exec",
					"16",
					"npx",
					"-y",
					vim.fs.normalize("~/.local/share/nvim/zankich/cucumber-language-server"),
					"--stdio",
				},
				capabilities = cmp_nvim_capabilities,
				on_attach = function(client, bufnr)
					lsp_status.on_attach(client)
				end,
			})
		end,
		["gopls"] = function()
			local augroup = vim.api.nvim_create_augroup("gopls", {})
			lspconfig.gopls.setup({
				capabilities = cmp_nvim_capabilities,
				on_attach = function(client, bufnr)
					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ bufnr = bufnr, id = client.id })
						end,
					})

					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function(args)
							go_imports(client, bufnr)
						end,
					})

					-- https://github.com/golang/go/issues/54531#issuecomment-1464982242
					local semantic = client.config.capabilities.textDocument.semanticTokens
					client.server_capabilities.semanticTokensProvider = {
						full = true,
						legend = { tokenModifiers = semantic.tokenModifiers, tokenTypes = semantic.tokenTypes },
						range = true,
					}

					lsp_status.on_attach(client)
				end,
				settings = {
					gopls = {
						["local"] = settings.go.imports["local"],
						allExperiments = true,
						allowImplicitNetworkAccess = true,
						gofumpt = true,
						semanticTokens = true,
						usePlaceholders = true,
						analyses = {
							useany = true,
							unusedparams = true,
							nilness = true,
							shadow = true,
							unusedvariable = true,
							stubmethods = true,
						},
					},
				},
			})
		end,
		["lua_ls"] = function()
			lspconfig.lua_ls.setup({
				capabilities = cmp_nvim_capabilities,
				on_attach = function(client, bufnr)
					lsp_status.on_attach(client)
				end,
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
						format = { enable = false },
						runtime = {
							-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
							version = "LuaJIT",
						},
						diagnostics = {
							-- Get the language server to recognize the `vim` global
							globals = { "vim" },
						},
						workspace = {
							-- Make the server aware of Neovim runtime files
							library = {
								vim.api.nvim_get_runtime_file("", true),
								vim.fn.expand("$VIMRUNTIME/lua"),
								vim.fn.stdpath("config") .. "/lua",
							},
							checkThirdParty = false, -- THIS IS THE IMPORTANT LINE TO ADD
						},
						-- Do not send telemetry data containing a randomized but unique identifier
						telemetry = { enable = false },
					},
				},
			})
		end,
		["bashls"] = function()
			lspconfig.bashls.setup({
				capabilities = cmp_nvim_capabilities,
				on_attach = function(client, bufnr)
					lsp_status.on_attach(client)
				end,
				settings = {
					bashIde = {
						backgroundAnalysisMaxFiles = 99999,
						includeAllWorkspaceSymbols = true,
						explainshellEndpoint = "https://explainshell.com",
						shellcheckPath = "",
					},
				},
			})
		end,
		["yamlls"] = function()
			lspconfig.yamlls.setup({
				capabilities = cmp_nvim_capabilities,
				on_attach = function(client, bufnr)
					lsp_status.on_attach(client)
				end,
				filetypes = { "yaml", "yaml.docker-compose", "yml" },
				settings = {
					yaml = {
						schemaStore = { enable = true },
						format = { enable = true },
						keyOrdering = false,
						completion = true,
						hover = true,
					},
				},
			})
		end,
		["ltex"] = function()
			lspconfig.ltex.setup({
				capabilities = cmp_nvim_capabilities,
				on_attach = function(client, bufnr)
					lsp_status.on_attach(client)
				end,
				filetypes = { "bib", "gitcommit", "org", "plaintex", "rst", "rnoweb", "tex", "pandoc" },
			})
		end,
		["tsserver"] = function()
			local augroup = vim.api.nvim_create_augroup("tsserver", {})
			lspconfig.tsserver.setup({
				cmd = {
					"n",
					"exec",
					"20",
					"npx",
					"-y",
					"typescript-language-server",
					"--stdio",
				},
				capabilities = cmp_nvim_capabilities,
				on_attach = function(client, bufnr)
					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ bufnr = bufnr, id = client.id })
						end,
					})

					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							for _, action in ipairs({
								-- "source.fixAll",
								-- "source.removeUnused",
								"source.addMissingImports",
								"source.removeUnusedImports",
								"source.sortImports",
								"source.organizeImports",
							}) do
								local params =
									vim.lsp.util.make_range_params(0, vim.lsp.util._get_offset_encoding(bufnr))
								params.context = {
									only = { action },
								}

								local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 5000)
								for _, res in pairs(result or {}) do
									for _, r in pairs(res.result or {}) do
										if r.edit then
											vim.lsp.util.apply_workspace_edit(
												r.edit,
												vim.lsp.util._get_offset_encoding(bufnr)
											)
										end
									end
								end
							end
						end,
					})
					lsp_status.on_attach(client)
				end,
				settings = {
					typescript = {
						format = {
							insertSpaceAfterConstructor = true,
							insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
							insertSpaceBeforeFunctionParenthesis = true,
							semicolons = "remove",
						},
					},
				},
			})
		end,
	},
})

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("mason-lspconfig", { clear = true }),
	callback = function(t)
		if vim.bo[t.buf].buftype ~= "" then
			return
		end

		local installed_servers = mason_lspconfig.get_installed_servers()
		local available_servers = mason_lspconfig.get_available_servers({
			filetype = t.match,
		})

		for _, value in pairs(available_servers) do
			if vim.tbl_contains(installed_servers, value) then
				return
			end
		end

		if #available_servers > 0 then
			vim.cmd.LspInstall()
		end
	end,
})

vim.lsp.handlers["workspace/diagnostic/refresh"] = function(_, _, ctx)
	local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
	pcall(vim.diagnostic.reset, ns)
	return true
end
