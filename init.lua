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
      if vim.bo.buftype ~= 'terminal' and math.abs(prevLine - currLine) > 13 and prevWindow == currWindow then
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
    callback = function()

      local log_file_path = vim.fn.stdpath("data") .. "\\shada_cleanup.log"
      local log_file = io.open(log_file_path, "a")
      if log_file then
        log_file:write(os.date() .. " - Cleanup started\n")
        log_file:close()
      end
      os.execute('del "' .. vim.fn.stdpath("data") .. '\\shada\\main.shada.tmp.*"')
      -- delete all tmp shada tmp files
      -- for i = string.byte('f'), string.byte('z') do
      --   local shadafile = vim.fn.stdpath("data") .. "\\shada\\main.shada.tmp." .. string.char(i)
      --   local file = io.open(shadafile, "w")
      --   if file then
      --     file:write("Dummy content for " .. shadafile)
      --     file:close()
      --   end
      -- end
      -- vim.opt.shadafile = vim.fn.stdpath("data") .. "\\shada\\main.shada.tmp." .. os.time()
      -- local ok, err = pcall(vim.cmd, 'wshada')
      -- if not ok and err:match("E138: main%.shada%.tmp%.%d+ files exist") then
        -- vim.opt.shadafile = vim.fn.stdpath("data") .. "\\shada\\main.shada.tmp." .. os.time()
        -- vim.cmd('wshada')
      -- end
      log_file = io.open(log_file_path, "a")
      if log_file then
        log_file:write(os.date() .. " - Cleanup completed\n")
        log_file:close()
      end
    end
  })
end
