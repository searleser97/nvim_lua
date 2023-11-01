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
  vim.keymap.set('n', 'gc', telescope_builtin.git_commits, { noremap = true, desc = "git branch commits" })
  -- git history
  -- vim.keymap.set('n', 'gh', "<cmd>DiffviewFileHistoryToggle %<cr>", { noremap = true, desc = "git file history" })
  vim.keymap.set('n', 'gh', telescope_builtin.git_bcommits, { noremap = true, desc = "git file history" })
  vim.keymap.set('n', 'gb', telescope_builtin.git_branches, { noremap = true, desc = "git branches" })
  vim.keymap.set('n', 'gt', "<cmd>DiffviewToggle<cr>", { noremap = true, desc = "git tab/toggle" })
  vim.keymap.set('n', 'gS', telescope_builtin.git_stash, { noremap = true, desc = "git stash" })
  vim.keymap.set('n', '<leader>ss', telescope_builtin.treesitter, { noremap = true, desc = "show symbols" })
  vim.keymap.set('n', 'gd', telescope_builtin.lsp_definitions, { noremap = true, desc = "go to definition" })
  vim.keymap.set('n', 'gi', telescope_builtin.lsp_implementations, { noremap = true, desc = "go to implementation" })
  vim.keymap.set('n', 'gr', telescope_builtin.lsp_references, { noremap = true, desc = "go to references" })

  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"
  local previewers = require('telescope.previewers')

  local sessions = require("sessions")
  vim.keymap.set("n", "<leader>os", function ()
    telescope_builtin.find_files({
      previewer = false,
      prompt_title = "Open Session",
      cwd = vim.fn.stdpath("data") .. "/sessions",
      attach_mappings = function (_, map)
        map("i", "<cr>", function (prompt_bufnr)
          actions.close(prompt_bufnr)
          sessions.load(string.sub(action_state.get_selected_entry()[1], 1, -9))
        end)
        return true
      end
    })
  end, { noremap = true, desc = "search session" })
  vim.keymap.set("n", "<leader>SS", ":SessionsSave ", { noremap = true, desc = "Save new Session" })

  local delta_previewer = previewers.new_termopen_previewer {
    get_command = function(entry)
      return { 'git', '-c', 'core.pager=delta', '-c', 'delta.side-by-side=false', 'diff', entry.value .. '^!' }
    end
  }
  vim.keymap.set("n", "gc", function ()
    telescope_builtin.git_commits({
      previewer = delta_previewer
    })
  end, { noremap = true, desc = "git branch commits" })

  local gs = package.loaded.gitsigns

  local function map(mode, l, r, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, l, r, opts)
  end

  -- Navigation
  map('n', ']c', function()
    if vim.wo.diff then return ']c' end

    vim.schedule(function() gs.next_hunk() end)
    return '<Ignore>'
  end, {expr=true, desc = "Next Change"})

  map('n', '[c', function()
    if vim.wo.diff then return '[c' end
    vim.schedule(function() gs.prev_hunk() end)
    return '<Ignore>'
  end, {expr=true, desc = "Previous Change"})

  vim.keymap.set({'n', 'x', 'o'}, 't', '<Plug>(leap-forward-to)')
  vim.keymap.set({'n', 'x', 'o'}, 'T', '<Plug>(leap-backward-to)')

  -- Actions
  map('n', '<leader>hs', gs.stage_hunk, {desc = "hunk stage"})
  map('n', '<leader>hr', gs.reset_hunk, {desc = "hunk reset"})
  map('x', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "hunk stage" })
  map('x', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "hunk reset" })
  map('n', '<leader>su', gs.undo_stage_hunk, { desc = "stage undo" })
  map('n', '<leader>hp', gs.preview_hunk, { desc = "hunk preview" })
  map('n', '<leader>gb', function() gs.blame_line{full=true} end, { desc = "git blame" })
  map('n', '<leader>td', gs.toggle_deleted, { desc = "toggle deleted lines" })

  -- Text object
  map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')

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

  function OpenToggleTerms()
    local maxBufferIndex = vim.fn.bufnr("$")
    local toggleTermBuffers = vim.fn.filter(vim.fn.range(1, maxBufferIndex), 'bufname(v:val) =~ ".*toggleterm.*"')
    local corruptedBuffersExcluded = vim.fn.filter(toggleTermBuffers, function (_key, val) return vim.fn.getbufinfo(val)[1].variables.term_title ~= "exit"; end)
    return corruptedBuffersExcluded;
  end

  function ToggleIntegratedTerminal()
    local openTerms = OpenToggleTerms()
    if (#openTerms == 0) then
      return "<cmd>ToggleTerm<cr>";
    elseif #openTerms == 1 then
      return "<cmd>TermSelect<cr>1<cr>i";
    else
      return "<cmd>TermSelect<cr>";
    end
  end

  vim.keymap.set('n', '<c-t>', ToggleIntegratedTerminal, { noremap = true, expr = true, replace_keycodes = true })
  -- vim.keymap.set({'n', 't'}, '<c-x>', [[<C-\><C-n><cmd>ToggleTerm<cr>]], { noremap = true })
  local opts = {noremap = true}
  vim.keymap.set('t', '<c-n>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<c-t>', [[<C-\><C-n><C-w><C-p>]], opts)

  local Terminal  = require('toggleterm.terminal').Terminal
  local lazygit = Terminal:new({
    cmd = "lazygit",
    dir = "git_dir",
    direction = "float",
    float_opts = {
      border = "double",
    },
    -- function to run on opening the terminal
    on_open = function(term)
      vim.cmd("startinsert!")
      vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    end,
    -- function to run on closing the terminal
    on_close = function(term)
      vim.cmd("startinsert!")
    end,
  })

  function _lazygit_toggle()
    lazygit:toggle()
  end

  vim.api.nvim_set_keymap("n", "<leader>lg", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true, desc = "lazygit"})


  local gitDiffStaged = Terminal:new({
    cmd = "git diff --staged",
    dir = "git_dir",
    close_on_exit = false,
    direction = "float",
    float_opts = {
      border = "double",
    },
    -- function to run on opening the terminal
    on_open = function(term)
      vim.cmd("startinsert!")
      vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    end,
  })

  function _gitDiffStaged_toggle()
    gitDiffStaged:toggle()
  end

  vim.api.nvim_set_keymap("n", "<leader>gd", "<cmd>lua _gitDiffStaged_toggle()<CR>", {noremap = true, silent = true, desc = "git diff --staged"})

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
