vim.g.mapleader = " "
vim.cmd("unmap [%")

vim.keymap.set({'n', 'x'}, '<C-c>', '"+y', { noremap = true })
vim.keymap.set({'n', 'x'}, '<C-v>', '"+p', { noremap = true })
vim.keymap.set({'n', 'x'}, '<C-b>', '<C-v>', { noremap = true })
vim.keymap.set({'x', 'n'}, 'p', '"0p', { noremap = true })
vim.keymap.set({'n', 'x', 'o'}, '[', '""p', { noremap = true })
vim.keymap.set('n', '<cr>', 'i<cr><esc>', { noremap = true })
-- fine-grained undo
vim.keymap.set('i', '<space>', '<space><c-g>u', { noremap = true })
vim.keymap.set('i', '<tab>', '<space><c-g>u', { noremap = true })
vim.keymap.set('i', '<cr>', '<space><c-g>u', { noremap = true })
-- end fine-grained undo

if not vim.g.vscode then
  local telescope_builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', telescope_builtin.find_files, {})
  vim.keymap.set('n', '<leader>fg', telescope_builtin.live_grep, {})
  vim.keymap.set('n', '<leader>fb', telescope_builtin.buffers, {})
  vim.keymap.set('n', '<leader>fh', telescope_builtin.help_tags, {})

  local harpoon_ui = require("harpoon.ui")
  vim.keymap.set('n', '<leader>ha', require("harpoon.mark").add_file, {})
  vim.keymap.set('n', '<leader>ht', harpoon_ui.toggle_quick_menu, {})
  vim.keymap.set('n', '<leader>hn', harpoon_ui.nav_next, {})
  vim.keymap.set('n', '<leader>hp', harpoon_ui.nav_prev, {})
  vim.keymap.set('n', '<leader>1', function() harpoon_ui.nav_file(1) end, {})
  vim.keymap.set('n', '<leader>2', function() harpoon_ui.nav_file(2) end, {})
  vim.keymap.set('n', '<leader>3', function() harpoon_ui.nav_file(3) end, {})
  vim.keymap.set('n', '<leader>4', function() harpoon_ui.nav_file(4) end, {})
end