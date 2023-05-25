local notify = require("notify")
local neotest = require("neotest")

local notifications = {}

local function get_notif_data(id)
	if not notifications[id] then
		notifications[id] = {}
	end

	return notifications[id]
end

local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

local function update_spinner(id)
	local notif_data = get_notif_data(id)

	if notif_data.spinner then
		notif_data.spinner = ((notif_data.spinner + 1) % #spinner_frames)
		if notif_data.spinner == 0 then
			notif_data.spinner = 8
		end

		if notif_data.notification.id then
			notif_data.notification = vim.notify(nil, nil, {
				hide_from_history = true,
				icon = spinner_frames[notif_data.spinner],
				replace = notif_data.notification.id,
			})
		else
			notify.dismiss({ pending = false })
			return nil
		end

		vim.defer_fn(function()
			update_spinner(id)
		end, 100)
	else
		notif_data.notification = vim.notify(nil, nil, {
			hide_from_history = true,
			icon = spinner_frames[notif_data.spinner],
			replace = notif_data.notification.id,
			timeout = 0,
		})

		return nil
	end
end

local function format_title(title)
	return (#title > 0 and ": " .. title or "")
end

neotest.setup({
	log_level = "info",
	quickfix = {
		open = false,
	},
	adapters = {
		require("neotest-go")({
			experimental = {
				test_table = true,
			},
			args = { "-count=1" },
		}),
	},
	consumers = {
		notify = function(client)
			local title = "Neotest"

			client.listeners.run = function(adapter_id, root_id, position_ids)
				local notif_data = get_notif_data(adapter_id)

				notif_data.notification = vim.notify("Running tests " .. root_id, vim.log.levels.INFO, {
					title = format_title(title),
					icon = spinner_frames[1],
					hide_from_history = false,
					timeout = false,
				})

				notif_data.spinner = 0

				update_spinner(adapter_id)

				return {}
			end

			client.listeners.results = function(adapter_id, results, partial)
				if partial then
					return
				end

				local notif_data = get_notif_data(adapter_id)
				local failures = 0
				local passed = 0
				local skipped = 0
				local messages = {}
				local level = vim.log.levels.INFO
				local icons = {}
				icons[vim.log.levels.ERROR] = ""
				icons[vim.log.levels.INFO] = ""
				icons[vim.log.levels.WARN] = ""

				for _, result in pairs(results) do
					if result.status == "failed" then
						failures = failures + 1
					end
					if result.status == "passed" then
						passed = passed + 1
					end
					if result.status == "skipped" then
						skipped = skipped + 1
					end
				end

				if passed > 0 then
					table.insert(messages, passed .. " tests passed")
					level = vim.log.levels.INFO
				end

				if skipped > 0 then
					table.insert(messages, skipped .. " tests skipped")
					level = vim.log.levels.WARN
				end

				if failures > 0 then
					table.insert(messages, failures .. " tests failed")
					level = vim.log.levels.ERROR
				end

				vim.notify(table.concat(messages, "\n"), level, {
					title = title,
					icon = icons[level],
					hide_from_history = false,
				})

				notif_data.spinner = nil

				return {}
			end
		end,
	},
})

local open_buffers_and_test = function(path)
	local bufnr = vim.api.nvim_get_current_buf()
	local ft = vim.fn.getbufvar(bufnr, "&filetype")

	if ft == "go" then
		local cmd = string.format("fd --exclude vendor --absolute-path --glob '*_test.go' %s", path)
		local handle = io.popen(cmd)
		local result = handle:read("*a")
		handle:close()

		for file in result:gmatch("([^\n]*)\n?") do
			vim.api.nvim_command(string.format("edit! %s", file))
		end

		vim.api.nvim_command(string.format("buffer %s", bufnr))
	end

	neotest.run.run(path)
end

vim.api.nvim_create_user_command("TestFunc", function()
	neotest.run.run()
end, {})

vim.api.nvim_create_user_command("TestFile", function()
	neotest.run.run(vim.fn.expand("%:p"))
end, {})

vim.api.nvim_create_user_command("TestDir", function()
	open_buffers_and_test(vim.fn.expand("%:p:h"))
end, {})

vim.api.nvim_create_user_command("TestProject", function()
	open_buffers_and_test(require("zankich.util").bufferRootDir())
end, {})

vim.api.nvim_create_user_command("TestOutput", function()
	neotest.output.open({ enter = true, quiet = true, auto_close = true })
end, {})

vim.api.nvim_create_user_command("TestOutputPanel", function()
	neotest.output_panel.toggle()
end, {})

vim.api.nvim_create_user_command("TestSummary", function()
	neotest.summary.toggle()
end, {})

vim.keymap.set("n", "[t", function()
	neotest.jump.prev({ status = "failed" })
end)

vim.keymap.set("n", "]t", function()
	neotest.jump.next({ status = "failed" })
end)

vim.keymap.set("n", "<space>o", ":TestOutput<CR>")
