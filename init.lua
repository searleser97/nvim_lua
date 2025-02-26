require("settings")
require("plugins")
require("mappings")

vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
  desc = 'Center When Cursor Line Significantly Changed',
  pattern = '*',
  callback = (function()
    local initialCursorPos = vim.fn.getcurpos()
    local prevLine = initialCursorPos[2]
    local prevWindow = vim.api.nvim_get_current_win()
    return function()
      local curr_cursor_pos = vim.fn.getcurpos()
      local currLine = curr_cursor_pos[2]
      local currWindow = vim.api.nvim_get_current_win()
      if math.abs(prevLine - currLine) > 13 and prevWindow == currWindow then
        if vim.g.vscode then
          local vscode = require("vscode-neovim")
          local current_line = vim.api.nvim_win_get_cursor(0)[1]
          vscode.call("revealLine", {args = {lineNumber = current_line, at = "center"}})
        else
          vim.cmd("norm! zz")
        end
      end
      prevLine = currLine
      prevWindow = currWindow
    end
  end)()
})

if require('myutils').Is_Windows() then
  vim.api.nvim_create_autocmd('QuitPre', {
    -- the following callback blocks neovim, so no other action can occur until it finishes
    callback = function()
      os.execute('del "' .. vim.fn.stdpath("data") .. '\\shada\\main.shada.tmp.*"')
    end,
  })
end
