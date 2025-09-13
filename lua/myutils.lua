local utils = { }
utils.getPathToGitDirOr = function(defaultPath)
  local gitCommandResult = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if gitCommandResult.code == 0 then
    return gitCommandResult.stdout:gsub("\n", "")
  else
    return defaultPath
  end
end

utils.Is_Windows = function()
  return package.config:sub(1,1) == "\\";
end

-- function that will search current directory and parent directories trying to find a set of files with given extension or name, like "package.json" or "<projectname>.csproj"
utils.getPathToProjectOr = function(defaultPath, projectFilePatterns)
  local currentFile = vim.fn.expand('%:p')
  local currentDir = vim.fn.fnamemodify(currentFile, ":h")
  local found = false

  while not found do
    for _, pattern in ipairs(projectFilePatterns) do
      local files = vim.fn.glob(currentDir .. "/" .. pattern)
      if #files > 0 then
        found = true
        return currentDir
      end
    end
    currentDir = vim.fn.fnamemodify(currentDir, ":h")
    if currentDir == "" then
      break
    end
  end

  return defaultPath
end

utils.getPathToCurrentDir = function(ignore)
  local currentFile = vim.fn.expand('%:p')
  local currentDir = vim.fn.fnamemodify(currentFile, ":h")
  local path_sep = package.config:sub(1,1)
  -- Default ignore patterns if none provided
  ignore = ignore or {}

  -- Check if current directory ends with any of the ignore patterns
  for _, pattern in ipairs(ignore) do
    local is_ignored = string.match(currentDir, path_sep .. pattern .. "$")
    if is_ignored then
      return vim.fn.fnamemodify(currentDir, ":h")
    end
  end

  return currentDir
end

utils.my_open = function(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local actions = require("telescope.actions")
  local fb_utils = require("telescope._extensions.file_browser.utils")
  local quiet = action_state.get_current_picker(prompt_bufnr).finder.quiet
  local selections = fb_utils.get_selected_files(prompt_bufnr, true)
  if vim.tbl_isempty(selections) then
    fb_utils.notify("actions.open", { msg = "No selection to be opened!", level = "INFO", quiet = quiet })
    return
  end

  for _, selection in ipairs(selections) do
    vim.cmd(string.format('silent !start "%s"', selection:absolute()))
  end
  actions.close(prompt_bufnr)
end

utils.get_wezterm_dimensions = function()
  local path = vim.fn.stdpath("data") .. "/wezterm_pixels.txt"

  if not vim.fn.filereadable(path) == 1 then
    vim.notify("Pixel dimension file not found: " .. path, vim.log.levels.WARN)
    return
  end

  local line = vim.fn.readfile(path)[1]
  if not line then
    vim.notify("Pixel dimension file is empty", vim.log.levels.WARN)
    return
  end

  local width = tonumber(line:match("^(%d+)x%d+"))
  local height = tonumber(line:match("^%d+x(%d+)"))

  if width and height then
    return { width = width, height = height };
  else
    vim.notify("Failed to parse pixel dimensions from: " .. line, vim.log.levels.ERROR)
  end
end

return utils
