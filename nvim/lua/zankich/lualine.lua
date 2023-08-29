local lualine = require("lualine")

lualine.setup({
	options = { refresh = {}, theme = "base16", globalstatus = false },
	sections = {
		lualine_c = {
			{ "require('zankich.util').file_path_from_buffer_root_dir()", padding = 2 },
			{ "require('lsp-status').status()" },
		},
	},
	inactive_sections = {
		lualine_c = {
			{ "require('zankich.util').file_path_from_buffer_root_dir()", padding = 2 },
		},
	},
	tabline = {
		lualine_a = {
			{
				"mode",
				color = function()
					for _, group in ipairs(vim.fn.getcompletion("lualine_a_*_*$", "highlight")) do
						if string.match(group, "^lualine_a_%d+_.+") then
							vim.api.nvim_set_hl(0, group, { link = string.gsub(group, "^lualine_a_%d+", "lualine_a") })
						end
					end
				end,
			},
		},
		lualine_c = { { "filename", path = 3, padding = 2 } },
		lualine_z = {
			{
				"tabs",
				mode = 2,
				padding = 2,
				fmt = function(name, context)
					local buflist = vim.fn.tabpagebuflist(context.tabnr)
					local winnr = vim.fn.tabpagewinnr(context.tabnr)
					local bufnr = buflist[winnr]
					local fileName = vim.api.nvim_buf_get_name(bufnr)
					local root = vim.fn.fnamemodify(require("zankich.util").buffer_root_dir(fileName), ":p:h:t")

					if context.current then
						vim.api.nvim_tabpage_set_var(context.tabId, "tabname", root)
					end

					local ok, tabname = pcall(vim.api.nvim_tabpage_get_var, context.tabId, "tabname")
					if ok then
						return tabname
					else
						return root
					end
				end,
			},
		},
	},
	extensions = { "quickfix", "nvim-tree", "trouble" },
})
