local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")
local lspconfig = require("lspconfig")
local cmp_nvim_capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

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
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
		vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
		vim.keymap.set("n", "<space>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, opts)
		vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
		vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<space>f", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
	end,
})

mason.setup()

mason_lspconfig.setup({
	automatic_installation = true,
})

mason_lspconfig.setup_handlers({
	function(server_name) -- default handler (optional)
		lspconfig[server_name].setup({ capabilities = cmp_nvim_capabilities })
	end,
	["gopls"] = function()
		lspconfig.gopls.setup(require("go.lsp").config())
	end,
	["lua_ls"] = function()
		lspconfig.lua_ls.setup({
			capabilities = cmp_nvim_capabilities,
			settings = {
				Lua = {
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