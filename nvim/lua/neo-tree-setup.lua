vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])
vim.cmd('nnoremap - :Neotree<cr>')


require("neo-tree").setup({
  filesystem = {
    hijack_netrw_behavior = "open_current",
    follow_current_file = true
  },
  event_handlers = {
    {
      event = "before_render",
      handler = function (state)
        -- add something to the state that can be used by custom components
      end
    },
    {
      event = "file_opened",
      handler = function(file_path)
        --auto close
        require("neo-tree").close_all()
      end
    },
    --{
      --event = "file_opened",
      --handler = function(file_path)
        ----clear search after opening a file
        --require("neo-tree.sources.filesystem").reset_search()
      --end
    --},
    {
      event = "file_renamed",
      handler = function(args)
        -- fix references to file
        print(args.source, " renamed to ", args.destination)
      end
    },
    {
      event = "file_moved",
      handler = function(args)
        -- fix references to file
        print(args.source, " moved to ", args.destination)
      end
    },
    {
      event = "neo_tree_buffer_enter",
      handler = function()
        vim.cmd 'highlight! Cursor blend=100'
      end
    },
    {
      event = "neo_tree_buffer_leave",
      handler = function()
        vim.cmd 'highlight! Cursor guibg=#5f87af blend=0'
      end
    },
    {
      event = "neo_tree_window_before_open",
      handler = function(args)
        print("neo_tree_window_before_open", vim.inspect(args))
      end
    },
    {
      event = "neo_tree_window_after_open",
      handler = function(args)
        vim.cmd("wincmd =")
      end
    },
    {
      event = "neo_tree_window_before_close",
      handler = function(args)
        print("neo_tree_window_before_close", vim.inspect(args))
      end
    },
    {
      event = "neo_tree_window_after_close",
      handler = function(args)
        vim.cmd("wincmd =")
      end
    }
  }
})

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>f', builtin.find_files, {})
vim.keymap.set('n', '<leader>rg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>b', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
