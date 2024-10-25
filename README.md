# nvim_lua
Neovim configuration in lua

## Pending

- make toggleterm load lazily based on key mappings like <c-t>, <c-g>t, ... or commands like "ToggleTerm", "ToggleAllTerms", ...
- <c-t> binding should check if a terminal window is already visible,
if it is and the cursor is in another window, then move the cursor to the terminal
otherwise, if the cursor is inside the terminal close/hide the terminal

- PR to toggleterm to stack terminals on top of each other
- Create cherry-pick UI within neovim
