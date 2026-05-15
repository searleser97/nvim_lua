-- Remove buffer-local [[ and ]] maps set by the runtime ftplugin (markdown.lua)
-- so that global Leap bindings take precedence.
pcall(vim.keymap.del, 'n', ']]', { buffer = 0 })
pcall(vim.keymap.del, 'n', '[[', { buffer = 0 })
