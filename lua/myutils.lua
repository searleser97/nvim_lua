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

utils.getPathToCurrentDir = function()
  local currentFile = vim.fn.expand('%:p')
  local currentDir = vim.fn.fnamemodify(currentFile, ":h")
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

return utils
