vim.g.mapleader = " "
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

if not vim.g.vscode then
  -- fine-grained undo
  vim.keymap.set('i', '<space>', '<space><c-g>u', { noremap = true })
  vim.keymap.set('i', '<tab>', '<tab><c-g>u', { noremap = true })
  vim.keymap.set('i', '<cr>', '<cr><c-g>u', { noremap = true })
  -- end fine-grained undo

  local telescope_builtin = require('telescope.builtin')

  vim.keymap.set('n', '<leader>sf', telescope_builtin.find_files, { noremap = true })
  vim.keymap.set('n', '<leader>sw', telescope_builtin.live_grep, { noremap = true })
  vim.keymap.set('n', '<leader>ff', ':Telescope frecency<cr>', { noremap = true })
  vim.keymap.set('n', '<leader>sb', telescope_builtin.buffers, { noremap = true })
  vim.keymap.set('n', '<F1>', telescope_builtin.help_tags, { noremap = true })
  vim.keymap.set('n', 'gc', telescope_builtin.git_commits, { noremap = true })
  -- git history
  vim.keymap.set('n', 'gh', telescope_builtin.git_bcommits, { noremap = true })
  vim.keymap.set('n', 'gb', telescope_builtin.git_branches, { noremap = true })
  vim.keymap.set('n', 'gs', telescope_builtin.git_status, { noremap = true })
  vim.keymap.set('n', '<leader>gs', telescope_builtin.git_stash, { noremap = true })
  vim.keymap.set('n', '<leader>ts', telescope_builtin.treesitter, { noremap = true })

  local harpoon_ui = require("harpoon.ui")
  vim.keymap.set('n', '<leader>ha', require("harpoon.mark").add_file, { noremap = true })
  vim.keymap.set('n', '<leader>hl', ":Telescope harpoon marks<cr>", { noremap = true })
  vim.keymap.set('n', '<leader>hn', harpoon_ui.nav_next, { noremap = true })
  vim.keymap.set('n', '<leader>hp', harpoon_ui.nav_prev, { noremap = true })
  vim.keymap.set('n', '<leader>1', function() harpoon_ui.nav_file(1) end, { noremap = true })
  vim.keymap.set('n', '<leader>2', function() harpoon_ui.nav_file(2) end, { noremap = true })
  vim.keymap.set('n', '<leader>3', function() harpoon_ui.nav_file(3) end, { noremap = true })
  vim.keymap.set('n', '<leader>4', function() harpoon_ui.nav_file(4) end, { noremap = true })


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
