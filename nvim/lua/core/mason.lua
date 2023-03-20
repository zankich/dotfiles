require("mason").setup()
require("mason-lspconfig").setup({
    automatic_installation = true,
    function (server_name) -- default handler (optional)
        require("lspconfig")[server_name].setup {}
    end,
})
