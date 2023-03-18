require('Comment').setup({
  mappings = false,
})


 vim.keymap.set('n', '<leader>/', '<Plug>(comment_toggle_linewise_current)')
