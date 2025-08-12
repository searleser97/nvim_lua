local function get_node_bin_path(major_version)
  local is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1
  local nvm_dir
  local versions_dir
  local list_cmd
  local path_sep = is_windows and "\\" or "/"
  if is_windows then
    nvm_dir = vim.env.NVM_HOME or (vim.env.APPDATA .. "\\nvm")
    versions_dir = nvm_dir
    list_cmd = 'dir /b "' .. versions_dir .. '" 2>nul'
  else
    nvm_dir = vim.env.NVM_DIR or (vim.env.HOME .. "/.nvm")
    versions_dir = nvm_dir .. "/versions/node"
    list_cmd = "ls -1 " .. versions_dir .. " 2>/dev/null"
  end
  local handle = io.popen(list_cmd)
  if not handle then return nil end
  local highest_version = nil
  for line in handle:lines() do
    local version = line:match("^v?(.+)$")
    if version then
      local major = version:match("^(%d+)")
      if major and tonumber(major) == tonumber(major_version) then
        highest_version = version
      end
    end
  end
  handle:close()
  if not highest_version then return nil end
  if is_windows then
    return versions_dir .. path_sep .. "v" .. highest_version
  else
    return versions_dir .. path_sep .. "v" .. highest_version .. path_sep .. "bin"
  end
end

local node_bin_path = get_node_bin_path("22")
if node_bin_path then
  vim.env.PATH = node_bin_path .. ":" .. vim.env.PATH
end

require("settings")
require("plugins")
require("mappings")

-- vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
--   desc = 'Center When Cursor Line Significantly Changed',
--   pattern = '*',
--   callback = (function()
--     local initialCursorPos = vim.fn.getcurpos()
--     local prevLine = initialCursorPos[2]
--     local prevWindow = vim.api.nvim_get_current_win()
--     return function()
--       local curr_cursor_pos = vim.fn.getcurpos()
--       local currLine = curr_cursor_pos[2]
--       local currWindow = vim.api.nvim_get_current_win()
--       if vim.bo.buftype ~= 'terminal' and vim.bo.buftype ~= 'nofile' and math.abs(prevLine - currLine) > 13 and prevWindow == currWindow then
--         if vim.g.vscode then
--           local vscode = require("vscode-neovim")
--           local current_line = vim.api.nvim_win_get_cursor(0)[1]
--           vscode.call("revealLine", {args = {lineNumber = current_line, at = "center"}})
--         else
--           vim.cmd("norm! zz")
--         end
--       end
--       prevLine = currLine
--       prevWindow = currWindow
--     end
--   end)()
-- })

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
