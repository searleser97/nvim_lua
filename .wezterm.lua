local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

if package.config:sub(1,1) == '\\' then
  config.default_prog = { 'C:\\Program Files\\PowerShell\\7\\pwsh.exe' }
end

config.hide_tab_bar_if_only_one_tab = true

local ctrl_c_action = wezterm.action_callback(function(window, pane)
  local sel = window:get_selection_text_for_pane(pane)
  if (not sel or sel == '') then
    window:perform_action(wezterm.action.SendKey{ key='c', mods='CTRL' }, pane)
  else
    window:perform_action(wezterm.action{ CopyTo = 'ClipboardAndPrimarySelection' }, pane)
  end
end)

config.keys = {
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
  { key = 'c', mods = 'CTRL', action = ctrl_c_action },
  { key = 'c', mods = 'SUPER', action = ctrl_c_action }
}

return config

