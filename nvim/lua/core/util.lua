local M = {}

function M.reload()
    require("plenary.reload").reload_module("core")
    require("core")
    print("config reloaded!")
end

function M.bufferRootDir()
    local currentdir = vim.fn.expand('%:p:h')
    local file = io.popen('git -C ' .. currentdir ..
                              ' rev-parse --show-toplevel 2> /dev/null', 'r')
    local output = file:read('*line')
    file:close()

    if output and not output:find(':/') then
        return vim.fn.resolve(output)
    else
        return vim.fn.resolve(currentdir)
    end
end

vim.api.nvim_create_autocmd("BufEnter", {command = vim.cmd.lcd(M.bufferRootDir())})
vim.keymap.set('n', '<space>r', M.reload, {silent = true, noremap = true})

return M
