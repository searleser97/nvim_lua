local M = {}

local function find_files_utils()
  local show_all_hidden = false
  local prev_cwd = nil
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

  local toggle_hidden = function()
    show_all_hidden = not show_all_hidden
  end

  local launch_find_files_in_cwd = function(cwd)
    prev_cwd = cwd
    require('telescope.builtin').find_files({
      cwd = cwd
    })
  end

  local launch_find_files_in_prev_cwd = function()
    launch_find_files_in_cwd(prev_cwd)
  end

  return {
    toggle_hidden = toggle_hidden,
    get_find_files_command = get_find_files_command,
    launch_find_files_in_prev_cwd = launch_find_files_in_prev_cwd,
    launch_find_files_in_cwd = launch_find_files_in_cwd
  }
end

M.find_files_utils = find_files_utils()

return M
