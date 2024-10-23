vim.cmd("unmap [%")

if package.config:sub(1,1) == "\\" then
  vim.keymap.set({'n', 'x'}, '<C-c>', '"*y', { noremap = true })
else
  vim.keymap.set({'n', 'x'}, '<C-c>', '"+y', { noremap = true })
end
vim.keymap.set({'n', 'x'}, '<C-v>', '"+p', { noremap = true })
vim.keymap.set({'n', 'x'}, '<C-b>', '<C-v>', { noremap = true })
vim.keymap.set({'x', 'n'}, '<M-p>', '"ap', { noremap = true })
vim.keymap.set({'x', 'n'}, '<M-P>', '"aP', { noremap = true })
vim.keymap.set({'x'}, 'p', 'p<cmd>let @a=@"<cr><cmd>let @"=@0<cr>', { noremap = true })
vim.keymap.set('x', 'y', "ygv<esc>", { noremap = true })
vim.keymap.set('n', 'Q', "<nop>", { noremap = true })
vim.keymap.set('n', '<leader><leader>rec', 'q')
vim.keymap.set('n', 'q', "<nop>", { noremap = true })
vim.keymap.set('n', 'zl', "15zl", { noremap = true })
vim.keymap.set('n', 'zh', "15zh", { noremap = true })
vim.keymap.set('n', 'n', "nzz", { noremap = true })
vim.keymap.set('n', 'N', "Nzz", { noremap = true })
vim.keymap.set('n', '<c-q>', "<cmd>close<cr>")

vim.keymap.set({'n', 'x', 'o'}, 'f', '<Plug>(leap-forward-to)')
vim.keymap.set({'n', 'x', 'o'}, 'F', '<Plug>(leap-backward-to)')

vim.keymap.set('n', '<leader>ts', function() require('treesj').toggle({ split = { recursive = true } }) end, { noremap = true, desc = "toggle split"})

vim.keymap.set({'n', 'x'}, '<C-r>', '<nop>', { noremap = true })
vim.keymap.set({'n', 'x'}, 'R', '<C-r>', { noremap = true })

local utils = require('myutils')

if not vim.g.vscode then
  vim.keymap.set({'n', 'x'}, '<C-u>', '<C-u>M')
  vim.keymap.set({'n', 'x'}, '<C-d>', '<C-d>M')
  vim.keymap.set({'n', 'x'}, 'n', 'nzz')
  vim.keymap.set({'n', 'x'}, 'N', 'Nzz')
  vim.keymap.set("n", "<c-p>", "<c-o>zz", { noremap = true })
  vim.keymap.set("n", "<c-n>", "<c-i>zz", { noremap = true })
  vim.api.nvim_create_user_command("DiffviewToggle", function(e)
    local view = require("diffview.lib").get_current_view()

    if view then
      vim.cmd("DiffviewClose")
    else
      vim.cmd("DiffviewOpen " .. e.args)
    end
  end, { nargs = "*" })

  -- fine-grained undo
  vim.keymap.set('i', '<space>', '<space><c-g>u', { noremap = true })
  vim.keymap.set('i', '<tab>', '<tab><c-g>u', { noremap = true })
  vim.keymap.set('i', '<cr>', '<cr><c-g>u', { noremap = true })
  -- end fine-grained undo

  -- window mappings
  vim.keymap.set({'i', 'x', 'n', 't'}, '<C-Up>', '<C-w><Up>', { noremap = true })
  vim.keymap.set({'i', 'x', 'n', 't'}, '<C-Down>', '<C-w><Down>', { noremap = true })
  vim.keymap.set({'i', 'x', 'n', 't'}, '<C-Right>', '<C-w><Right>', { noremap = true })
  vim.keymap.set({'i', 'x', 'n', 't'}, '<C-Left>', '<C-w><Left>', { noremap = true })

  local contrastantColors = {
    ["purple"] = "white",
    ["red"] = "white",
    ["green"] = "white",
    ["blue"] = "white",
    ["black"] = "white",
    ["magenta"] = "white",
    ["grey"] = "white",
    ["darkgrey"] = "white",
    ["darkblue"] = "white",
    ["darkred"] = "white",
    ["darkgreen"] = "white",
    ["orange"] = "black",
    ["yellow"] = "black",
    ["white"] = "black",
    ["cyan"] = "black",
    ["light_grey"] = "black",
  }

  vim.api.nvim_create_user_command('SetStatusLineBG', function(opts)
    -- The following line tells lua to re-require the module, otherwise it just returns the cached module value
    package.loaded["lualine.themes.auto"] = nil
    local autoTheme = require('lualine.themes.auto')
    autoTheme.normal.c.gui = "bold"
    if opts.fargs[1] == "auto" then
      require('lualine').setup({ options = { theme = autoTheme } })
    else
      autoTheme.normal.c.bg = opts.fargs[1]
      if contrastantColors[opts.fargs[1]] then
        autoTheme.normal.c.fg = contrastantColors[opts.fargs[1]]
      end
      require('lualine').setup({ options = { theme = autoTheme } })
    end
  end, { nargs = 1 })

  local Terminal  = require('toggleterm.terminal').Terminal
  local gitTermConfig =  {
    autochdir = true,
    direction = "float",
    float_opts = {
      border = "double",
    },
    count = 9,
  }

  GitTerm = Terminal:new(gitTermConfig);

  local execGitCommand = function(command)
    local gitCommandFull = "git"
    if (vim.api.nvim_win_get_width(0) < 150) then
      gitCommandFull = gitCommandFull .. " -c delta.side-by-side=false"
    else
      gitCommandFull = gitCommandFull .. " -c delta.side-by-side=true"
    end
    gitCommandFull = gitCommandFull .. " " .. command
    if (GitTerm:is_open()) then
      GitTerm:send(gitCommandFull)
    else
      GitTerm:open()
      GitTerm:change_dir(vim.loop.cwd())
      GitTerm:send(gitCommandFull)
    end
  end

  local gitPrettyFormat = "commit %C(#FFDE59)%h%Creset %aI %aN  %s"
  local gitPrettyFormatWithDescription = gitPrettyFormat .. "%n%n%b"
  vim.keymap.set({'n', 't'}, "<c-g>D", function() execGitCommand("diff --staged") end, {noremap = true, silent = true, desc = "git diff --staged"})
  vim.keymap.set({'n', 't'}, "<c-g>d", function() execGitCommand("diff") end, {noremap = true, silent = true, desc = "git diff"})
  vim.keymap.set({'n', 't'}, "<c-g>l", function() execGitCommand('log -p --pretty=format:"' .. gitPrettyFormatWithDescription .. '"') end, {noremap = true, silent = true, desc = "git log"})
  vim.keymap.set({'n', 't'}, "<c-g>g", function() execGitCommand('log --graph --pretty=format:"' .. gitPrettyFormat .. '"') end, {noremap = true, silent = true, desc = "git graph"})
  vim.keymap.set({'n', 't'}, '<c-g>c', function() execGitCommand("commit") end, { noremap = true, desc = "git commit" })
  vim.keymap.set({'n', 't'}, '<c-g>a', function() execGitCommand("commit --amend") end, { noremap = true, desc = "git commit --amend" })
  vim.keymap.set({'n', 't'}, '<c-g>P', function() execGitCommand("push") end, { noremap = true, desc = "git push" })
  vim.keymap.set({'n', 't'}, '<c-g>p', function() execGitCommand("pull") end, { noremap = true, desc = "git git pull" })
  vim.keymap.set({'n', 't'}, '<c-g>F', function() execGitCommand("push --force-with-lease") end, { noremap = true, desc = "git push force" })
  vim.keymap.set({'n', 't'}, '<c-g>f', function() execGitCommand("fetch") end, { noremap = true, desc = "git fetch" })
  vim.keymap.set({'n', 't'}, '<leader>gh', function() execGitCommand('log -p --follow --pretty=format:"' .. gitPrettyFormatWithDescription .. '" -- ' .. vim.api.nvim_buf_get_name(0)) end, { noremap = true, desc = "git file history" })
  vim.keymap.set({'n', 't'}, '<c-g>s', "<cmd>DiffviewToggle<cr>", { noremap = true, desc = "git status" })
  vim.keymap.set({'n', 't'}, '<c-g>t', function() GitTerm:toggle() end, { noremap = true, desc = "git terminal" })
  vim.keymap.set({'n', 't'}, '<leader>gb', function() gs.blame_line{full=true} end, { desc = "git blame" })

  vim.keymap.set('t', '<c-e>', [[<C-\><C-n>]], { noremap = true, desc = "exit terminal mode" })
  vim.keymap.set('t', '<c-w>p', [[<C-\><C-n><C-w><C-p>]], { desc = "got to previous window" })
  vim.keymap.set('t', '<c-t>', function()
    return [[<C-\><C-n><cmd>ToggleTermToggleAll<cr>]];
  end, { expr = true, desc = "toggle all terminals" })
  vim.keymap.set('t', '<c-q>', [[<C-\><C-n><cmd>close<cr>]], { desc = "close terminal" })
  vim.keymap.set('t', '<c-Up>', [[<C-\><C-n><C-w><Up>]], { desc = "move cursor to the window above" })
  vim.keymap.set('t', '<c-Down>', [[<C-\><C-n><C-w><Down>]], { desc = "move cursor to the window below" })
  vim.keymap.set('t', '<c-Left>', [[<C-\><C-n><C-w><Left>]], { desc = "move cursor to the window on the left" })
  vim.keymap.set('t', '<c-Right>', [[<C-\><C-n><C-w><Right>]], { desc = "move cursor to the window on the right" })

  vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    desc = 'Insert mode in terminal when entering it',
    pattern = 'term://*',
    callback = function()
      vim.defer_fn(function()
        vim.cmd('startinsert!')
      end, 100)
    end
  })

  function OpenToggleTerms(ids_to_ignore)
    local maxBufferIndex = vim.fn.bufnr("$")
    local toggleTermBuffers = vim.fn.filter(vim.fn.range(1, maxBufferIndex), function(idx, val)
      local termId = string.match(string.match(vim.fn.bufname(val), "toggleterm#%d+") or "", "%d+")
        return termId ~= nil and ids_to_ignore[termId] == nil;
    end)
    local corruptedBuffersExcluded = vim.fn.filter(toggleTermBuffers, function (_key, val) return vim.fn.getbufinfo(val)[1].variables.term_title ~= "exit"; end)
    return corruptedBuffersExcluded;
  end

  -- I need this function
  function ToggleAllTerms(ignore)
    local openTerms = OpenToggleTerms(ignore)
    print(vim.inspect(openTerms))
    for _key, value in pairs(openTerms) do
      local termId = string.match(string.match(vim.fn.bufname(value), "toggleterm#%d+"), "%d+")
      vim.cmd(termId .."ToggleTerm")
    end
  end

  vim.keymap.set('n', '<c-t>', function()
    if vim.v.count ~= 0 then
      vim.cmd(vim.v.count .. "ToggleTerm");
    else
      local openTermsCount = #OpenToggleTerms({ ["".. GitTerm.id] = true })
      if openTermsCount < 1 then
        vim.cmd("1ToggleTerm");
      else
        ToggleAllTerms({ ["" .. GitTerm.id] = true })
      end
    end
  end, { noremap = true })

  vim.keymap.set('n', '<F5>', function()
    local dirPath = vim.fn.expand("%:p:h"):gsub("%%20", " ")
    local count = vim.v.count > 0 and vim.v.count or 1
    vim.cmd(count .. "TermExec cmd=\"cd " .. dirPath .. "\"")
  end, { noremap = true })

  vim.keymap.set('n', '<F6>', function()
    local count = vim.v.count > 0 and vim.v.count or 1
    vim.cmd(count .. "TermExec cmd=\"pwd\"")
    vim.schedule(function()
      vim.cmd(count .. "TermExec cmd=\"cd " .. utils.getPathToGitDirOr(vim.loop.cwd()) .. "\"")
    end)
  end, { noremap = true })


  return {
    open_session_action = require('session_utils').open_session_action
  }
else
  -- all vscode ctrl+... keybindings are defined in the keybindings.json file of vscode
  local vscode = require("vscode-neovim")
  vim.keymap.set("n", "gr", function() vscode.call("editor.action.goToReferences") end)
  vim.keymap.set("n", "gi", function() vscode.call("editor.action.goToImplementation") end)
  vim.keymap.set("n", "zh", function()
    for _ = 1, 6 do
      vscode.call("scrollLeft")
    end
  end)
  vim.keymap.set("n", "zl", function()
    for _ = 1, 6 do
      vscode.call("scrollRight")
    end
  end)
  vim.keymap.set("n", "<c-t>", function()
    local dirPath = vim.fn.expand("%:p:h"):gsub("^vscode%-userdata:", ""):gsub("%%20", " ")
    vscode.call("workbench.action.terminal.sendSequence",
      { args = { text = "cd \"" .. dirPath .. "\"\n"} }
    )
  end)
  vim.keymap.set("n", "]c", function()
    vscode.call("workbench.action.editor.nextChange")
  end)
  vim.keymap.set("n", "[c", function()
    vscode.call("workbench.action.editor.previousChange")
  end)
  vim.keymap.set("n", "]x", function()
    vscode.call("merge-conflict.next")
  end)
  vim.keymap.set("n", "[x", function()
    vscode.call("merge-conflict.previous")
  end)

  local nvim_feedkeys = function(keys, delay)
    vim.defer_fn(function()
      local feedable_keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
      vim.api.nvim_feedkeys(feedable_keys, "n", false)
    end, delay)
  end

  -- Centers the viewport. This needs to be delayed for the cursor position to be
  -- correct after the nvim_feedkeys operations.
  local center_viewport = function(delay)
    vim.defer_fn(function()
      local current_line = vim.api.nvim_win_get_cursor(0)[1]
      vscode.call("revealLine", {args = {lineNumber = current_line, at = "center"}})
    end, delay)
  end

  vim.keymap.set("n", "n", function()
    nvim_feedkeys("n", 0)
    center_viewport(20)
  end)

  vim.keymap.set("n", "N", function()
    nvim_feedkeys("N", 0)
    center_viewport(20)
  end)
  vim.keymap.set("n", "<c-p>", function()
    vscode.call("workbench.action.navigateBack")
    center_viewport(100)
  end)
  vim.keymap.set("n", "<c-n>", function()
    vscode.call("workbench.action.navigateForward")
    center_viewport(100)
  end)

  -- TODO: Improve this keybiding so that it behaves like in [neo]vim, i.e. staying in the same visual position (not text position)
  -- this could be probably achievaple by passing the newCursorPosition (based on file line number) in the "to" param of the cursorMove command
  -- the newCursorPosition could be computed by knowing how many lines will be scrolled, and adding that value to the current cursor position
  vim.keymap.set("n", "<c-u>", function()
    vscode.call("vscode-neovim.ctrl-u")
    vim.defer_fn(function() vscode.call("cursorMove", { args = { to = "viewPortCenter" } }) end, 80)
  end)

  vim.keymap.set("n", "<c-d>", function()
    vscode.call("vscode-neovim.ctrl-d")
    vim.defer_fn(function() vscode.call("cursorMove", { args = { to = "viewPortCenter" } }) end, 80)
  end)
end
