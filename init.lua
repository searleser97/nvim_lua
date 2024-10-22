require("settings")
require("plugins")
local mappings = require("mappings")
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
  if (vim.fn.argc() == 0) then
    vim.schedule(mappings.open_session_action)
  end
end

