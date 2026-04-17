local M = {}

local state = {
  term_buf = nil,
  term_job_id = nil,
  compose_buf = nil,
  tab = nil,
}

local COMPOSE_HEIGHT = 4

local function is_term_alive()
  if not state.term_job_id or not state.term_buf then return false end
  if not vim.api.nvim_buf_is_valid(state.term_buf) then return false end
  local ok = pcall(vim.fn.jobpid, state.term_job_id)
  return ok
end

local function focus_term_insert()
  if not M.is_open() then return false end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(state.tab)) do
    if vim.api.nvim_win_get_buf(win) == state.term_buf then
      vim.api.nvim_set_current_win(win)
      vim.cmd('startinsert')
      return true
    end
  end
  return false
end

local function focus_compose()
  if not M.is_open() then return end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(state.tab)) do
    if vim.api.nvim_win_get_buf(win) == state.compose_buf then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end

local function setup_compose_keymaps(buf)
  vim.keymap.set('n', '<CR>', function()
    M.send_input()
  end, { buffer = buf, noremap = true, desc = 'Send to Copilot' })

  vim.keymap.set('n', 'q', function()
    M.close_chat()
  end, { buffer = buf, noremap = true, desc = 'Close Copilot chat' })

  vim.keymap.set('i', '/', function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cursor = vim.api.nvim_win_get_cursor(0)
    if #lines == 1 and lines[1] == "" and cursor[1] == 1 and cursor[2] == 0 and is_term_alive() then
      vim.schedule(function()
        vim.cmd('stopinsert')
        if focus_term_insert() then
          vim.api.nvim_paste("/", true, -1)
        end
      end)
    else
      vim.api.nvim_feedkeys("/", "n", false)
    end
  end, { buffer = buf, noremap = true, desc = 'Slash command passthrough' })
end

local function get_compose_buf()
  if not state.compose_buf or not vim.api.nvim_buf_is_valid(state.compose_buf) then
    state.compose_buf = vim.api.nvim_create_buf(false, true)
    local buf = state.compose_buf
    pcall(vim.api.nvim_buf_set_name, buf, "[ai cli input]")
    vim.bo[buf].filetype = 'markdown'
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].swapfile = false
    vim.bo[buf].buflisted = false
    setup_compose_keymaps(buf)
  end
  return state.compose_buf
end

function M.send_input()
  if not is_term_alive() then
    vim.notify("Copilot terminal is not running", vim.log.levels.WARN)
    return
  end

  local buf = get_compose_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(lines, "\n"):gsub("%s+$", "")
  if text == "" then return end

  local function paste_and_submit()
    if not focus_term_insert() then return end
    vim.api.nvim_paste(text, true, -1)
    local enter = vim.api.nvim_replace_termcodes('<CR>', true, true, true)
    vim.api.nvim_feedkeys(enter, 'n', true)
    vim.defer_fn(function() focus_compose() end, 100)
  end

  paste_and_submit()

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
end

function M.is_open()
  return state.tab ~= nil and vim.api.nvim_tabpage_is_valid(state.tab)
end

function M.open_chat()
  if M.is_open() then
    vim.api.nvim_set_current_tabpage(state.tab)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(state.tab)) do
      if vim.api.nvim_win_get_buf(win) == state.compose_buf then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
    return
  end

  vim.cmd('tabnew')
  state.tab = vim.api.nvim_get_current_tabpage()

  if is_term_alive() then
    vim.api.nvim_win_set_buf(0, state.term_buf)
  else
    if state.term_buf and vim.api.nvim_buf_is_valid(state.term_buf) then
      vim.api.nvim_buf_delete(state.term_buf, { force = true })
    end
    state.term_job_id = vim.fn.termopen("copilot", {
      on_exit = function()
        state.term_job_id = nil
      end,
    })
    state.term_buf = vim.api.nvim_get_current_buf()
  end

  local compose_buf = get_compose_buf()
  vim.cmd('belowright split')
  local compose_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(compose_win, compose_buf)
  vim.api.nvim_win_set_height(compose_win, COMPOSE_HEIGHT)
  vim.wo[compose_win].winfixheight = true
end

function M.close_chat()
  if not M.is_open() then return end
  vim.api.nvim_set_current_tabpage(state.tab)
  vim.cmd('tabclose')
  state.tab = nil
end

function M.toggle_chat()
  if M.is_open() then
    M.close_chat()
  else
    M.open_chat()
  end
end

vim.api.nvim_create_autocmd('TabClosed', {
  callback = function()
    if state.tab and not vim.api.nvim_tabpage_is_valid(state.tab) then
      state.tab = nil
    end
  end,
})

return M
