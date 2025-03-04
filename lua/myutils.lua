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


return utils
