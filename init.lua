require("settings")
require("plugins")
local mappings = require("mappings")
require("lsp")
require("parsers")

if not vim.g.vscode then
  if (vim.fn.argc() == 0) then
    vim.schedule(mappings.open_session_action)
  end
end

