local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local conf = require"telescope.config".values

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

local function save_breakpoints(session_name)
  if not session_name or session_name == "" then
    return false
  end
  local ok, dap_bps = pcall(function() return require("dap.breakpoints").get() end)
  if not ok or vim.tbl_isempty(dap_bps) then return false end

  local save_data = {}
  for bufnr, buf_bps in pairs(dap_bps) do
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname ~= "" then
      save_data[fname] = buf_bps
    end
  end

  local filepath = vim.fn.stdpath("data") .. "/sessions/" .. session_name .. "_breakpoints.json"
  if vim.tbl_isempty(save_data) then
    vim.fn.delete(filepath)
    return true
  end
  local file = io.open(filepath, "w")
  if file then
    file:write(vim.fn.json_encode(save_data))
    file:close()
    return true
  end
  return false
end

local function load_breakpoints(session_name)
  if not session_name or session_name == "" then
    return false
  end
  local filepath = vim.fn.stdpath("data") .. "/sessions/" .. session_name .. "_breakpoints.json"
  if vim.fn.filereadable(filepath) == 0 then
    return false
  end

  local file = io.open(filepath, "r")
  if not file then return false end
  local content = file:read("*all")
  file:close()

  local success, data = pcall(vim.fn.json_decode, content)
  if not success or not data then return false end

  local ok, dap_bps = pcall(function() return require("dap.breakpoints") end)
  if not ok then return false end

  dap_bps.clear()
  for fname, buf_bps in pairs(data) do
    local bufnr = vim.fn.bufadd(fname)
    vim.fn.bufload(bufnr)
    for _, bp in ipairs(buf_bps) do
      dap_bps.set({
        condition = bp.condition,
        log_message = bp.logMessage,
        hit_condition = bp.hitCondition,
      }, bufnr, bp.line)
    end
  end
  return true
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
          save_breakpoints(vim.g.session_name)
        end

        local session_name = selected:gsub("%.session$", "")
        vim.g.session_name = session_name
        sessions.load(session_name, {})
        load_quickfix_list(session_name)
        load_breakpoints(session_name)
      end
    end)
  else
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
          if vim.g.session_name then
            save_quickfix_list(vim.g.session_name)
            save_breakpoints(vim.g.session_name)
          end
          actions.close(prompt_bufnr)
          local session_name = action_state.get_selected_entry()[1]:gsub("%.session$", "")
          vim.g.session_name = session_name
          sessions.load(session_name, {})
          load_quickfix_list(session_name)
          load_breakpoints(session_name)
        end)
        map("i", "<C-d>", function (prompt_bufnr)
          local entry = action_state.get_selected_entry()
          if not entry then return end
          local filename = entry[1]
          local session_name = filename:gsub("%.session$", "")
          local confirm = vim.fn.confirm("Delete session '" .. session_name .. "'?", "&Yes\n&No", 2)
          if confirm == 1 then
            local session_file = session_utils.sessions_dir .. path.path.sep .. filename
            local quickfix_file = session_utils.sessions_dir .. path.path.sep .. session_name .. "_quickfix.json"
            local breakpoints_file = session_utils.sessions_dir .. path.path.sep .. session_name .. "_breakpoints.json"
            vim.fn.delete(session_file)
            vim.fn.delete(quickfix_file)
            vim.fn.delete(breakpoints_file)
            if vim.g.session_name == session_name then
              vim.g.session_name = nil
            end
            actions.close(prompt_bufnr)
            session_utils.open_session_action()
          end
        end)
        return true
      end
    }):find()
  end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if vim.g.session_name then
      save_quickfix_list(vim.g.session_name)
      save_breakpoints(vim.g.session_name)
    end
  end
})

return session_utils
