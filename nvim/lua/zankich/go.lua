-- local ts_utils = require("nvim-treesitter.ts_utils")
-- local parse = vim.treesitter.query.parse
--
-- local query_test_func = [[((function_declaration name: (identifier) @test_name
--         parameters: (parameter_list
--             (parameter_declaration
--                      name: (identifier)
--                      type: (pointer_type
--                          (qualified_type
--                           package: (package_identifier) @_param_package
--                           name: (type_identifier) @_param_name))))
--          ) @testfunc
--       (#contains? @test_name "Test")
--       (#match? @_param_package "testing")
--       (#match? @_param_name "T"))]]
--
-- local test_file = function()
-- 	local bufnr = vim.api.nvim_get_current_buf()
-- 	local tree = vim.treesitter.get_parser(bufnr):parse()[1]
-- 	local query = parse("go", query_test_func)
--
-- 	local test_funcs = {}
-- 	for id, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
-- 		local name = query.captures[id]
-- 		if name == "test_name" then
-- 			table.insert(test_funcs, vim.treesitter.get_node_text(node, bufnr, {}))
-- 		end
-- 	end
--
-- 	vim.schedule(function()
-- 		-- vim.notify("Running tests for " .. vim.uri_from_bufnr(bufnr), vim.log.levels.INFO)
-- 		vim.lsp.buf.execute_command({
-- 			command = "gopls.run_tests",
-- 			arguments = { { URI = vim.uri_from_bufnr(bufnr), Tests = test_funcs } },
-- 		})
-- 	end)
-- end
--
-- local test_func = function()
-- 	local current_node = ts_utils.get_node_at_cursor()
-- 	if not current_node then
-- 		return "no test function found"
-- 	end
--
-- 	local bufnr = vim.api.nvim_get_current_buf()
-- 	local node = current_node
-- 	while node do
-- 		if node:type() == "function_declaration" then
-- 			vim.schedule(function()
-- 				vim.lsp.buf.execute_command({
-- 					command = "gopls.run_tests",
-- 					arguments = {
-- 						{
-- 							URI = vim.uri_from_bufnr(bufnr),
-- 							Tests = { vim.treesitter.get_node_text(node:child(1), bufnr, {}) },
-- 						},
-- 					},
-- 				})
-- 			end)
--
-- 			return ""
-- 		end
-- 		node = node:parent()
-- 	end
--
-- 	return "no test function found"
-- end

local get_diagnostic_namespace = function(bufnr)
	-- local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
	local clients = vim.lsp.get_active_clients()
	if clients == nil or #clients == 0 then
		return nil
	end

	return vim.api.nvim_create_namespace(string.format("vim.lsp.%s.%d", clients[1].name, bufnr))
end

local golanci_lint = function(package)
	if package == nil then
		package = require("zankich.util").bufferRootDir() .. "/..."
	end

	vim.fn.jobstart({
		"golangci-lint",
		"run",
		"--out-format=json",
		package,
	}, {
		on_stdout = function(chan_id, data, name)
			local output = vim.fn.json_decode(data)
			local issues = output["Issues"]
			local diags_by_buf = {}
			if type(issues) == "table" then
				for _, issue in ipairs(issues) do
					vim.api.nvim_command("silent! badd " .. issue.Pos.Filename)
					local bufnr = vim.fn.bufnr(issue.Pos.Filename)

					if diags_by_buf[bufnr] == nil then
						diags_by_buf[bufnr] = {}
					end

					table.insert(diags_by_buf[bufnr], {
						source = string.format("golangci-lint:%s", issue.FromLinter),
						lnum = issue.Pos.Line - 1,
						end_lnum = issue.Pos.Line - 1,
						col = issue.Pos.Column - 1,
						end_col = issue.Pos.Column - 1,
						message = issue.Text,
						severity = vim.diagnostic.severity.WARN,
						bufnr = bufnr,
					})
				end

				for bufnr, diags in pairs(diags_by_buf) do
					vim.diagnostic.reset(nil, bufnr)
					print("bufnr: " .. bufnr .. "\ndiags: " .. vim.inspect(diags))
					vim.diagnostic.set(get_diagnostic_namespace(bufnr), bufnr, diags)
				end
			end
		end,
		stdout_buffered = true,
		on_stderr = function(chan_id, data, name)
			print(vim.inspect(data))
		end,
		stderr_buffered = true,
	})
end

-- vim.api.nvim_create_user_command("GoTestFunc", function()
-- 	test_func()
-- end, {})
--
-- vim.api.nvim_create_user_command("GoTestFile", function()
-- 	test_file()
-- end, {})
--
-- vim.api.nvim_create_user_command("GoLint", function()
-- 	golanci_lint()
-- end, {})
