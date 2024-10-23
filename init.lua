require("settings")
require("plugins")
require("mappings")
require("lsp")
require("parsers")

if not vim.g.vscode then
  require("wezterm").set_user_var('vim_keybindings_status', 'enabled')
  vim.api.nvim_create_autocmd({ 'VimLeave' }, {
    desc = 'VimLeave',
    pattern = '*',
    callback = function()
      require("wezterm").set_user_var('vim_keybindings_status', 'disabled')
    end
  })
end

