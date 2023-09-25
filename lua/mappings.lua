vim.cmd("unmap [%")

if package.config:sub(1,1) == "\\" then
  vim.keymap.set({'n', 'x'}, '<C-c>', '"*y', { noremap = true })
else
  vim.keymap.set({'n', 'x'}, '<C-c>', '"+y', { noremap = true })
end
vim.keymap.set({'n', 'x'}, '<C-v>', '"+p', { noremap = true })
vim.keymap.set({'n', 'x'}, '<C-b>', '<C-v>', { noremap = true })
vim.keymap.set({'x', 'n'}, 'l', '"0p', { noremap = true })
vim.keymap.set('n', '<cr>', 'i<cr><esc>', { noremap = true })
vim.keymap.set('x', 'y', "ygv<esc>", { noremap = true })
vim.keymap.set('n', 'Q', "<nop>", { noremap = true })

if not vim.g.vscode then
  -- fine-grained undo
  vim.keymap.set('i', '<space>', '<space><c-g>u', { noremap = true })
  vim.keymap.set('i', '<tab>', '<tab><c-g>u', { noremap = true })
  vim.keymap.set('i', '<cr>', '<cr><c-g>u', { noremap = true })
  -- end fine-grained undo

  local telescope_builtin = require('telescope.builtin')
  local telescope = require("telescope")
  local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")

  vim.keymap.set('n', '<leader>f', telescope_builtin.find_files, { noremap = true, desc = "files" })
  vim.keymap.set('n', '<leader>rf', telescope.extensions.recent_files.pick, { noremap = true, desc = "recent files" })
  vim.keymap.set('x', '<leader>sp', function ()
    live_grep_args_shortcuts.grep_visual_selection({ postfix = " -g \"*.*\""})
  end
  , { noremap = true, desc = "search pattern" })
  vim.keymap.set('n', '<leader>sp', function ()
    telescope.extensions.live_grep_args.live_grep_args({ postfix = " -g \"*.*\"" })
  end, { noremap = true, desc = "search pattern" })
  vim.keymap.set('n', '<F1>', telescope_builtin.help_tags, { noremap = true })
  vim.keymap.set('n', 'gc', telescope_builtin.git_commits, { noremap = true, desc = "git commits" })
  -- git history
  vim.keymap.set('n', 'gh', telescope_builtin.git_bcommits, { noremap = true, desc = "git history" })
  vim.keymap.set('n', 'gb', telescope_builtin.git_branches, { noremap = true, desc = "git branches" })
  vim.keymap.set('n', 'gs', telescope_builtin.git_status, { noremap = true, desc = "git status" })
  vim.keymap.set('n', '<leader>gs', telescope_builtin.git_stash, { noremap = true, desc = "git stash" })
  vim.keymap.set('n', '<leader>ss', telescope_builtin.treesitter, { noremap = true, desc = "show symbols" })
  vim.keymap.set('n', 'gd', telescope_builtin.lsp_definitions, { noremap = true, desc = "go to definition" })
  vim.keymap.set('n', 'gr', telescope_builtin.lsp_references, { noremap = true, desc = "go to references" })

  local harpoon_ui = require("harpoon.ui")
  vim.keymap.set('n', '<leader>ha', require("harpoon.mark").add_file, { noremap = true })
  vim.keymap.set('n', '<leader>hl', ":Telescope harpoon marks<cr>", { noremap = true })
  vim.keymap.set('n', '<leader>hn', harpoon_ui.nav_next, { noremap = true })
  vim.keymap.set('n', '<leader>hp', harpoon_ui.nav_prev, { noremap = true })
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

  function _G.set_terminal_keymaps()
    local opts = {buffer = 0}
    vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
    vim.keymap.set('t', '<c-t>', [[<C-\><C-n><cmd>ToggleTerm<cr>]], opts)
  end

  function IsToggleTermOpen()
    local maxBufferIndex = vim.fn.bufnr("$")
    local toggleTermBuffers = vim.fn.filter(vim.fn.range(1, maxBufferIndex), 'bufname(v:val) =~ ".*toggleterm.*"')
    return #toggleTermBuffers > 0;
  end

  function ToggleIntegratedTerminal()
    if (IsToggleTermOpen()) then
      return "<cmd>TermSelect<cr>1<cr>i";
    else
      return "<cmd>ToggleTerm<cr>";
    end
  end
  vim.keymap.set('n', '<c-t>', ToggleIntegratedTerminal, { noremap = true, expr = true, replace_keycodes = true })
  -- if you only want these mappings for toggle term use term://*toggleterm#* instead
  vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

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
