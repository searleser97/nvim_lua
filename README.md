# nvim_lua
Neovim configuration in lua

## Copilot Mesh

The `ai` start mode uses [copilot-mesh.nvim](https://github.com/searleser97/copilot-mesh.nvim)
through `require("copilot_mesh")`, with Telescope selection and Blink completion.
Lazy intentionally keeps the installation name `native-copilot.nvim`, so existing
checkouts and running hosts remain in place rather than loading a second copy.
Its local lockfile entry retains that name; `lazy-lock.json` remains ignored.
The plugin preserves existing sessions and its `native-copilot` data directory.
Legacy `native_copilot` modules and `NativeCopilot*` commands remain supported.

## Pending

- make toggleterm load lazily based on key mappings like <c-t>, <c-g>t, ... or commands like "ToggleTerm", "ToggleAllTerms", ...
- <c-t> binding should check if a terminal window is already visible,
if it is and the cursor is in another window, then move the cursor to the terminal
otherwise, if the cursor is inside the terminal close/hide the terminal

- PR to toggleterm to stack terminals on top of each other
- Create cherry-pick UI within neovim
