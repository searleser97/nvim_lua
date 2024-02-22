require("settings")
require("plugins")
require("mappings")
require("lsp")
require("parsers")

if not vim.g.vscode then
  vim.cmd("WhichKey<cr>")
end

