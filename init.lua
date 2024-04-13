require("settings")
require("plugins")
local mappings = require("mappings")
require("lsp")
require("parsers")

if not vim.g.vscode then
  vim.cmd("WhichKey<cr>")
  vim.schedule(mappings.open_session_action)
end

