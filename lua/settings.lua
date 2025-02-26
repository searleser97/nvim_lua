vim.g.mapleader = " "
vim.opt.cursorline = true
vim.opt.nu = true
vim.opt.relativenumber = true
vim.wo.number = true
vim.opt.tabstop = 2
-- vim.opt.softtabstop = 0
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.autoindent = false
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
vim.o.hidden = true

vim.opt.termguicolors = true

-- vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50
vim.opt.timeoutlen = 300
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.api.nvim_create_autocmd("BufEnter", {
  desc = "Disable automatic comment insertion",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"

-- used to prevent filetype plugin from adding mappings
vim.g.no_plugin_maps = 1

if package.config:sub(1,1) == "\\" then -- is windows
  vim.opt.shell = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
  vim.opt.shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait"
  vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end
