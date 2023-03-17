local M = {}

function M.reload()
  require("plenary.reload").reload_module("core")
  require("core")
  print("config reloaded!")
end

vim.keymap.set('n', '<space>r', M.reload, { silent = true, noremap = true })
