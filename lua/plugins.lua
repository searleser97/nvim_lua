local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "https://github.com/ggandor/flit.nvim",
    dependencies = {
      "https://github.com/ggandor/leap.nvim",
      "https://github.com/tpope/vim-repeat"
    },
    config = function()
      local leap = require("leap")
      -- remove lower case `s`
      table.remove(leap.opts.safe_labels, 1)
      table.remove(leap.opts.labels, 1)
      require("flit").setup({
        labeled_modes = "nv"
      })
    end
  },
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v2.x',
    dependencies = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},             -- Required
      {'williamboman/mason.nvim'},           -- Optional
      {'williamboman/mason-lspconfig.nvim'}, -- Optional

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},     -- Required
      {'hrsh7th/cmp-nvim-lsp'}, -- Required
      {'L3MON4D3/LuaSnip'},     -- Required
    },
    cond = not vim.g.vscode
  },
  {
    "https://github.com/mbbill/undotree",
  },
  {
    "https://github.com/tpope/vim-fugitive",
    cond = not vim.g.vscode
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    cond = not vim.g.vscode,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "bash", "lua", "vim", "vimdoc", "query", "lua", "dart", "typescript", "javascript", "json" }
      })
    end
  },
  {
    "https://github.com/ThePrimeagen/harpoon",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim"
    },
    cond = not vim.g.vscode,
    config = function()
      require("telescope").load_extension('harpoon')
    end
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim"
    },
    cond = not vim.g.vscode,
    config = function()
      local telescope = require("telescope");
      local actions = require("telescope.actions");
      telescope.setup({
        defaults = {
          path_display = {"truncate"}
        },
        extensions = {
        },
        pickers = {
          git_branches = {
            mappings = {
              i = { ["<cr>"] = actions.git_switch_branch },
            }
          }
        }
      });
    end
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "https://github.com/FelipeLema/cmp-async-path",
      "https://github.com/hrsh7th/cmp-nvim-lua",
      "https://github.com/hrsh7th/cmp-buffer"
    },
    cond = not vim.g.vscode,
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        sources = {
          { name = 'async_path' },
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'nvim_lua' },
        },
        preselect = 'item',
        completion = {
          completeopt = 'menu,menuone,noinsert'
        },
        mapping = {
          ['<CR>'] = cmp.mapping.confirm({select = true}),
        }
      })
    end
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    cond = not vim.g.vscode
  },
  {
    'numToStr/Comment.nvim',
    lazy = false,
    config = function()
      require("Comment").setup({
        mappings = {
          basic = false,
          extra = false
        }
      })
    end
  },
  {
    "arnamak/stay-centered.nvim",
    lazy = false,
    config = function()
      require("stay-centered").setup()
    end
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup()
    end
  },
  {
    "notjedi/nvim-rooter.lua",
    config = function()
      require("nvim-rooter").setup({
        rooter_patterns = { 'pubspec.yaml', 'package.json', 'dirs.proj', '.git', '.hg', '.svn' }
      })
    end,
    cond = not vim.g.vscode
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter-context",
    cond = not vim.g.vscode
  },
  {
    "smartpde/telescope-recent-files",
    config = function()
      require("telescope").load_extension("recent_files")
    end,
    dependencies = { "nvim-telescope/telescope.nvim" },
    cond = not vim.g.vscode
  },
  {
    'Wansmer/treesj',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('treesj').setup({
        use_default_keymaps = false
      })
    end,
  },
  {
    'akinsho/flutter-tools.nvim',
    lazy = false,
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- 'stevearc/dressing.nvim', -- optional for vim.ui.select
    },
    config = function ()
      require("flutter-tools").setup()
    end,
    cond = not vim.g.vscode
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- "antoinemadec/FixCursorHold.nvim",
      "sidlatau/neotest-dart"
    },
    lazy = false,
    cond = not vim.g.vscode,
    config = function ()
      require("neotest").setup({
        adapters = {
          require("neotest-dart") {
            command = "flutter",
            use_lsp = true
          }
        }
      })
    end
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    cond = not vim.g.vscode,
    config = function ()
      require("ibl").setup()
    end
  },
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    config = function()
      require("telescope").load_extension("live_grep_args")
    end,
    dependencies = { "nvim-telescope/telescope.nvim" },
    cond = not vim.g.vscode
  },
  {
    "sindrets/diffview.nvim",
    cond = not vim.g.vscode,
    config = function ()
      require("diffview").setup({
        enhanced_diff_hl = true,
        use_icons = true,
      })
    end
  },
  {
    "nvim-tree/nvim-web-devicons",
    cond = not vim.g.vscode
  },
  {
    "lewis6991/gitsigns.nvim",
    cond = not vim.g.vscode,
    config = function ()
      require('gitsigns').setup()
    end
  },
  {
    "ruifm/gitlinker.nvim",
    cond = not vim.g.vscode,
    config = function ()
      require("gitlinker").setup()
    end
  },
  {
    "searleser97/sessions.nvim",
    config = function()
      require("sessions").setup({
        use_unique_session_names = true,
        session_filepath = vim.fn.stdpath("data") .. "/sessions",
        absolute = true,
      })
    end
  }
})

