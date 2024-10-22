if not vim.g.vscode then
  local lsp_zero = require("lsp-zero").preset({})

  lsp_zero.on_attach(function(client, buffer)
    lsp_zero.highlight_symbol(client, buffer)
    local telescope_builtin = require('telescope.builtin')
    vim.keymap.set('n', 'gd', telescope_builtin.lsp_definitions, { noremap = true, desc = "go to definition" })
    vim.keymap.set('n', 'gi', telescope_builtin.lsp_implementations, { noremap = true, desc = "go to implementation" })
    vim.keymap.set('n', 'gr', telescope_builtin.lsp_references, { noremap = true, desc = "go to references" })
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { noremap = true, desc = "go to references" })
    vim.keymap.set('n', '<leader>sd', function()
      vim.diagnostic.open_float()
      vim.diagnostic.open_float() -- the second call moves my cursor inside the diagnostic window
    end, { noremap = true, desc = "show diagnostics" })
    vim.keymap.set('n', 'H', function()
      vim.lsp.buf.hover()
      vim.lsp.buf.hover()
    end, { noremap = true, desc = "hover info" })
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { noremap = true, desc = "code action" }) end)

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
            vim.keymap.set('n', 'gd', function() require('csharpls_extended').lsp_definitions(); end, { noremap = true, desc = "go to definition", buffer = true })
          end
        }

        require("lspconfig").csharp_ls.setup(config)
      end,
      ["lua_ls"] = function()
        local lua_opts = lsp_zero.nvim_lua_ls()
        lua_opts.settings.Lua.workspace.library = {
          vim.env.VIMRUNTIME,
          os.getenv('HOME') .. '/.config/luvit-meta'
        }
        require("lspconfig").lua_ls.setup(lua_opts)
      end
    }
  });
end
