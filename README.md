# nvim_lua
Neovim configuration in lua

## Pending

- <c-t> binding should check if a terminal window is already visible,
if it is and the cursor is in another window, then move the cursor to the terminal
otherwise, if the cursor is inside the terminal close/hide the terminal

- (in progress) move keybindings to plugins.lua file, so that plugins can be really loaded lazyly

- PR to toggleterm to stack terminals on top of each other

- use H to show lsp hover info 

- center after direct jump to implementation/definition/reference/...
