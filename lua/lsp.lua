if not vim.g.vscode then
  local lsp = require("lsp-zero").preset({})

  lsp.on_attach(function(client, buffer)
    lsp.default_keymaps({buffer = bufnr})
  end)

  require("lspconfig").lua_ls.setup(lsp.nvim_lua_ls())
  lsp.setup()
end
