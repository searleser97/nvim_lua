require("settings")
require("plugins")
require("mappings")

vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
  desc = 'Center When Cursor Line Significantly Changed',
  pattern = '*',
  callback = (function()
    local initialCursorPos = vim.fn.getcurpos()
    local prevLine = initialCursorPos[2]
    return function()
      local curr_cursor_pos = vim.fn.getcurpos()
      local currLine = curr_cursor_pos[2]
      if (math.abs(prevLine - currLine) > 10) then
        vim.cmd("norm! zz")
      end
      prevLine = currLine
    end
  end)()
})
