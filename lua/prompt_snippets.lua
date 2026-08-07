local M = {}

local default_prompts = {
  {
    label = "Order steps with todo_deps",
    text = "Use `todo_deps` tool to respect the order of the following steps:",
  },
  {
    label = "Push before build",
    text = "Once your changes are ready, push them before building so that I can take a look at them online while you build which usually takes time.",
  },
  {
    label = "Continue while away",
    text = "Create a scheduled task to remind you to continue working and not stop while I am away until you complete the assigned task, if you already stop for some reason, please figure out the way to unblock you while I am away.",
  },
  {
    label = "Document investigation",
    text = "Write an MD file with the details of your investigation and push it to the branch to have it as reference.",
  },
}

function M.get_file_path()
  local configured_path = vim.g.my_ai_prompts_file or vim.env.MY_AI_PROMPTS_FILE
  if configured_path and configured_path ~= "" then
    return vim.fs.normalize(vim.fn.expand(configured_path))
  end

  return vim.fs.joinpath(vim.fn.expand("~"), ".my_ai_prompts.json")
end

local function encode_default_prompts()
  local lines = { "[" }
  for index, prompt in ipairs(default_prompts) do
    vim.list_extend(lines, {
      "  {",
      "    \"label\": " .. vim.json.encode(prompt.label) .. ",",
      "    \"text\": " .. vim.json.encode(prompt.text),
      "  }" .. (index < #default_prompts and "," or ""),
    })
  end
  table.insert(lines, "]")
  return table.concat(lines, "\n") .. "\n"
end

function M.ensure_file()
  local file_path = M.get_file_path()
  if vim.fn.filereadable(file_path) == 1 then return true end

  local parent_dir = vim.fs.dirname(file_path)
  if vim.fn.isdirectory(parent_dir) == 0 and vim.fn.mkdir(parent_dir, "p") == 0 then
    vim.notify("Could not create AI prompts directory: " .. parent_dir, vim.log.levels.ERROR)
    return false
  end

  local file, open_error = io.open(file_path, "w")
  if not file then
    vim.notify("Could not create AI prompts file: " .. open_error, vim.log.levels.ERROR)
    return false
  end

  local ok, write_error = file:write(encode_default_prompts())
  file:close()
  if not ok then
    vim.notify("Could not write AI prompts file: " .. write_error, vim.log.levels.ERROR)
    return false
  end

  return true
end

local function load_prompts()
  local file_path = M.get_file_path()
  local file, open_error = io.open(file_path, "r")
  if not file then
    vim.notify("Could not open AI prompts file: " .. open_error, vim.log.levels.ERROR)
    return nil
  end

  local contents = file:read("*a")
  file:close()

  local ok, prompts = pcall(vim.json.decode, contents)
  if not ok then
    vim.notify("Invalid JSON in AI prompts file: " .. prompts, vim.log.levels.ERROR)
    return nil
  end
  if not vim.islist(prompts) then
    vim.notify("AI prompts file must contain a JSON array: " .. file_path, vim.log.levels.ERROR)
    return nil
  end

  for index, prompt in ipairs(prompts) do
    if type(prompt) ~= "table"
      or type(prompt.label) ~= "string"
      or prompt.label == ""
      or type(prompt.text) ~= "string"
      or prompt.text == "" then
      vim.notify(
        string.format("AI prompt %d must have non-empty string fields 'label' and 'text'", index),
        vim.log.levels.ERROR
      )
      return nil
    end
  end

  return prompts
end

local function insert_prompt(buf, win, cursor, text)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
    vim.notify("AI Prompt buffer is no longer available", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_set_current_win(win)
  vim.api.nvim_buf_set_text(buf, cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2], { text })
  vim.api.nvim_win_set_cursor(win, { cursor[1], cursor[2] + #text - 1 })
  vim.cmd("startinsert!")
end

function M.pick(buf)
  local prompts = load_prompts()
  if not prompts then return end
  if #prompts == 0 then
    vim.notify("No AI instructions configured in " .. M.get_file_path(), vim.log.levels.INFO)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")
  local conf = require("telescope.config").values

  local target_win = vim.api.nvim_get_current_win()
  local target_cursor = vim.api.nvim_win_get_cursor(target_win)
  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = 28 },
      { remaining = true },
    },
  })

  pickers.new({}, {
    prompt_title = "Insert AI instruction",
    previewer = false,
    finder = finders.new_table({
      results = prompts,
      entry_maker = function(prompt)
        return {
          value = prompt.text,
          ordinal = prompt.label,
          display = function()
            return displayer({ prompt.label, prompt.text })
          end,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not selection then return end

        vim.schedule(function()
          insert_prompt(buf, target_win, target_cursor, selection.value)
        end)
      end)
      return true
    end,
  }):find()
end

return M
