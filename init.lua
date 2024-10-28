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
        vim.cmd("norm! zz")
      end
      prevLine = currLine
      prevWindow = currWindow
    end
  end)()
})
