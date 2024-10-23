local utils = { }
utils.getPathToGitDirOr = function(defaultPath)
  local gitCommandResult = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if gitCommandResult.code == 0 then
    return gitCommandResult.stdout:gsub("\n", "")
  else
    return defaultPath
  end
end

return utils
