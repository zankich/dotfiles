-- require("dap").setup({})
require("dapui").setup({})
require("nvim-dap-virtual-text").setup()
require("dap-go").setup({})
require("neodev").setup({
	library = { plugins = { "nvim-dap-ui", "neotest" }, types = true },
})
