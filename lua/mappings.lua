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
vim.keymap.set({'n', 'x'}, '<C-r>', '<nop>', { noremap = true })
vim.keymap.set({'n', 'x'}, 'R', '<C-r>', { noremap = true })

if not vim.g.vscode then

  local pastedInInsertMode = false

  vim.api.nvim_create_autocmd("TextChangedI", {
    desc = "set nopaste after text has been completely copied",
    pattern = "*",
    callback = function()
      if pastedInInsertMode then
        pastedInInsertMode = false
        vim.schedule(function() vim.cmd('set nopaste!') end)
      end
    end
  })

  vim.keymap.set('c', '<C-v>', '<c-r>+', { noremap = true })
  vim.keymap.set('i', '<c-v>', function()
    vim.cmd('set paste!')
    pastedInInsertMode = true
    vim.schedule(function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<c-r>+', true, true, true), 'i', true)
    end)
  end, { noremap = true })

  vim.keymap.set('i', '<c-p>', function()
    vim.cmd('set paste!')
    pastedInInsertMode = true
    vim.schedule(function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<c-r>"', true, true, true), 'i', true)
    end)
  end, { noremap = true })

  vim.keymap.set({'n', 'x'}, '<C-u>', '<C-u>M')
  vim.keymap.set({'n', 'x'}, '<C-d>', '<C-d>M')
  vim.keymap.set({'n', 'x'}, 'n', 'nzz')
  vim.keymap.set({'n', 'x'}, 'N', 'Nzz')
  vim.keymap.set("n", "<c-p>", "<c-o>zz", { noremap = true })
  vim.keymap.set("n", "<c-n>", "<c-i>zz", { noremap = true })
  -- fine-grained undo
  vim.keymap.set('i', '<space>', '<space><c-g>u', { noremap = true })
  vim.keymap.set('i', '<tab>', '<tab><c-g>u', { noremap = true })
  vim.keymap.set('i', '<cr>', '<cr><c-g>u', { noremap = true })
  -- end fine-grained undo
  -- window mappings
  vim.keymap.set('n', '<C-Up>', '<C-w><Up>', { noremap = true })
  vim.keymap.set('n', '<C-Down>', '<C-w><Down>', { noremap = true })
  vim.keymap.set('n', '<C-Right>', '<C-w><Right>', { noremap = true })
  vim.keymap.set('n', '<C-Left>', '<C-w><Left>', { noremap = true })

  vim.keymap.set('t', '<c-v>', [[<C-\><C-n>"+pi<Right>]], { noremap = true, desc = "exit terminal mode" })
  vim.keymap.set('t', '<c-e>', [[<C-\><C-n>]], { noremap = true, desc = "exit terminal mode" })
  vim.keymap.set('t', '<c-w>p', [[<C-\><C-n><C-w><C-p>]], { noremap = true, desc = "got to previous window" })
  vim.keymap.set('t', '<c-q>', [[<C-\><C-n><cmd>close<cr>]], { noremap = true, desc = "close terminal" })
  vim.keymap.set('t', '<c-Up>', [[<C-\><C-n><C-w><Up>]], { noremap = true, desc = "move cursor to the window above" })
  vim.keymap.set('t', '<c-Down>', [[<C-\><C-n><C-w><Down>]], { noremap = true, desc = "move cursor to the window below" })
  vim.keymap.set('t', '<c-Left>', [[<C-\><C-n><C-w><Left>]], { noremap = true, desc = "move cursor to the window on the left" })
  vim.keymap.set('t', '<c-Right>', [[<C-\><C-n><C-w><Right>]], { noremap = true, desc = "move cursor to the window on the right" })
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
