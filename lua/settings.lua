vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
-- vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
if package.config:sub(1,1) == "\\" then -- is windows
  vim.opt.undodir = os.getenv("UserProfile") .. "/.vim/undodir"
else
  vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
end
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"

vim.api.nvim_create_autocmd("BufEnter", {
  desc = "Disable automatic comment insertion",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- vim.cmd("colorscheme catppuccin-mocha")
vim.cmd("colorscheme tokyonight-night")
