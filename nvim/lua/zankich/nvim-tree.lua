local HEIGHT_RATIO = 0.9 -- You can change this
local WIDTH_RATIO = 0.5 -- You can change this too

local function copy_file_to(node)
	local file_src = node["absolute_path"]
	-- The args of input are {prompt}, {default}, {completion}
	-- Read in the new file path using the existing file's path as the baseline.
	local file_out = vim.fn.input("COPY TO: ", file_src, "file")
	-- Create any parent dirs as required
	local dir = vim.fn.fnamemodify(file_out, ":h")
	vim.fn.system({ "mkdir", "-p", dir })
	-- Copy the file
	vim.fn.system({ "cp", "-R", file_src, file_out })
end

local function move_file_to(node)
	local file_src = node["absolute_path"]
	-- The args of input are {prompt}, {default}, {completion}
	-- Read in the new file path using the existing file's path as the baseline.
	local file_out = vim.fn.input("MOVE TO: ", file_src, "file")
	-- Create any parent dirs as required
	local dir = vim.fn.fnamemodify(file_out, ":h")
	vim.fn.system({ "mkdir", "-p", dir })
	-- Copy the file
	vim.fn.system({ "mv", file_src, file_out })
end

local function on_attach(bufnr)
	local api = require("nvim-tree.api")

	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end

	-- Default mappings.
	api.config.mappings.default_on_attach(bufnr)

	vim.keymap.set("n", "u", api.tree.change_root_to_parent, opts("Up"))
	vim.keymap.set("n", "-", api.tree.close, opts("Close"))
	vim.keymap.set("n", "c", function()
		local node = api.tree.get_node_under_cursor()
		copy_file_to(node)
	end, opts("copy_file_to"))
	vim.keymap.set("n", "mv", function()
		local node = api.tree.get_node_under_cursor()
		move_file_to(node)
	end, opts("move_file_to"))
end

require("nvim-tree").setup({
	on_attach = on_attach,

	view = {
		float = {
			enable = true,
			open_win_config = function()
				local screen_w = vim.opt.columns:get()
				local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
				local window_w = screen_w * WIDTH_RATIO
				local window_h = screen_h * HEIGHT_RATIO
				local window_w_int = math.floor(window_w)
				local window_h_int = math.floor(window_h)
				local center_x = (screen_w - window_w) / 2
				local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
				return {
					border = "rounded",
					relative = "editor",
					row = center_y,
					col = center_x,
					width = window_w_int,
					height = window_h_int,
				}
			end,
		},
		width = function()
			return math.floor(vim.opt.columns:get() * WIDTH_RATIO)
		end,
	},
	update_focused_file = { enable = true, update_root = true, ignore_list = {} },
	sort_by = "case_sensitive",
	renderer = { group_empty = true },
	filters = { dotfiles = false, git_clean = false, no_buffer = false },
	actions = { open_file = { window_picker = { enable = false } } },
	git = {
		ignore = false,
	},
})

local function open_nvim_tree(data)
	-- buffer is a directory
	local directory = vim.fn.isdirectory(data.file) == 1

	if not directory then
		return
	end

	-- change to the directory
	vim.cmd.cd(require("zankich.util").buffer_root_dir())

	require("nvim-tree.api").tree.focus()
end

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
vim.keymap.set("n", "-", require("nvim-tree.api").tree.focus)
