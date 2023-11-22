if not vim.g.vscode then
  local lsp_zero = require("lsp-zero").preset({})

  lsp_zero.on_attach(function(client, buffer)
    lsp_zero.default_keymaps({ buffer = buffer })
    local telescope_builtin = require('telescope.builtin')
    vim.keymap.set('n', 'gd', telescope_builtin.lsp_definitions, { noremap = true, desc = "go to definition" })
  end)

  require("mason").setup({})
  require("mason-lspconfig").setup({
    handlers = {
      lsp_zero.default_setup,
      ["csharp_ls"] = function()
        local config = {
          handlers = {
            ["textDocument/definition"] = require('csharpls_extended').handler,
          },
          on_attach = function (client, bufnr)
            vim.keymap.set('n', 'gd', function() print("eeoo"); require('csharpls_extended').lsp_definitions(); end, { noremap = true, desc = "go to definition", buffer = true })
          end
        }

        require("lspconfig").csharp_ls.setup(config)
      end,
      ["lua_ls"] = function()
        require("lspconfig").lua_ls.setup(lsp_zero.nvim_lua_ls())
      end
    }
  });
end
