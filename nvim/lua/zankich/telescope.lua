local M = {}

M.find_files_opts = { hidden = true }

local util = require("zankich.util")
local telescope = require("telescope")
local actions = require("telescope.actions")
local trouble = require("trouble.providers.telescope")
local lga_actions = require("telescope-live-grep-args.actions")
telescope.load_extension("live_grep_args")

telescope.setup({
	defaults = require("telescope.themes").get_ivy({
		mappings = {
			i = {
				["<esc>"] = actions.close,
				["<c-t>"] = trouble.open_with_trouble,
				["<C-k>"] = lga_actions.quote_prompt(),
			},
			n = { ["<c-t>"] = trouble.open_with_trouble, ["<C-k>"] = lga_actions.quote_prompt() },
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

telescope.load_extension("fzf")
telescope.load_extension("live_grep_args")

local builtin = require("telescope.builtin")

function M.search_root()
	local opts = vim.deepcopy(M.find_files_opts)

	local bufferRootDir = util.bufferRootDir()
	opts.cwd = bufferRootDir
	opts.prompt_title = bufferRootDir

	builtin.find_files(opts)
end

vim.keymap.set("n", "<leader>f", M.search_root, { noremap = true, silent = true })
-- vim.keymap.set("n", "<leader>rg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>rg", function()
	telescope.extensions.live_grep_args.live_grep_args()
end)
vim.keymap.set("n", "<leader>b", builtin.buffers, {})
vim.keymap.set("n", "<leader>h", builtin.help_tags, {})
