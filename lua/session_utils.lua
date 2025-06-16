local sessions = require("sessions")
local scan = require 'plenary.scandir'
local path = require 'plenary.path'

local session_utils = {}

session_utils.open_session_action = function()
  local files = scan.scan_dir(vim.fn.stdpath("data") .. "/sessions", { depth = 1, })
  local filenames = {}
  ---@diagnostic disable-next-line: unused-local
  for index, filepath in ipairs(files) do
    local splitpath = vim.split(filepath, path.path.sep)
    table.insert(filenames, splitpath[#splitpath])
  end
  vim.ui.select(filenames, {
    prompt = "Select a session to open:",
    format_item = function(filename)
      return string.sub(filename, 1, -9)
    end,
  }, function(selected)
    local session_name = string.sub(selected, 1, -9)
    vim.g.session_name = session_name
    sessions.load(session_name)
  end)
end

return session_utils
