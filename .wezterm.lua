-- to debug this config with print statements run wezterm with the following command
-- WEZTERM_LOG=INFO wezterm

local wezterm = require 'wezterm'
local globalConfig = wezterm.config_builder()
local act = wezterm.action

if package.config:sub(1,1) == '\\' then
  globalConfig.default_prog = { 'C:\\Program Files\\PowerShell\\7\\pwsh.exe' }
end

-- globalConfig.prefer_egl = true
-- globalConfig.front_end = "Software"
globalConfig.animation_fps = 1
globalConfig.cursor_blink_ease_in = 'Constant'
globalConfig.cursor_blink_ease_out = 'Constant'
globalConfig.disable_default_key_bindings = true
globalConfig.window_background_opacity = 0.8
globalConfig.hide_tab_bar_if_only_one_tab = true
globalConfig.initial_cols = 70
globalConfig.initial_rows = 16
globalConfig.font_size = 16
globalConfig.keys = {}

local ctrl_c_action = wezterm.action_callback(function(window, pane)
  local sel = window:get_selection_text_for_pane(pane)
  if (not sel or sel == '') then
    window:perform_action(wezterm.action.SendKey{ key='c', mods='CTRL' }, pane)
  else
    window:perform_action(wezterm.action{ CopyTo = 'ClipboardAndPrimarySelection' }, pane)
  end
end)

local ignoreKeys = { "v", "c" }

for c = string.byte("a"), string.byte("z") do
  local key = string.char(c)
  if not ignoreKeys[key] then
    table.insert(globalConfig.keys, { key = key, mods = 'SUPER', action = wezterm.action.SendKey { key = key, mods = 'CTRL' } })
  end
end

for c = string.byte("0"), string.byte("9") do
  local key = string.char(c)
  table.insert(globalConfig.keys, { key = key, mods = 'SUPER', action = wezterm.action.SendKey { key = key, mods = 'CTRL' } })
end

local otherKeys = {  'LeftArrow',  'RightArrow',  'DownArrow',  'UpArrow' }
for _, key in ipairs(otherKeys) do
  table.insert(globalConfig.keys, { key = key, mods = 'SUPER', action = wezterm.action.SendKey { key = key, mods = 'CTRL' } })
end

table.insert(globalConfig.keys, { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' })
table.insert(globalConfig.keys, { key = 'v', mods = 'SUPER', action = act.PasteFrom 'Clipboard' })
table.insert(globalConfig.keys, { key = 'c', mods = 'CTRL', action = ctrl_c_action })
table.insert(globalConfig.keys, { key = 'c', mods = 'SUPER', action = ctrl_c_action })
table.insert(globalConfig.keys, { key = 'n', mods = 'SUPER|SHIFT', action = act.SpawnWindow })

return globalConfig
