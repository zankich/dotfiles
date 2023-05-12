require("trouble").setup({
	use_diagnostic_signs = false,
})

vim.keymap.set("n", "<space>t", ":Trouble<CR>", { silent = true, noremap = true })

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
