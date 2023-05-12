local notify = require("notify")

notify.setup({
	timeout = 1000,
	fps = 60,
	background_colour = "#000000",
	top_down = false,
})

-- require("lsp-notify").setup({
-- 	notify = notify,
-- })

vim.notify = notify

-- ignore spammy messages https://github.com/rcarriga/nvim-notify/issues/114#issuecomment-1179754969
-- local banned_messages = {
-- 	"No code actions available", -- gopls sends this if it doesn't have to reorder imports, etc
-- }

-- vim.notify = function(msg, ...)
-- 	for _, banned in ipairs(banned_messages) do
-- 		if msg == banned then
-- 			print(msg)
-- 			return
-- 		end
-- 	end
-- 	notify(msg, ...)
-- end
