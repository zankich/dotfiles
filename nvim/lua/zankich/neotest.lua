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

	if notif_data.spinner and notif_data.notification then
		notif_data.spinner = ((notif_data.spinner + 1) % #spinner_frames)
		if notif_data.spinner == 0 then
			notif_data.spinner = 8
		end

		notif_data.notification = vim.notify(nil, nil, {
			hide_from_history = true,
			icon = spinner_frames[notif_data.spinner],
			replace = notif_data.notification.id,
		})

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
	end
end

local function format_title(title)
	return (#title > 0 and ": " .. title or "")
end

require("neotest").setup({
	log_level = "trace",
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
				local message = "Passed!"
				local level = vim.log.levels.INFO
				local icons = {}
				icons[vim.log.levels.ERROR] = ""
				icons[vim.log.levels.INFO] = ""

				for _, result in pairs(results) do
					if result.status == "failed" then
						failures = failures + 1
					end
				end

				if failures > 0 then
					message = "There were " .. failures .. " test failures!"
					level = vim.log.levels.ERROR
				end

				vim.notify(message, level, {
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

	require("neotest").run.run(path)
end

vim.api.nvim_create_user_command("TestFunc", function()
	require("neotest").run.run()
end, {})

vim.api.nvim_create_user_command("TestFile", function()
	require("neotest").run.run(vim.fn.expand("%:p"))
end, {})

vim.api.nvim_create_user_command("TestDir", function()
	open_buffers_and_test(vim.fn.expand("%:p:h"))
end, {})

vim.api.nvim_create_user_command("TestProject", function()
	open_buffers_and_test(require("zankich.util").bufferRootDir())
end, {})

vim.api.nvim_create_user_command("TestOutput", function()
	require("neotest").output.open({ enter = true, quiet = true, auto_close = true })
end, {})

vim.api.nvim_create_user_command("TestSummary", function()
	require("neotest").summary.toggle()
end, {})

vim.keymap.set("n", "[t", function()
	require("neotest").jump.prev({ status = "failed" })
end)

vim.keymap.set("n", "]t", function()
	require("neotest").jump.next({ status = "failed" })
end)

vim.keymap.set("n", "<space>o", ":TestOutput<CR>")
