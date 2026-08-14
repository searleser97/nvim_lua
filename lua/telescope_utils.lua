local M = {}

local function find_files_utils()
  local show_all_hidden = false
  local get_find_files_command = function()
    local cmd = {
      "rg",
      "--files",
    }
    if show_all_hidden then
      table.insert(cmd, "--no-ignore")
      table.insert(cmd, "--hidden")
    end
    vim.list_extend(cmd, {
      "--follow", -- follow symlinks
      "--glob",
      "!**/.git/*",
    })
    return cmd
  end

  local toggle_hidden = function(prompt_bufnr)
    show_all_hidden = not show_all_hidden
    if not prompt_bufnr then return end

    local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
    local finder = require("telescope.finders").new_oneshot_job(get_find_files_command(), {
      cwd = current_picker.finder.cwd,
      entry_maker = current_picker.finder.entry_maker,
    })
    current_picker:refresh(finder, {
      reset_prompt = false,
      multi = current_picker._multi,
    })
  end

  local launch_find_files_in_cwd = function(cwd)
    require('telescope.builtin').find_files({
      cwd = cwd
    })
  end

  return {
    toggle_hidden = toggle_hidden,
    get_find_files_command = get_find_files_command,
    launch_find_files_in_cwd = launch_find_files_in_cwd
  }
end

M.find_files_utils = find_files_utils()

local function get_windows_drives()
  local drives = {}
  for code = string.byte("A"), string.byte("Z") do
    local drive = string.char(code) .. ":\\"
    if vim.fn.isdirectory(drive) == 1 then
      table.insert(drives, drive)
    end
  end
  return drives
end

local function normalize_windows_path(path)
  local normalized = vim.fs.normalize(path):gsub("/", "\\")
  if #normalized > 3 then
    normalized = normalized:gsub("\\+$", "")
  end
  return normalized:lower()
end

local function restore_file_browser(current_picker, finder)
  local fb_utils = require("telescope._extensions.file_browser.utils")
  current_picker:refresh(finder, {
    new_prefix = fb_utils.relative_path_prefix(finder),
    reset_prompt = true,
    multi = current_picker._multi,
  })
  fb_utils.redraw_border_title(current_picker)
end

local function restore_file_browser_mappings(prompt_bufnr)
  vim.keymap.set({ "i", "n" }, "<CR>", function()
    M.file_browser_select_default(prompt_bufnr)
  end, {
    buffer = prompt_bufnr,
    silent = true,
  })
  vim.keymap.set({ "i", "n" }, "<2-LeftMouse>", function()
    M.file_browser_double_click(prompt_bufnr)
  end, {
    buffer = prompt_bufnr,
    silent = true,
  })
end

local function open_selected_drive(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local drive_finder = current_picker.finder
  local selection = action_state.get_selected_entry()
  if not selection then return end

  local file_browser_finder = drive_finder.file_browser_finder
  file_browser_finder.path = selection.value
  file_browser_finder.forward_history = {}
  restore_file_browser_mappings(prompt_bufnr)
  restore_file_browser(current_picker, file_browser_finder)
end

local function open_clicked_drive(prompt_bufnr)
  local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
  local mouse = vim.fn.getmousepos()
  if mouse.winid ~= current_picker.results_win then return end

  vim.schedule(function()
    current_picker:set_selection(mouse.line - 1)
    open_selected_drive(prompt_bufnr)
  end)
end

local function show_windows_drives(prompt_bufnr, origin)
  local action_state = require("telescope.actions.state")
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local file_browser_finder = current_picker.finder.drive_mode
      and current_picker.finder.file_browser_finder
    or current_picker.finder
  local Path = require("plenary.path")

  local drive_finder = require("telescope.finders").new_table({
    results = get_windows_drives(),
    entry_maker = function(drive)
      return {
        value = drive,
        ordinal = drive,
        display = drive,
        path = drive,
        filename = drive,
        Path = Path:new(drive),
      }
    end,
  })
  drive_finder.drive_mode = true
  drive_finder.drive_origin = origin
  drive_finder.file_browser_finder = file_browser_finder

  current_picker:refresh(drive_finder, {
    reset_prompt = true,
    multi = current_picker._multi,
  })
  vim.keymap.set({ "i", "n" }, "<CR>", function()
    open_selected_drive(prompt_bufnr)
  end, {
    buffer = prompt_bufnr,
    silent = true,
  })
  vim.keymap.set({ "i", "n" }, "<2-LeftMouse>", function()
    open_clicked_drive(prompt_bufnr)
  end, {
    buffer = prompt_bufnr,
    silent = true,
  })
  if current_picker.results_border then
    current_picker.results_border:change_title("Drives")
  end
end

function M.file_browser_select_default(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local finder = current_picker.finder
  local entry = action_state.get_selected_entry()

  if not finder.drive_mode and entry and entry.path then
    local current_path = normalize_windows_path(finder.path)
    local parent_path = normalize_windows_path(vim.fs.dirname(current_path))
    if normalize_windows_path(entry.path) == parent_path then
      M.file_browser_parent(prompt_bufnr)
      return
    end
  end

  require("telescope.actions").select_default(prompt_bufnr)
end

function M.file_browser_double_click(prompt_bufnr)
  local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
  local mouse = vim.fn.getmousepos()
  if mouse.winid ~= current_picker.results_win then return end

  vim.schedule(function()
    current_picker:set_selection(mouse.line - 1)
    M.file_browser_select_default(prompt_bufnr)
  end)
end

function M.file_browser_parent(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local fb_actions = require("telescope").extensions.file_browser.actions
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local finder = current_picker.finder
  if finder.drive_mode then return end

  local current_path = normalize_windows_path(finder.path)
  local parent_path = normalize_windows_path(vim.fs.dirname(current_path))

  if current_path ~= parent_path then
    finder.forward_history = finder.forward_history or {}
    table.insert(finder.forward_history, finder.path)
    fb_actions.goto_parent_dir(prompt_bufnr)
    return
  end

  show_windows_drives(prompt_bufnr, finder.path)
end

function M.file_browser_forward(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local finder = current_picker.finder
  if finder.drive_mode then
    if not finder.drive_origin then
      vim.notify("No forward directory", vim.log.levels.INFO)
      return
    end

    local file_browser_finder = finder.file_browser_finder
    file_browser_finder.path = finder.drive_origin
    restore_file_browser_mappings(prompt_bufnr)
    restore_file_browser(current_picker, file_browser_finder)
    return
  end

  local history = finder.forward_history
  if not history or #history == 0 then
    vim.notify("No forward directory", vim.log.levels.INFO)
    return
  end

  local current_path = normalize_windows_path(finder.path)
  for index = #history, 1, -1 do
    if normalize_windows_path(history[index]) == current_path then
      for _ = #history, index, -1 do
        table.remove(history)
      end
      break
    end
  end

  if #history == 0 then
    vim.notify("No forward directory", vim.log.levels.INFO)
    return
  end

  local target_path = history[#history]
  if normalize_windows_path(vim.fs.dirname(normalize_windows_path(target_path))) ~= current_path then
    finder.forward_history = {}
    vim.notify("No forward directory", vim.log.levels.INFO)
    return
  end

  table.remove(history)
  finder.path = target_path
  restore_file_browser(current_picker, finder)
end

function M.file_browser_backspace(prompt_bufnr)
  local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
  if current_picker:_get_prompt() == "" then
    M.file_browser_parent(prompt_bufnr)
    return
  end

  require("telescope").extensions.file_browser.actions.backspace(prompt_bufnr)
end

function M.open_file_browser_anywhere()
  require("telescope").extensions.file_browser.file_browser({
    cwd = vim.loop.cwd(),
  })
  show_windows_drives(vim.api.nvim_get_current_buf(), nil)
end

return M
