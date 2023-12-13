vim.cmd("unmap [%")

if package.config:sub(1,1) == "\\" then
  vim.keymap.set({'n', 'x'}, '<C-c>', '"*y', { noremap = true })
else
  vim.keymap.set({'n', 'x'}, '<C-c>', '"+y', { noremap = true })
end
vim.keymap.set({'n', 'x'}, '<C-v>', '"+p', { noremap = true })
vim.keymap.set({'n', 'x'}, '<C-b>', '<C-v>', { noremap = true })
vim.keymap.set({'x', 'n'}, 'l', '"0p', { noremap = true })
vim.keymap.set('x', 'y', "ygv<esc>", { noremap = true })
vim.keymap.set('n', 'Q', "<nop>", { noremap = true })
vim.keymap.set('n', 'zl', "10zl", { noremap = true })
vim.keymap.set('n', 'zh', "10zh", { noremap = true })

if not vim.g.vscode then
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

  vim.keymap.set('n', '<leader>sf', telescope_builtin.find_files, { noremap = true, desc = "search files" })
  vim.keymap.set('n', '<leader>rf', telescope.extensions.recent_files.pick, { noremap = true, desc = "recent files" })
  vim.keymap.set('n', '<leader>fb', ':Telescope file_browser path=%:p:h select_buffer=true<CR>', { noremap = true, desc = "File Browser" })
  vim.keymap.set('n', '<leader>sm', telescope_builtin.marks, { noremap = true, desc = "search marks" })
  vim.keymap.set('x', '<leader>sp', function ()
    live_grep_args_shortcuts.grep_visual_selection({ postfix = " -g \"*.*\""})
  end
  , { noremap = true, desc = "search pattern" })
  vim.keymap.set('n', '<leader>sp', function ()
    telescope.extensions.live_grep_args.live_grep_args({ postfix = " -g \"*.*\"" })
  end, { noremap = true, desc = "search pattern" })
  vim.keymap.set('n', '<F1>', telescope_builtin.help_tags, { noremap = true })
  vim.keymap.set('n', '<leader>ss', telescope_builtin.treesitter, { noremap = true, desc = "show symbols" })

  vim.keymap.set('n', 'gi', telescope_builtin.lsp_implementations, { noremap = true, desc = "go to implementation" })
  vim.keymap.set('n', 'gr', telescope_builtin.lsp_references, { noremap = true, desc = "go to references" })
  vim.keymap.set('n', '<leader>sd', vim.diagnostic.open_float, { noremap = true, desc = "show diagnostics" })

  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local conf = require"telescope.config".values

  local sessions = require("sessions")
  local lua_utils = require("lua_utils")

  vim.keymap.set("n", "<leader>os", function ()
    pickers.new({}, {
      previewer = false,
      prompt_title = "Open Session",
      finder = finders.new_table({
        results = lua_utils.file_names_sorted_by_modified_date(vim.fn.stdpath("data") .. "/sessions"),
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
  end, { noremap = true, desc = "search session" })
  vim.keymap.set("n", "<leader>SS", ":SessionsSave ", { noremap = true, desc = "Save new Session" })

  vim.keymap.set({'n', 'x', 'o'}, 'f', '<Plug>(leap-forward-to)')
  vim.keymap.set({'n', 'x', 'o'}, 'F', '<Plug>(leap-backward-to)')

  local harpoon_ui = require("harpoon.ui")
  vim.keymap.set('n', '<leader>ha', require("harpoon.mark").add_file, { noremap = true })
  vim.keymap.set('n', '<leader>hl', ":Telescope harpoon marks<cr>", { noremap = true })
  vim.keymap.set('n', '<leader>1', function() harpoon_ui.nav_file(1) end, { noremap = true })
  vim.keymap.set('n', '<leader>2', function() harpoon_ui.nav_file(2) end, { noremap = true })
  vim.keymap.set('n', '<leader>3', function() harpoon_ui.nav_file(3) end, { noremap = true })
  vim.keymap.set('n', '<leader>4', function() harpoon_ui.nav_file(4) end, { noremap = true })

  vim.keymap.set('n', '<leader>ts', function() require('treesj').toggle({ split = { recursive = true } }) end, { noremap = true, desc = "toggle split"})
  vim.keymap.set('x', '<leader>c', function()
    local mode = vim.fn.mode()
    if  mode == 'V' then
      return "<Plug>(comment_toggle_linewise_visual)"
    elseif mode == 'v' then
      return "<Plug>(comment_toggle_blockwise_visual)"
    end
  end, { noremap = true, expr = true, replace_keycodes = true})
  vim.keymap.set('n', '<leader>c', '<Plug>(comment_toggle_linewise_current)', { noremap = true })

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
    -- function to run on opening the terminal
    on_open = function(term)
      vim.cmd("startinsert!")
    end,
  }

  local gitTerm = Terminal:new(gitTermConfig);

  local execGitCommand = function(command)
    gitTerm:open()
    gitTerm:change_dir(vim.loop.cwd())
    gitTerm:send(command)
  end

  vim.keymap.set("n", "GD", function() execGitCommand("git diff --staged") end, {noremap = true, silent = true, desc = "git diff --staged"})
  vim.keymap.set("n", "Gd", function() execGitCommand("git diff") end, {noremap = true, silent = true, desc = "git diff"})
  vim.keymap.set('n', 'Gl', telescope_builtin.git_commits, { noremap = true, desc = "git branch commits" })
  vim.keymap.set('n', 'GC', function() execGitCommand("git commit") end, { noremap = true, desc = "git commit" })
  vim.keymap.set('n', 'GA', function() execGitCommand("git commit --amend") end, { noremap = true, desc = "git commit amend" })
  vim.keymap.set('n', 'GP', function() execGitCommand("git push") end, { noremap = true, desc = "git push" })
  vim.keymap.set('n', 'Gp', function() execGitCommand("git pull") end, { noremap = true, desc = "git git pull" })
  vim.keymap.set('n', 'GF', function() execGitCommand("git push --force-with-lease") end, { noremap = true, desc = "git push force" })
  vim.keymap.set('n', 'Gf', function() execGitCommand("git fetch") end, { noremap = true, desc = "git fetch" })
  -- git history
  -- vim.keymap.set('n', 'Gh', "<cmd>DiffviewFileHistoryToggle %<cr>", { noremap = true, desc = "git file history" })
  vim.keymap.set('n', 'Gh', telescope_builtin.git_bcommits, { noremap = true, desc = "git file history" })
  vim.keymap.set('n', 'GB', telescope_builtin.git_branches, { noremap = true, desc = "git branches" })
  vim.keymap.set('n', 'Gb', function() gs.blame_line{full=true} end, { desc = "git blame" })
  vim.keymap.set('n', 'GS', "<cmd>DiffviewToggle<cr>", { noremap = true, desc = "git status" })
  vim.keymap.set('n', 'Gs', telescope_builtin.git_stash, { noremap = true, desc = "git stash" })
  vim.keymap.set('n', 'GT', function() gitTerm:open() end, { noremap = true, desc = "git terminal" })

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
      local openTermsCount = #OpenToggleTerms({ ["".. gitTerm.id] = true })
      if openTermsCount < 1 then
        vim.cmd("1ToggleTerm");
      else
        ToggleAllTerms({ ["" .. gitTerm.id] = true })
      end
    end
  end, { noremap = true })
  vim.keymap.set('n', '<c-q>', "<cmd>close<cr>")

  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], { noremap = true })
  vim.keymap.set('t', '<c-p>', [[<C-\><C-n><C-w><C-p>]])
  vim.keymap.set('t', '<c-t>', function()
    return [[<C-\><C-n><cmd>ToggleTermToggleAll<cr>]];
  end, { expr = true })
  vim.keymap.set('t', '<c-q>', [[<C-\><C-n><cmd>close<cr>]])
  vim.keymap.set('t', '<c-Up>', [[<C-\><C-n><C-w><Up>]])
  vim.keymap.set('t', '<c-Down>', [[<C-\><C-n><C-w><Down>]])
  vim.keymap.set('t', '<c-Left>', [[<C-\><C-n><C-w><Left>]])
  vim.keymap.set('t', '<c-Right>', [[<C-\><C-n><C-w><Right>]])

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
else
  vim.keymap.set('n', 'u', '<cmd>call VSCodeNotify("undo")<cr>', { noremap = true })
  vim.keymap.set('n', '<c-r>', '<cmd>call VSCodeNotify("redo")<cr>', { noremap = true })
  vim.keymap.set('n', '<leader>ha', '<cmd>call VSCodeNotify("vscode-harpoon.addEditor")<cr>', { noremap = true })
  vim.keymap.set('n', '<leader>hl', '<cmd>call VSCodeNotify("vscode-harpoon.editorQuickPick")<cr>', { noremap = true })
  vim.keymap.set('n', '<leader>he', '<cmd>call VSCodeNotify("vscode-harpoon.editEditors")<cr>', { noremap = true })
  vim.keymap.set('n', '<leader>1', '<cmd>call VSCodeNotify("vscode-harpoon.gotoEditor1")<cr>', { noremap = true })
  vim.keymap.set('n', '<leader>2', '<cmd>call VSCodeNotify("vscode-harpoon.gotoEditor2")<cr>', { noremap = true })
  vim.keymap.set('n', '<leader>3', '<cmd>call VSCodeNotify("vscode-harpoon.gotoEditor3")<cr>', { noremap = true })
  vim.keymap.set('n', '<leader>4', '<cmd>call VSCodeNotify("vscode-harpoon.gotoEditor4")<cr>', { noremap = true })
end
