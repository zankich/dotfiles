local lualine = require('lualine')

lualine.setup({
    options = {refresh = {}, theme = 'base16', globalstatus = false},
    sections = {
        lualine_c = {
            {"require('zankich.util').filePathFromBufferRootDir()", padding = 2}
        }
    },
    -- sections = {lualine_c = {{'filename', path = 1, padding = 2}}},
    inactive_sections = {
        lualine_c = {
            {"require('zankich.util').filePathFromBufferRootDir()", padding = 2}
        }
    },
    -- inactive_winbar = {lualine_c = {{'filename', path = 1}}},
    -- inactive_sections = {},
    -- inactive_winbar = {},
    tabline = {
        lualine_c = {{'filename', path = 3, padding = 2}},
        lualine_z = {
            {
                'tabs',
                mode = 2,
                padding = 2,
                fmt = function(name, context)

                    local buflist = vim.fn.tabpagebuflist(context.tabnr)
                    local winnr = vim.fn.tabpagewinnr(context.tabnr)
                    local bufnr = buflist[winnr]
                    local fileName = vim.api.nvim_buf_get_name(bufnr)

                    return vim.fn.fnamemodify(
                               require('zankich.util').bufferRootDir(fileName),
                               ':p:h:t')

                end
            }
        }
    },
    extensions = {'quickfix', 'nvim-tree', 'trouble'}
})

-- vim.api.nvim_create_autocmd('CursorMoved', {callback = lualine.refresh})
