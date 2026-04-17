local function get_node_bin_path(major_version)
  local is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1
  local path_sep = is_windows and "\\" or "/"
  local versions_dir

  if is_windows then
    versions_dir = vim.env.HOME .. "\\scoop\\apps\\nvm\\current\\nodejs"
  else
    versions_dir = vim.env.HOME .. "/.nvm/versions/node"
  end

  local handle = vim.uv.fs_scandir(versions_dir)
  if not handle then return nil end

  local target_match = nil
  local highest_match = nil
  local highest_major, highest_minor, highest_patch = 0, 0, 0

  local name = vim.uv.fs_scandir_next(handle)
  while name do
    local version = name:match("^v?(.+)$")
    if version then
      local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)")
      if major then
        major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)
        if major_version and major == tonumber(major_version) then
          target_match = version
        end
        if major > highest_major
          or (major == highest_major and minor > highest_minor)
          or (major == highest_major and minor == highest_minor and patch > highest_patch) then
          highest_major, highest_minor, highest_patch = major, minor, patch
          highest_match = version
        end
      end
    end
    name = vim.uv.fs_scandir_next(handle)
  end

  local chosen = target_match or highest_match
  if not chosen then return nil end

  if is_windows then
    return versions_dir .. path_sep .. "v" .. chosen
  else
    return versions_dir .. path_sep .. "v" .. chosen .. path_sep .. "bin"
  end
end

local node_bin_path = get_node_bin_path("24")
if node_bin_path then
  vim.env.PATH = node_bin_path .. ":" .. vim.env.PATH
end

require("settings")
require("plugins")
require("mappings")

if vim.g.copilot_mode then
  vim.schedule(function()
    require('cli_chat').open_chat()
    vim.cmd('tabclose 1')
  end)
end

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
