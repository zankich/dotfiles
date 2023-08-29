local M = {}

function M.reload()
	require("plenary.reload").reload_module("zankich")
	require("zankich")
	print("config reloaded!")
end

function M.buffer_root_dir_for_file(fi)
	local currentdir = vim.fn.fnamemodify(fi, vim.fn.expand(":p:h"))
	local file = io.popen("git -C " .. currentdir .. " rev-parse --show-toplevel 2> /dev/null", "r")
	local output = file:read("*line")
	file:close()

	if output and not output:find(":/") then
		return vim.fn.resolve(output)
	else
		return vim.fn.resolve(currentdir)
	end
end

function M.buffer_root_dir(fi)
	local currentdir

	if fi == nil then
		currentdir = vim.fn.fnamemodify(fi, vim.fn.expand(":p:h"))
	else
		currentdir = vim.fn.expand("%:p:h")
	end
	local file = io.popen("git -C " .. currentdir .. " rev-parse --show-toplevel 2> /dev/null", "r")
	local output = file:read("*line")
	file:close()

	if output and not output:find(":/") then
		return vim.fn.resolve(output)
	else
		return vim.fn.resolve(currentdir)
	end
end

function M.file_path_from_buffer_root_dir()
	local rootDir = M.buffer_root_dir()
	local currentDir = vim.fn.fnamemodify(rootDir, ":p:h:t")
	local relativePath = vim.fn.fnamemodify(vim.fn.expand("%h"), ":." .. rootDir .. ":")
	return currentDir .. "/" .. relativePath
end

function M.value_in_array(value, array)
	for _, v in ipairs(array) do
		if v == value then
			return true
		end
	end
	return false
end

vim.api.nvim_create_autocmd("BufEnter", { command = vim.cmd.lcd(M.buffer_root_dir()) })
vim.keymap.set("n", "<space>r", M.reload, { silent = true, noremap = true })

vim.keymap.set("n", "<Leader>s", ":%s/<C-r><C-w>//gc<Left><Left><Left>")
vim.keymap.set("v", "<Leader>s", '"hy:%s/<C-r>h//gc<left><left><left>')

return M
