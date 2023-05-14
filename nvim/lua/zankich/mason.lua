-- IMPORTANT: make sure to setup neodev BEFORE lspconfig
require("neodev").setup({
	library = { plugins = { "neotest" }, types = true },
})

local lsp_status = require("lsp-status")
lsp_status.config({
	current_function = false,
	indicator_ok = "",
	status_symbol = "",
	diagnostics = false,
})

lsp_status.register_progress()

local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")
local lspconfig = require("lspconfig")
local cmp_nvim_capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
-- Set default client capabilities plus window/workDoneProgress
cmp_nvim_capabilities = vim.tbl_extend("keep", cmp_nvim_capabilities, lsp_status.capabilities)

-- vim.lsp.set_log_level("debug")

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
	local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
	params.context = { only = { "source.organizeImports" } }

	local params = vim.lsp.util.make_range_params(0, vim.lsp.util._get_offset_encoding())
	params.context = { only = { "source.organizeImports" } }

	local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 5000)
	for _, res in pairs(result or {}) do
		for _, r in pairs(res.result or {}) do
			-- print(vim.inspect(r.command))
			if r.edit then
				vim.lsp.util.apply_workspace_edit(r.edit, vim.lsp.util._get_offset_encoding())
				-- else
				-- vim.lsp.buf.execute_command(r.command)
			end
		end
	end

	local gci_output = vim.fn.systemlist({
		"gci",
		"print",
		"--section=standard",
		"--section=default",
		"--section=prefix(stash.corp.netflix.com)",
		"--section=blank",
		"--section=dot",
		"--skip-generated",
	}, vim.api.nvim_buf_get_lines(bufnr, 0, -1, true))

	if not vim.v.shell_error == 1 then
		-- Get the current buffer and set its contents to the output
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, gci_output)
	end
end

vim.diagnostic.config({
	virtual_text = false,
	float = {
		source = "if_many",
		border = "rounded",
		style = "minimal",
	},
	signs = true,
	underline = false,
	severity_sort = true,
})

mason.setup()
mason_lspconfig.setup({
	ensure_installed = {
		"gopls",
		"lua_ls",
		"bashls",
		"yamlls",
		"marksman",
	},
	automatic_installation = true,
	handlers = {
		function(server_name) -- default handler (optional)
			lspconfig[server_name].setup({
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
					-- vim.api.nvim_buf_create_user_command(bufnr, "TestDir", function()
					-- 	open_buffers_and_test(vim.fn.expand("%:p:h"))
					-- end, {})
					--
					-- vim.api.nvim_buf_create_user_command(bufnr, "TestProject", function()
					-- 	open_buffers_and_test(vim.fn.getcwd())
					-- end, {})
					--
					lsp_status.on_attach(client)
				end,
				settings = {
					gopls = {
						["local"] = "stash.corp.netflix.com",
						allExperiments = true,
						gofumpt = true,
						semanticTokens = true,
						analyses = {
							unusedwrite = true,
							useany = true,
							unusedvariable = true,
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

-- vim.lsp.handlers["window/showMessage"] = function(err, method, params)
-- 	vim.notify(method.message, params.type, {
-- 		title = vim.lsp.get_client_by_id(params.client_id).name,
-- 	})
-- end
