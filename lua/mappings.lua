if package.config:sub(1,1) == "\\" then
  vim.keymap.set({'n', 'x'}, '<C-c>', '"*y', { noremap = true })
else
  vim.keymap.set({'n', 'x'}, '<C-c>', '"+y', { noremap = true })
end

-- vim.keymap.set({'n', 'x'}, '<C-v>', '"+p', { noremap = true })

vim.keymap.set({'n', 'x'}, '<leader><leader>b', '<C-v>', { noremap = true })
vim.keymap.set({'x', 'n'}, '<M-p>', '"ap', { noremap = true })
vim.keymap.set({'x', 'n'}, '<M-P>', '"aP', { noremap = true })
vim.keymap.set({'x'}, 'p', 'p<cmd>let @a=@"<cr><cmd>let @"=@0<cr>', { noremap = true })
vim.keymap.set('x', 'y', "ygv<esc>", { noremap = true })
vim.keymap.set('n', 'Q', "<nop>", { noremap = true })
vim.keymap.set('n', '<leader><leader>rec', 'q')
vim.keymap.set('n', 'q', "<nop>", { noremap = true })
vim.keymap.set('n', '<leader><right>', "15zl", { noremap = true })
vim.keymap.set('n', '<leader><left>', "15zh", { noremap = true })
vim.keymap.set({'n', 'x'}, '<C-r>', '<nop>', { noremap = true })
vim.keymap.set({'n', 'x'}, 'R', '<C-r>', { noremap = true })

if not vim.g.vscode then

  vim.keymap.set({'n'}, 'qa',
    function()
      local current_bufnr = vim.api.nvim_get_current_buf()
      local current_line_number = vim.api.nvim_win_get_cursor(0)[1]
      local qflist = vim.fn.getqflist()
      for _, item in ipairs(qflist) do
        if item.bufnr == current_bufnr and item.lnum == current_line_number then
          print("Current line already in quickfix list")
          return
        end
      end
      local current_line = vim.api.nvim_get_current_line()
      local line_number = vim.api.nvim_win_get_cursor(0)[1]
      local filename = vim.api.nvim_buf_get_name(current_bufnr)
      vim.fn.setqflist({}, 'a',
        {
          items = {
            {
              filename = filename,
              lnum = line_number,
              text = current_line,
            },
          }
        }
      );
      print(filename .. " added to quickfix list")
    end,
    { noremap = true, desc = "quickfix add current file" });

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
      vim.keymap.set('n', 'dd', function()
        local qflist = vim.fn.getqflist()
        if #qflist == 0 then
          print("quickfix list is already empty")
          return
        end

        local current_line = vim.api.nvim_win_get_cursor(0)[1]
        if current_line > #qflist then
          print("no entry to delete at this position")
          return
        end

        table.remove(qflist, current_line)

        vim.fn.setqflist(qflist, 'r')

        if current_line > #qflist and #qflist > 0 then
          vim.api.nvim_win_set_cursor(0, {#qflist, 0})
        else
          vim.api.nvim_win_set_cursor(0, {current_line, 0})
        end

        print("deleted quickfix entry " .. current_line)
      end, { buffer = true, noremap = true, desc = "delete quickfix entry" })
    end
  })


  vim.keymap.set({"n"}, 'qc',
    function()
      vim.fn.setqflist({}, 'r');
      print("quickfix list cleared")
    end,
  { noremap = true, desc = "quickfix clear" });

  vim.keymap.set({"n"}, "qt",
    function()
      local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
      if qf_winid ~= 0 then
        vim.cmd("cclose")
      else
        vim.cmd("copen")
      end
    end,
  { noremap = true, desc = "quickfix toggle" });

  vim.keymap.set({'n'}, '<leader>tc', '<cmd>tabc<cr>', { noremap = true, desc = "tab close" })

  vim.keymap.set({'n'}, 'qn', '<cmd>cnext<cr>', { noremap = true, desc = "quickfix next" })
  vim.keymap.set({'n'}, 'qp', '<cmd>cprev<cr>', { noremap = true, desc = "quickfix previous" })
  -- local pastedInInsertMode = false
  --
  -- vim.api.nvim_create_autocmd("TextChangedI", {
  --   desc = "set nopaste after text has been completely copied",
  --   pattern = "*",
  --   callback = function()
  --     if pastedInInsertMode then
  --       pastedInInsertMode = false
  --       vim.schedule(function() vim.cmd('set nopaste!') end)
  --     end
  --   end
  -- })

  -- vim.keymap.set('c', '<C-v>', '<c-r>+', { noremap = true })
  -- vim.keymap.set('i', '<c-v>', function()
  --   vim.cmd('set paste!')
  --   pastedInInsertMode = true
  --   vim.schedule(function()
  --     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<c-r>+', true, true, true), 'i', true)
  --   end)
  -- end, { noremap = true })

  -- vim.keymap.set('i', '<c-p>', function()
  --   vim.cmd('set paste!')
  --   pastedInInsertMode = true
  --   vim.schedule(function()
  --     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<c-r>"', true, true, true), 'i', true)
  --   end)
  -- end, { noremap = true })

  vim.keymap.set({'n', 'x'}, '<PageUp>', '2<C-y>', { noremap = true })
  vim.keymap.set({'n', 'x'}, '<PageDown>', '2<C-e>', { noremap = true })
  vim.keymap.set("n", "<c-p>", "<c-o>", { noremap = true })
  vim.keymap.set("n", "<c-n>", "<c-i>", { noremap = true })
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
  vim.keymap.set('n', '<C-k>', '<C-w><Up>', { noremap = true })
  vim.keymap.set('n', '<C-j>', '<C-w><Down>', { noremap = true })
  vim.keymap.set('n', '<C-l>', '<C-w><Right>', { noremap = true })
  vim.keymap.set('n', '<C-h>', '<C-w><Left>', { noremap = true })

  vim.keymap.set('t', '<c-v>', [[<C-\><C-n>"+pi<Right>]], { noremap = true, desc = "exit terminal mode" })
  vim.keymap.set('t', '<c-e>', [[<C-\><C-n>]], { noremap = true, desc = "exit terminal mode" })
  vim.keymap.set('t', '<c-w>p', [[<C-\><C-n><C-w><C-p>]], { noremap = true, desc = "got to previous window" })
  vim.keymap.set('t', '<c-q>', [[<C-\><C-n><cmd>close<cr>]], { noremap = true, desc = "close terminal" })
  vim.keymap.set('t', '<c-Up>', [[<C-\><C-n><C-w><Up>]], { noremap = true, desc = "move cursor to the window above" })
  vim.keymap.set('t', '<c-Down>', [[<C-\><C-n><C-w><Down>]], { noremap = true, desc = "move cursor to the window below" })
  vim.keymap.set('t', '<c-Left>', [[<C-\><C-n><C-w><Left>]], { noremap = true, desc = "move cursor to the window on the left" })
  vim.keymap.set('t', '<c-Right>', [[<C-\><C-n><C-w><Right>]], { noremap = true, desc = "move cursor to the window on the right" })
  vim.keymap.set('t', '<c-k>', [[<C-\><C-n><C-w><Up>]], { noremap = true, desc = "move cursor to the window above" })
  vim.keymap.set('t', '<c-j>', [[<C-\><C-n><C-w><Down>]], { noremap = true, desc = "move cursor to the window below" })
  vim.keymap.set('t', '<c-h>', [[<C-\><C-n><C-w><Left>]], { noremap = true, desc = "move cursor to the window on the left" })
  vim.keymap.set('t', '<c-l>', [[<C-\><C-n><C-w><Right>]], { noremap = true, desc = "move cursor to the window on the right" })
else
  local utils = require('myutils')
  -- all vscode ctrl+... keybindings are defined in the keybindings.json file of vscode
  local vscode = require("vscode-neovim")
  vim.keymap.set("n", "gr", function() vscode.call("editor.action.goToReferences") end)
  vim.keymap.set("n", "gi", function() vscode.call("editor.action.goToImplementation") end)
  vim.keymap.set("n", "<leader><left>", function()
    for _ = 1, 6 do
      vscode.call("scrollLeft")
    end
  end)
  vim.keymap.set("n", "<leader><right>", function()
    for _ = 1, 6 do
      vscode.call("scrollRight")
    end
  end)

  vim.keymap.set("n", "<leader>th", function()
    vscode.call("workbench.action.terminal.toggleTerminal");
    vscode.call("workbench.action.terminal.sendSequence",
      { args = { text = "cd \"" .. utils.getPathToGitDirOr(vim.loop.cwd()) .. "\"\n"} }
    )
  end, { desc = "terminal here (git root)" })

  vim.keymap.set("n", "<leader>tH", function()
    local dirPath = vim.fn.expand("%:p:h"):gsub("^vscode%-userdata:", ""):gsub("%%20", " ")
    vscode.call("workbench.action.terminal.toggleTerminal");
    vscode.call("workbench.action.terminal.sendSequence",
      { args = { text = "cd \"" .. dirPath .. "\"\n"} }
    )
  end, { desc = "terminal here (file)" })

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

  vim.keymap.set("n", "<c-p>", function()
    vscode.call("workbench.action.navigateBack")
  end)
  vim.keymap.set("n", "<c-n>", function()
    vscode.call("workbench.action.navigateForward")
  end)

  local verticalMovementsCountWithinTimeFrame = 0
  local timeBeforeCenteringCursorInMs = 300

  local centerCursor = function(verticalMovementNumberWithinTimeFrame)
    return function()
      if verticalMovementNumberWithinTimeFrame == verticalMovementsCountWithinTimeFrame then
        verticalMovementsCountWithinTimeFrame = 0
        vscode.call("cursorMove", { args = { to = "viewPortCenter" } })
      end
    end
  end

  vim.keymap.set("n", "<c-u>", function()
    vscode.call("vscode-neovim.ctrl-u")
    verticalMovementsCountWithinTimeFrame = verticalMovementsCountWithinTimeFrame + 1
    vim.defer_fn(centerCursor(verticalMovementsCountWithinTimeFrame), timeBeforeCenteringCursorInMs)
  end)

  vim.keymap.set("n", "<c-d>", function()
    vscode.call("vscode-neovim.ctrl-d")
    verticalMovementsCountWithinTimeFrame = verticalMovementsCountWithinTimeFrame + 1
    vim.defer_fn(centerCursor(verticalMovementsCountWithinTimeFrame), timeBeforeCenteringCursorInMs)
  end)

  vim.keymap.set("n", "<leader>cc", function()
    vscode.call("workbench.panel.chat.view.copilot.focus")
  end)

  -- for loop that iterates from 1 to 9 to set keymaps for F keys, like F1, F2, ...
  for i = 1, 9 do
    vim.keymap.set("n", "<F" .. i .. ">", function()
      vscode.call("vscode-harpoon.gotoEditor" .. i)
    end)
  end

  vim.keymap.set("n", "<leader>ha", function()
    vscode.call("vscode-harpoon.addEditor")
  end)

  vim.keymap.set("n","<leader>ca", function()
    vscode.call("editor.action.quickFix")
  end)

  vim.keymap.set("n", "H", function()
    vscode.call("editor.action.showHover")
  end)
end
