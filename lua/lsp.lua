if not vim.g.vscode then
  local lsp = require("lsp-zero").preset({})

  lsp.on_attach(function(client, buffer)
    lsp.default_keymaps({buffer = bufnr})
    local builtin = require('telescope.builtin');
    vim.keymap.set('n', 'gd', builtin.lsp_definitions)
  end)

  require("lspconfig").lua_ls.setup(lsp.nvim_lua_ls())
  lsp.setup()
end
