# nvim_lua
Neovim configuration in lua

## Copilot Mesh

The `ai` start mode uses the Neovim client from the private
[copilot-mesh-clients](https://github.com/sergiosanc_microsoft/copilot-mesh-clients)
repository's generated `nvim-package` branch, pinned to an immutable commit,
through `require("copilot_mesh")`, with Telescope selection and Blink completion.
Lazy intentionally keeps the installation name `native-copilot.nvim`, so existing
checkouts and running hosts remain in place rather than loading a second copy.
Its local lockfile entry retains that name; `lazy-lock.json` remains ignored.
On Windows, shared and embedded modes both load the pinned package installed in
`E:\WorkUtils\.copilot\mesh-host\node_modules\copilot-mesh.nvim`; mode selection
still controls host ownership, not the source repository. Other platforms use
the same package projection through Lazy. New source changes belong under
`nvim` on the clients repository's `main` branch. The old repository is retained
privately for history; existing hosts are not restarted by these configuration
changes.
The plugin preserves existing sessions and its `native-copilot` data directory.
Legacy `native_copilot` modules and `NativeCopilot*` commands remain supported.

## Pending

- make toggleterm load lazily based on key mappings like <c-t>, <c-g>t, ... or commands like "ToggleTerm", "ToggleAllTerms", ...
- <c-t> binding should check if a terminal window is already visible,
if it is and the cursor is in another window, then move the cursor to the terminal
otherwise, if the cursor is inside the terminal close/hide the terminal

- PR to toggleterm to stack terminals on top of each other
- Create cherry-pick UI within neovim
