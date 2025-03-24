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
  local gitCommandFull = "git"
  if (vim.api.nvim_win_get_width(0) < 150) then
    gitCommandFull = gitCommandFull .. " -c delta.side-by-side=false"
  else
    gitCommandFull = gitCommandFull .. " -c delta.side-by-side=true"
  end
  gitCommandFull = gitCommandFull .. " " .. command
  if (gitTerm:is_open()) then
    gitTerm:send(gitCommandFull)
  else
    gitTerm:open()
    gitTerm:change_dir(vim.loop.cwd())
    gitTerm:send(gitCommandFull)
  end
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

local gitPrettyFormat = "commit %C(#FFDE59)%h%Creset %aI %C(blue)%aN%Creset %s %C(blue)%D%Creset"
local gitPrettyFormatWithDescription = gitPrettyFormat .. "%n%n%b"

return {
  keys = {
    {
      '<leader>tH',
      function()
        local count = vim.v.count > 0 and vim.v.count or 1
        vim.cmd(count .. "TermExec cmd=\"pwd\"")
        vim.schedule(function() vim.cmd(count .. "TermExec cmd=\"cd " .. utils.getPathToGitDirOr(vim.loop.cwd()) .. "\"") end)
      end,
      noremap = true, mode = 'n', desc = 'terminal Here (git root)'
    },
    {
      '<leader>th',
      function()
        local dirPath = vim.fn.expand("%:p:h"):gsub("%%20", " ")
        local count = vim.v.count > 0 and vim.v.count or 1
        vim.cmd(count .. "TermExec cmd=\"cd " .. dirPath .. "\"")
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
    {
      "<c-g>D",
      function() execGitCommand("diff --staged") end,
      noremap = true, silent = true, desc = "git diff --staged", mode = { 'n', 't' }
    },
    {
      "<c-g>d",
      function() execGitCommand("diff") end,
      noremap = true, silent = true, desc = "git diff", mode = { 'n', 't' }
    },
    -- {
    --   "<c-g>L",
    --   function() execGitCommand('log -p --pretty=format:"' .. gitPrettyFormatWithDescription .. '"') end,
    --   noremap = true, silent = true, desc = "git log", mode = { 'n', 't' }
    -- },
    {
      "<c-g>g",
      function() execGitCommand('log --graph --pretty=format:"' .. gitPrettyFormat .. '" main HEAD') end,
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
