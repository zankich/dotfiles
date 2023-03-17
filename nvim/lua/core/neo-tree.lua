vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])
vim.cmd('nnoremap - :Neotree toggle=true<cr>')

require("neo-tree").setup({
  filesystem = {
    hijack_netrw_behavior = "open_current",
    follow_current_file = true,
    filtered_items = {
      visible = true,
    }
  },
  event_handlers = {
    {
      event = "file_opened",
      handler = function(file_path)
        require("neo-tree").close_all()
      end
    },
    {
      event = "file_renamed",
      handler = function(args)
        print(args.source, " renamed to ", args.destination)
      end
    },
    {
      event = "file_moved",
      handler = function(args)
        print(args.source, " moved to ", args.destination)
      end
    },
  }
})
