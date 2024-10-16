local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

config.keys = {}

if package.config:sub(1,1) == '\\' then
  config.default_prog = { 'C:\\Program Files\\PowerShell\\7\\pwsh.exe' }
end

config.window_background_opacity = 0.8
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 120
config.initial_rows = 30
config.font_size = 14

local ctrl_c_action = wezterm.action_callback(function(window, pane)
  local sel = window:get_selection_text_for_pane(pane)
  if (not sel or sel == '') then
    window:perform_action(wezterm.action.SendKey{ key='c', mods='CTRL' }, pane)
  else
    window:perform_action(wezterm.action{ CopyTo = 'ClipboardAndPrimarySelection' }, pane)
  end
end)

for c = string.byte("a"), string.byte("z") do
  local key = string.char(c)
  table.insert(config.keys, { key = key, mods = 'SUPER', action = wezterm.action.SendKey { key = key, mods = 'CTRL' } })
end

for c = string.byte("0"), string.byte("9") do
  local key = string.char(c)
  table.insert(config.keys, { key = key, mods = 'SUPER', action = wezterm.action.SendKey { key = key, mods = 'CTRL' } })
end


table.insert(config.keys, { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' })
table.insert(config.keys, { key = 'v', mods = 'SUPER', action = act.PasteFrom 'Clipboard' })
table.insert(config.keys, { key = 'c', mods = 'CTRL', action = ctrl_c_action })
table.insert(config.keys, { key = 'c', mods = 'SUPER', action = ctrl_c_action })
table.insert(config.keys, { key = 'LeftArrow', mods = 'SUPER', action = wezterm.action.SendKey{ key = 'LeftArrow', mods = 'CTRL'} })
table.insert(config.keys, { key = 'RightArrow', mods = 'SUPER', action = wezterm.action.SendKey{ key = 'RightArrow', mods = 'CTRL'} })
table.insert(config.keys, { key = 'DownArrow', mods = 'SUPER', action = wezterm.action.SendKey{ key = 'DownArrow', mods = 'CTRL'} })
table.insert(config.keys, { key = 'UpArrow', mods = 'SUPER', action = wezterm.action.SendKey{ key = 'UpArrow', mods = 'CTRL'} })

return config

