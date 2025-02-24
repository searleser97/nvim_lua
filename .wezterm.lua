-- to debug this config with print statements run wezterm with the following command
-- WEZTERM_LOG=INFO wezterm

local wezterm = require 'wezterm'
local globalConfig = wezterm.config_builder()
local act = wezterm.action

if package.config:sub(1,1) == '\\' then
  globalConfig.default_prog = { 'C:\\Program Files\\PowerShell\\7\\pwsh.exe' }
end

globalConfig.prefer_egl = true
globalConfig.front_end = "Software"
globalConfig.animation_fps = 1
globalConfig.cursor_blink_ease_in = 'Constant'
globalConfig.cursor_blink_ease_out = 'Constant'
globalConfig.disable_default_key_bindings = true
globalConfig.window_background_opacity = 0.8
globalConfig.hide_tab_bar_if_only_one_tab = true
globalConfig.initial_cols = 120
globalConfig.initial_rows = 30
globalConfig.font_size = 14

local ctrl_c_action = wezterm.action_callback(function(window, pane)
  local sel = window:get_selection_text_for_pane(pane)
  if (not sel or sel == '') then
    window:perform_action(wezterm.action.SendKey{ key='c', mods='CTRL' }, pane)
  else
    window:perform_action(wezterm.action{ CopyTo = 'ClipboardAndPrimarySelection' }, pane)
  end
end)

-- main process refers to the terminal emulator used, like zsh, bash, powershell, ...
local set_keybindings_for_main_process = function(config)
  table.insert(config.keys, { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' })
  table.insert(config.keys, { key = 'c', mods = 'CTRL', action = ctrl_c_action })

  -- bindings needed for MAC
  table.insert(config.keys, { key = 'v', mods = 'SUPER', action = act.PasteFrom 'Clipboard' })
  table.insert(config.keys, { key = 'c', mods = 'SUPER', action = ctrl_c_action })
end

local set_universal_keybindings = function(config)
  table.insert(config.keys, { key = 'n', mods = 'SUPER|SHIFT', action = act.SpawnWindow })
end

local set_keybindings_for_vim_like_process = function(config)
  for c = string.byte("a"), string.byte("z") do
    local key = string.char(c)
    table.insert(config.keys, { key = key, mods = 'SUPER', action = wezterm.action.SendKey { key = key, mods = 'CTRL' } })
  end
  for c = string.byte("0"), string.byte("9") do
    local key = string.char(c)
    table.insert(config.keys, { key = key, mods = 'SUPER', action = wezterm.action.SendKey { key = key, mods = 'CTRL' } })
  end
  local otherKeys = {  'LeftArrow',  'RightArrow',  'DownArrow',  'UpArrow' }
  for _, key in ipairs(otherKeys) do
    table.insert(config.keys, { key = key, mods = 'SUPER', action = wezterm.action.SendKey { key = key, mods = 'CTRL' } })
  end
end

local vim_keybindings_status_var_name = 'vim_keybindings_status';

wezterm.on('user-var-changed', function(window, pane, name, value)
  if name == vim_keybindings_status_var_name then
    if window then
      if value == 'enabled' then
        local config = window:get_config_overrides() or {}
        config.keys = wezterm.gui.default_keys()
        set_universal_keybindings(config)
        set_keybindings_for_vim_like_process(config)
        window:set_config_overrides(config)
      elseif value == 'disabled' then
        local config = window:get_config_overrides() or {}
        config.keys = wezterm.gui.default_keys()
        set_universal_keybindings(config)
        set_keybindings_for_main_process(config)
        window:set_config_overrides(config)
      end
    end
  end
end)

if wezterm.GLOBAL.hasLoadedConfig == nil then
  wezterm.GLOBAL.hasLoadedConfig = {}
end

wezterm.on('window-config-reloaded', function(window, pane)
  if wezterm.GLOBAL.hasLoadedConfig[tostring(window:window_id())] == nil then
    wezterm.GLOBAL.hasLoadedConfig[tostring(window:window_id())] = true
    wezterm.emit('user-var-changed', window, pane, vim_keybindings_status_var_name, 'disabled')
  end
end)


return globalConfig

