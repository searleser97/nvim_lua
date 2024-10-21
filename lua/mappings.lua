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

local getPathToGitDirOr = function(defaultPath)
  local gitCommandResult = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if gitCommandResult.code == 0 then
    return gitCommandResult.stdout:gsub("\n", "")
  else
    return defaultPath
  end
end

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

  vim.api.nvim_create_user_command("DiffviewFileHistoryToggle", function(e)
    local view = require("diffview.lib").get_current_view()

    if view then
      vim.cmd("DiffviewClose")
    else
      vim.cmd("DiffviewFileHistory " .. e.args)
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

  local telescope_builtin = require('telescope.builtin')
  local telescope = require("telescope")
  local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")

  vim.keymap.set('n', '<c-s>f', function()
    telescope_builtin.find_files({
      cwd = getPathToGitDirOr(vim.loop.cwd()),
      hidden = true,
      no_ignore = true,
      no_ignore_parent = true
    })
  end , { noremap = true, desc = "search files" })
  vim.keymap.set('n', '<c-r>f', telescope.extensions.recent_files.pick, { noremap = true, desc = "recent files" })
  vim.keymap.set('n', '<c-f>b', ':Telescope file_browser path=%:p:h select_buffer=true<CR>', { noremap = true, desc = "File Browser" })
  vim.keymap.set('n', '<c-s>m', telescope_builtin.marks, { noremap = true, desc = "search marks" })
  vim.keymap.set('x', '<c-s>p', function ()
    live_grep_args_shortcuts.grep_visual_selection({ cwd = getPathToGitDirOr(vim.loop.cwd()), postfix = " -g \"*.*\""})
  end
  , { noremap = true, desc = "search pattern" })
  vim.keymap.set('n', '<c-s>p', function ()
    telescope.extensions.live_grep_args.live_grep_args({ cwd = getPathToGitDirOr(vim.loop.cwd()), postfix = " -g \"*.*\"" })
  end, { noremap = true, desc = "search pattern" })
  vim.keymap.set('n', '<F1>', telescope_builtin.help_tags, { noremap = true })
  vim.keymap.set('n', '<c-s>s', telescope_builtin.treesitter, { noremap = true, desc = "show symbols" })

  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local conf = require"telescope.config".values

  local sessions = require("sessions")
  local scan = require'plenary.scandir'
  local path = require'plenary.path'
  local files = scan.scan_dir(vim.fn.stdpath("data") .. "/sessions", { depth = 1, })
  local filenames = {}
  for index, filepath in ipairs(files) do
    local splitpath = vim.split(filepath, path.path.sep)
    table.insert(filenames, splitpath[#splitpath])
  end
  local open_session_action = function ()
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
          actions.close(prompt_bufnr)
          sessions.load(string.sub(action_state.get_selected_entry()[1], 1, -9))
        end)
        return true
      end
    }):find()
  end
  vim.keymap.set("n", "<c-o>s", open_session_action, { noremap = true, desc = "open session" })
  vim.keymap.set("n", "<c-s>S", ":SessionsSave ", { noremap = true, desc = "Save new Session" })

  vim.keymap.set('n', '<leader>gl', function() require("gitlinker").get_buf_range_url("n", {action_callback = require("gitlinker.actions").open_in_browser}) end, {silent = true})
  vim.keymap.set('v', '<leader>gl', function() require("gitlinker").get_buf_range_url("v", {action_callback = require("gitlinker.actions").open_in_browser}) end, {silent = true})

  local harpoon = require("harpoon")
  -- harpoon depends on the current working directory remaining static through out the session
  -- therefore, in nvim-rooter, we are just setting directories related to source-control
  harpoon:setup()
  vim.keymap.set('n', '<c-h>a', function() harpoon:list():add() end, { noremap = true, desc = "harpoon add" })
  vim.keymap.set('n', '<c-h>l', function() harpoon.ui:toggle_quick_menu(harpoon:list(), { ui_width_ratio = 0.95 }) end, { noremap = true, desc = "harpoon list" })
  vim.keymap.set('n', '<C-1>', function() harpoon:list():select(1) end, { noremap = true })
  vim.keymap.set('n', '<C-2>', function() harpoon:list():select(2) end, { noremap = true })
  vim.keymap.set('n', '<C-3>', function() harpoon:list():select(3) end, { noremap = true })
  vim.keymap.set('n', '<C-4>', function() harpoon:list():select(4) end, { noremap = true })
  vim.keymap.set('n', '<C-5>', function() harpoon:list():select(5) end, { noremap = true })

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

  local gs = package.loaded.gitsigns

  -- Navigation
  vim.keymap.set('n', ']c', function()
    if vim.wo.diff then return ']c' end

    vim.schedule(function() gs.next_hunk() end)
    return '<Ignore>'
  end, {expr=true, desc = "Next Change"})

  vim.keymap.set('n', '[c', function()
    if vim.wo.diff then return '[c' end
    vim.schedule(function() gs.prev_hunk() end)
    return '<Ignore>'
  end, {expr=true, desc = "Previous Change"})

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
  vim.keymap.set({'n', 't'}, '<c-g>B', telescope_builtin.git_branches, { noremap = true, desc = "git branches" })
  vim.keymap.set({'n', 't'}, '<c-g>s', "<cmd>DiffviewToggle<cr>", { noremap = true, desc = "git status" })
  vim.keymap.set({'n', 't'}, '<c-g>S', telescope_builtin.git_stash, { noremap = true, desc = "git stash" })
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
      vim.cmd(count .. "TermExec cmd=\"cd " .. getPathToGitDirOr(vim.loop.cwd()) .. "\"")
    end)
  end, { noremap = true })

  -- Actions
  vim.keymap.set('n', '<leader>hs', gs.stage_hunk, {desc = "hunk stage"})
  vim.keymap.set('n', '<leader>hr', gs.reset_hunk, {desc = "hunk reset"})
  vim.keymap.set('x', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "hunk stage" })
  vim.keymap.set('x', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "hunk reset" })
  vim.keymap.set('n', '<leader>su', gs.undo_stage_hunk, { desc = "stage undo" })
  vim.keymap.set('n', '<leader>hp', gs.preview_hunk, { desc = "hunk preview" })
  vim.keymap.set('n', '<leader>td', gs.toggle_deleted, { desc = "toggle deleted lines" })

  -- Text object
  vim.keymap.set({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')

  return {
    open_session_action = open_session_action
  }
else
  -- all vscode ctrl+... keybindings are defined in the keybindings.json file of vscode
  local vscode = require("vscode-neovim")
  vim.keymap.set("n", "gr", function() vscode.call("editor.action.goToReferences") end)
  vim.keymap.set("n", "gi", function() vscode.call("editor.action.goToImplementation") end)
  vim.keymap.set("n", "zh", function()
    vscode.call("scrollLeft")
    vscode.call("scrollLeft")
    vscode.call("scrollLeft")
    vscode.call("scrollLeft")
    vscode.call("scrollLeft")
    vscode.call("scrollLeft")
  end)
  vim.keymap.set("n", "zl", function()
    vscode.call("scrollRight")
    vscode.call("scrollRight")
    vscode.call("scrollRight")
    vscode.call("scrollRight")
    vscode.call("scrollRight")
    vscode.call("scrollRight")
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
