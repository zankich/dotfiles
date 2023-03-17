local M = {}

M.find_files_opts = {
  hidden = true,
}

local actions = require("telescope.actions")
require("telescope").setup({
  defaults = require('telescope.themes').get_ivy {
    mappings = {
      i = {
        ["<esc>"] = actions.close
      },
    },
  },
  pickers = {
    find_files = {
      mappings = {
        i = {
					["<C-g>"] = function(prompt_bufnr)
            local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
            local opts = vim.deepcopy(M.find_files_opts)

            if current_picker.prompt_title == "~/code" then
              opts.cwd = vim.fn.BufferRootDir()
              opts.prompt_title = vim.fn.BufferRootDir()
            else
              opts.cwd = "~/code"
              opts.prompt_title = "~/code"
            end
              
            require("telescope.actions").close(prompt_bufnr)
            require("telescope.builtin").find_files(opts)
					end,
				},
      },
    },
  },
})

require('telescope').load_extension('fzf')

local builtin = require('telescope.builtin')

function M.search_root()
  local opts = vim.deepcopy(M.find_files_opts)
  opts.cwd = vim.fn.BufferRootDir()
  opts.prompt_title = vim.fn.BufferRootDir()

  builtin.find_files(opts)
end

vim.keymap.set('n', '<leader>f', M.search_root, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>rg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>b', builtin.buffers, {})
vim.keymap.set('n', '<leader>h', builtin.help_tags, {})
