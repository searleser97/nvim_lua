local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local conf = require"telescope.config".values

local sessions = require("sessions")
local scan = require'plenary.scandir'
local path = require'plenary.path'

local session_utils = {}

session_utils.open_session_action = function ()
  local files = scan.scan_dir(vim.fn.stdpath("data") .. "/sessions", { depth = 1, })
  local filenames = {}
---@diagnostic disable-next-line: unused-local
  for index, filepath in ipairs(files) do
    local splitpath = vim.split(filepath, path.path.sep)
    table.insert(filenames, splitpath[#splitpath])
  end
  pickers.new({}, {
    previewer = false,
    prompt_title = "Open Session",
    finder = finders.new_table({
      results = filenames,
      entry_maker = make_entry.gen_from_file({})
    }),
    sorter = conf.file_sorter(),
    attach_mappings = function (_, map)
      map("i", "<cr>", function (prompt_bufnr)
        actions.close(prompt_bufnr)
        local session_name = string.sub(action_state.get_selected_entry()[1], 1, -9)
        vim.g.session_name = session_name
        sessions.load(session_name)
      end)
      return true
    end
  }):find()
end

return session_utils
