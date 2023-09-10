local config = {
	cmd = { vim.fs.normalize("~/.local/share/nvim/mason/bin/jdtls") },
	root_dir = vim.fs.dirname(vim.fs.find({ "gradlew", ".git", "mvnw" }, { upward = true })[1]),
	init_options = {
		bundles = {
			vim.fn.glob(
				vim.fs.normalize("~/.local/share/nvim/zankich/java-debug")
					.. "/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar",
				true
			),
			vim.fn.glob(vim.fs.normalize("~/.local/share/nvim/zankich/vscode-java-test") .. "/server/*.jar", true),
		},
	},
}

require("jdtls").start_or_attach(config)

-- nnoremap <A-o> <Cmd>lua require'jdtls'.organize_imports()<CR>
-- nnoremap crv <Cmd>lua require('jdtls').extract_variable()<CR>
-- vnoremap crv <Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>
-- nnoremap crc <Cmd>lua require('jdtls').extract_constant()<CR>
-- vnoremap crc <Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>
-- vnoremap crm <Esc><Cmd>lua require('jdtls').extract_method(true)<CR>
--
--
-- " If using nvim-dap
-- " This requires java-debug and vscode-java-test bundles, see install steps in this README further below.
-- nnoremap <leader>df <Cmd>lua require'jdtls'.test_class()<CR>
-- nnoremap <leader>dn <Cmd>lua require'jdtls'.test_nearest_method()<CR>
-- -- require("jdtls.dap").setup_dap_main_class_configs()
