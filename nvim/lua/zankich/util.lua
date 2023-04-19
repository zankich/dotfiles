local M = {}

function M.reload()
    require("plenary.reload").reload_module("zankich")
    require("zankich")
    print("config reloaded!")
end

function M.bufferRootDirForFile(fi)
    local currentdir = vim.fn.fnamemodify(fi, vim.fn.expand(':p:h'))
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

function M.bufferRootDir(fi)
  local currentdir

    if fi == nil then
    currentdir = vim.fn.fnamemodify(fi, vim.fn.expand(':p:h'))
  else
    currentdir = vim.fn.expand('%:p:h')
  end
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

function M.filePathFromBufferRootDir()
    local rootDir = M.bufferRootDir()
    local currentDir = vim.fn.fnamemodify(rootDir, ':p:h:t')
    local relativePath = vim.fn.fnamemodify(vim.fn.expand('%h'),
                                            ':.' .. rootDir .. ':')
    return currentDir .. '/' .. relativePath
end

vim.api.nvim_create_autocmd("BufEnter",
                            {command = vim.cmd.lcd(M.bufferRootDir())})
vim.keymap.set('n', '<space>r', M.reload, {silent = true, noremap = true})

return M
