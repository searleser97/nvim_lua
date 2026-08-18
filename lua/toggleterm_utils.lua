local utils = require('myutils')
local gitTermConfig =  {
  autochdir = true,
  direction = "float",
  float_opts = {
    border = "double",
  },
  count = 9,
}

local _getGitTerm = function()
  local gitTerm = nil
  return function()
    if gitTerm == nil then
      gitTerm = require('toggleterm.terminal').Terminal:new(gitTermConfig);
    end
    return gitTerm
  end
end

local getGitTerm = _getGitTerm()

local execGitCommand = function(command)
  local gitTerm = getGitTerm()
  -- -S to disable line wrapping
  -- -N to show line numbers
  -- -i to ignore case when searching
  local gitCommandFull = "git -c core.pager='less -S -N -i'"
  -- if (vim.api.nvim_win_get_width(0) < 150) then
  --   gitCommandFull = gitCommandFull .. " -c delta.side-by-side=false"
  -- else
  --   gitCommandFull = gitCommandFull .. " -c delta.side-by-side=true"
  -- end
  gitCommandFull = gitCommandFull .. " " .. command
  if (gitTerm:is_open()) then
    gitTerm:send(gitCommandFull)
  else
    gitTerm:open()
    gitTerm:change_dir(vim.uv.cwd())
    gitTerm:send(gitCommandFull)
  end
end

local function git_output(args)
  local command = { 'git', '-C', vim.uv.cwd() }
  vim.list_extend(command, args)

  local output = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    return nil
  end

  output = vim.trim(output)
  return output ~= '' and output or nil
end

local function get_principal_branch()
  local remotes = vim.split(git_output({ 'remote' }) or '', '\n', { trimempty = true })
  for index, remote in ipairs(remotes) do
    remotes[index] = vim.trim(remote)
  end
  table.sort(remotes, function(left, right)
    return left == 'origin' and right ~= 'origin'
  end)

  for _, remote in ipairs(remotes) do
    local default_branch = git_output({
      'symbolic-ref',
      '--quiet',
      '--short',
      'refs/remotes/' .. remote .. '/HEAD',
    })
    if default_branch then
      return default_branch
    end
  end

  local candidates = { 'main', 'master', 'dev', 'develop', 'trunk' }

  for _, branch in ipairs(candidates) do
    if branch and git_output({ 'rev-parse', '--verify', '--quiet', 'refs/heads/' .. branch }) then
      return branch
    end
  end

  for _, branch in ipairs(candidates) do
    if branch then
      for _, remote in ipairs(remotes) do
        local remote_branch = remote .. '/' .. branch
        if git_output({ 'rev-parse', '--verify', '--quiet', 'refs/remotes/' .. remote_branch }) then
          return remote_branch
        end
      end
    end
  end

  return git_output({ 'symbolic-ref', '--quiet', '--short', 'HEAD' })
end


function OpenToggleTerms(ids_to_ignore)
  local maxBufferIndex = vim.fn.bufnr("$")
  local toggleTermBuffers = vim.fn.filter(vim.fn.range(1, maxBufferIndex), function(_, val)
    local termId = string.match(string.match(vim.fn.bufname(val), "toggleterm#%d+") or "", "%d+")
      return termId ~= nil and ids_to_ignore[termId] == nil;
  end)
  local corruptedBuffersExcluded = vim.fn.filter(toggleTermBuffers, function (_, val)
    return vim.fn.getbufinfo(val)[1].variables.term_title ~= "exit";
  end)
  return corruptedBuffersExcluded;
end

function ToggleAllTerms(ignore)
  local openTerms = OpenToggleTerms(ignore)
  for _, value in pairs(openTerms) do
    local termId = string.match(string.match(vim.fn.bufname(value), "toggleterm#%d+"), "%d+")
    vim.cmd(termId .."ToggleTerm")
  end
end

local function is_buffer_visible(bufnr)
  -- Get the list of windows displaying the buffer
  local windows = vim.fn.win_findbuf(bufnr)
  -- If the list is not empty, the buffer is visible
  return #windows > 0
end

function CloseAllVisibleTerms(ignore)
  local allTerms = require('toggleterm.terminal').get_all(false)
  for _, term in ipairs(allTerms) do
    if is_buffer_visible(term.bufnr) and ignore[term.id] == nil then
      term:close()
    end
  end
end

local function directory_command(path)
  if utils.Is_Windows() then
    return "Set-Location -LiteralPath '" .. path:gsub("'", "''") .. "'"
  end
  return "cd -- " .. vim.fn.shellescape(path)
end

local function open_terminal_in(path)
  path = vim.fs.normalize(path)
  if vim.fn.isdirectory(path) ~= 1 then
    vim.notify("Terminal directory does not exist: " .. path, vim.log.levels.ERROR)
    return
  end

  local count = vim.v.count > 0 and vim.v.count or 1
  require('toggleterm').exec(directory_command(path), count, nil, nil, nil, nil, false, true)
end

local gitPrettyFormat = "%C(#FFDE59)%h%Creset %aI %C(blue)%aN%Creset %s %C(red)%D%Creset"
local gitPrettyFormatWithDescription = gitPrettyFormat .. "%n%n%b"

return {
  keys = {
    {
      '<leader>tH',
      function()
        open_terminal_in(utils.getPathToGitDirOr(vim.loop.cwd()))
      end,
      noremap = true, mode = 'n', desc = 'terminal Here (git root)'
    },
    {
      '<leader>th',
      function()
        local dirPath = vim.fn.expand("%:p:h"):gsub("%%20", " ")
        open_terminal_in(dirPath)
      end,
      noremap = true, mode =  'n', desc = 'terminal here (file)'
    },
    {
      '<c-t>',
      function()
        if vim.v.count ~= 0 then
          vim.cmd(vim.v.count .. "ToggleTerm")
        else
          local openTermsCount = #OpenToggleTerms({ ["".. getGitTerm().id] = true })
          if openTermsCount < 1 then
            vim.cmd("1ToggleTerm")
          else
            ToggleAllTerms({ ["" .. getGitTerm().id] = true })
          end
        end
      end,
      noremap = true, mode = 'n'
    },
    -- {
    --   "<c-g>D",
    --   function() execGitCommand("diff --staged") end,
    --   noremap = true, silent = true, desc = "git diff --staged", mode = { 'n', 't' }
    -- },
    -- {
    --   "<c-g>d",
    --   function() execGitCommand("diff") end,
    --   noremap = true, silent = true, desc = "git diff", mode = { 'n', 't' }
    -- },
    -- {
    --   "<c-g>L",
    --   function() execGitCommand('log -p --pretty=format:"' .. gitPrettyFormatWithDescription .. '"') end,
    --   noremap = true, silent = true, desc = "git log", mode = { 'n', 't' }
    -- },
    {
      "<c-g>l",
      function() execGitCommand('log --pretty=format:"' .. gitPrettyFormat .. '" HEAD') end,
      noremap = true, silent = true, desc = "git graph", mode = { 'n', 't' }
    },
    {
      "<c-g>g",
      function()
        local principal_branch = get_principal_branch()
        local revisions = principal_branch and ('HEAD ' .. vim.fn.shellescape(principal_branch)) or 'HEAD'
        execGitCommand('log --pretty=format:"' .. gitPrettyFormat .. '" ' .. revisions .. ' --graph')
      end,
      noremap = true, silent = true, desc = "git graph", mode = { 'n', 't' }
    },
    {
      '<c-g>c',
      function() execGitCommand("commit") end,
      noremap = true, desc = "git commit", mode = { 'n', 't' }
    },
    {
      '<c-g>a',
      function() execGitCommand("commit --amend") end,
      noremap = true, desc = "git commit --amend", mode = { 'n', 't' }
    },
    {
      '<c-g>P',
      function() execGitCommand("push") end,
      noremap = true, desc = "git push", mode = { 'n', 't' }
    },
    {
      '<c-g>p',
      function() execGitCommand("pull") end,
      noremap = true, desc = "git git pull", mode = { 'n', 't' }
    },
    {
      '<c-g>F',
      function() execGitCommand("push --force-with-lease") end,
      noremap = true, desc = "git push force", mode = { 'n', 't' }
    },
    {
      '<c-g>f',
      function() execGitCommand("fetch") end,
      noremap = true, desc = "git fetch", mode = { 'n', 't' }
    },
    -- {
    --   '<c-g>H', function()
    --     execGitCommand(
    --       'log -p --follow --pretty=format:"' .. gitPrettyFormatWithDescription .. '" -- ' .. vim.api.nvim_buf_get_name(0)
    --     )
    --   end,noremap = true, desc = "git file history", mode = {'n', 't'}
    -- },
    {
      '<c-g>t',
      function()
        getGitTerm():toggle()
      end,
      noremap = true, desc = "git terminal", mode = { 'n', 't' }
    },
    {
      '<c-t>',
      function() CloseAllVisibleTerms({}) end,
      desc = "toggle all terminals", mode = 't'
    }
  }
}
