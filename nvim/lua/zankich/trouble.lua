local trouble = require("trouble")
trouble.setup({
	auto_preview = false,
	-- auto_fold = true,
	use_diagnostic_signs = false,
	sort_keys = {
		"filename",
		"lnum",
		"col",
		"severity",
	},
})

vim.keymap.set("n", "<space>t", ":Trouble<CR>", { silent = true, noremap = true })

vim.keymap.set("n", "[t", function()
	trouble.previous({ skip_groups = true, jump = true })
end)
vim.keymap.set("n", "]t", function()
	trouble.next({ skip_groups = true, jump = true })
end)

local do_trouble = function(action)
	vim.cmd(":Trouble " .. action)
end

vim.api.nvim_create_user_command("LspDefinitions", function()
	do_trouble("lsp_definitions")
end, {})

vim.api.nvim_create_user_command("LspReferences", function()
	do_trouble("lsp_references")
end, {})

vim.api.nvim_create_user_command("LspImplementations", function()
	do_trouble("lsp_implementations")
end, {})

vim.api.nvim_create_user_command("LspTypeDefinitions", function()
	do_trouble("lsp_type_definitions")
end, {})
