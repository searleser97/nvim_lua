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
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
  vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
end