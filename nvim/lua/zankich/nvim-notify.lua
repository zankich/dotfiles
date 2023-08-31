local notify = require("notify")

notify.setup({
	timeout = 1000,
	fps = 60,
	background_colour = "#000000",
	top_down = false,
})

vim.notify = notify
