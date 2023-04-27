local M = {}

M.find_files_opts = { hidden = true }

local util = require("zankich.util")
local actions = require("telescope.actions")
local trouble = require("trouble.providers.telescope")

require("telescope").setup({
	defaults = require("telescope.themes").get_ivy({
		mappings = {
			i = {
				["<esc>"] = actions.close,
				["<c-t>"] = trouble.open_with_trouble,
			},
			n = { ["<c-t>"] = trouble.open_with_trouble },
		},
	}),
	pickers = {
		colorscheme = { enable_preview = true },
		find_files = {
			mappings = {
				i = {
					["<C-g>"] = function(prompt_bufnr)
						local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
						local opts = vim.deepcopy(M.find_files_opts)

						if current_picker.prompt_title == "~/code" then
							local bufferRootDir = util.bufferRootDir()
							opts.cwd = bufferRootDir
							opts.prompt_title = bufferRootDir
						else
							opts.cwd = "~/code"
							opts.prompt_title = "~/code"
						end

						require("telescope.actions").close(prompt_bufnr)
						require("telescope.builtin").find_files(opts)
					end,
				},
			},
		},
	},
})

require("telescope").load_extension("fzf")

local builtin = require("telescope.builtin")

function M.search_root()
	local opts = vim.deepcopy(M.find_files_opts)

	local bufferRootDir = util.bufferRootDir()
	opts.cwd = bufferRootDir
	opts.prompt_title = bufferRootDir

	builtin.find_files(opts)
end

vim.keymap.set("n", "<leader>f", M.search_root, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>rg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>b", builtin.buffers, {})
vim.keymap.set("n", "<leader>h", builtin.help_tags, {})
