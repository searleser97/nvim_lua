local sessions = require("sessions")
local scan = require 'plenary.scandir'
local path = require 'plenary.path'

local session_utils = {}

-- Function to normalize a path into a filesystem-safe session name
session_utils.normalize_session_name = function(directory_path)
  return vim.fn.fnamemodify(directory_path, ":p")
    :gsub("/$", "")                           -- Remove trailing slash
    :gsub("[/\\:*?\"<>|]", "_")              -- Replace problematic chars with underscores
    :gsub("^_+", "")                         -- Remove leading underscores
end

local function save_quickfix_list(session_name)
  if not session_name or session_name == "" then
    return false
  end
  local qflist = vim.fn.getqflist()
  if #qflist == 0 then
    return true
  end

  local filepath = vim.fn.stdpath("data") .. "/sessions/" .. session_name .. "_quickfix.json"
  local file = io.open(filepath, "w")
  if file then
    file:write(vim.fn.json_encode(qflist))
    file:close()
    return true
  end
  return false
end

local function load_quickfix_list(session_name)
  if not session_name or session_name == "" then
    return false
  end
  local filepath = vim.fn.stdpath("data") .. "/sessions/" .. session_name .. "_quickfix.json"
  if vim.fn.filereadable(filepath) == 0 then
    return false
  end

  local file = io.open(filepath, "r")
  if not file then
    return false
  end

  local content = file:read("*all")
  file:close()

  local success, qflist = pcall(vim.fn.json_decode, content)
  if success and qflist and #qflist > 0 then
    vim.fn.setqflist(qflist, 'r')
    return true
  end
  return false
end

session_utils.sessions_dir = vim.fn.stdpath("data") .. "/sessions"

session_utils.open_session_action = function()
  if vim.fn.isdirectory(session_utils.sessions_dir) == 0 then
    vim.fn.mkdir(session_utils.sessions_dir, "p")
  end
  local files = scan.scan_dir(session_utils.sessions_dir, { depth = 1, })
  local filenames = {}
  ---@diagnostic disable-next-line: unused-local
  for index, filepath in ipairs(files) do
    local splitpath = vim.split(filepath, path.path.sep)
    local filename = splitpath[#splitpath]
    -- Only include files with .session extension
    if filename:match("%.session$") then
      table.insert(filenames, filename)
    end
  end
  local useNativePicker = false;
  if useNativePicker then
    vim.ui.select(filenames, {
      prompt = "Select a session to open:",
      format_item = function(filename)
        local session_name = filename
        local home_dir_normalized = session_utils.normalize_session_name(os.getenv("HOME"))
        return session_name:gsub("^" .. vim.pesc(home_dir_normalized) .. "_", ""):gsub("%.session$", "")
      end,
    }, function(selected)
      if selected then
        if vim.g.session_name then
          save_quickfix_list(vim.g.session_name)
        end

        local session_name = selected:gsub("%.session$", "")
        vim.g.session_name = session_name
        sessions.load(session_name, {})
        load_quickfix_list(session_name)
      end
    end)
  else
    local MiniPick = require('mini.pick')
    MiniPick.ui_select(filenames, {
      prompt = "Select a session to open:",
      format_item = function(filename)
        local session_name = filename
        local home_dir_normalized = session_utils.normalize_session_name(os.getenv("HOME"))
        return session_name:gsub("^" .. vim.pesc(home_dir_normalized) .. "_", ""):gsub("%.session$", "")
      end,
    }, function(selected)
      if selected then
        if vim.g.session_name then
          save_quickfix_list(vim.g.session_name)
        end

        local session_name = selected:gsub("%.session$", "")
        vim.g.session_name = session_name
        sessions.load(session_name, {})
        load_quickfix_list(session_name)
      end
    end)
  end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if vim.g.session_name then
      save_quickfix_list(vim.g.session_name)
    end
  end
})

return session_utils
