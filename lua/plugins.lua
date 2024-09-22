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
function Is_Windows()
  return package.config:sub(1,1) == "\\";
end

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
    branch = 'v3.x',
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
    cond = not vim.g.vscode
  },
  {
    "https://github.com/tpope/vim-fugitive",
    cond = not vim.g.vscode
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "bash", "lua", "vim", "vimdoc", "query", "dart", "typescript", "javascript", "json", "tsx", "c_sharp" }
      })
    end
  },
  {
    "nvim-lua/plenary.nvim"
  },
  {
    "searleser97/telescope.nvim",
    dir = Is_Windows() and "E:\\forks\\telescope.nvim" or nil,
    dependencies = {
      "nvim-lua/plenary.nvim"
    },
    lazy = false,
    cond = not vim.g.vscode,
    config = function()
      local telescope = require("telescope");
      local actions = require("telescope.actions");
      telescope.setup({
        defaults = {
          dynamic_preview_title = true,
          layout_strategy = 'vertical',
          layout_config = {
            vertical = { width = 0.95 }
          },
          path_display = {"tail"}, -- "smart", "tail"
          mappings = {
            i = {
              ["<C-l>"] = actions.results_scrolling_left,
              ["<C-r>"] = actions.results_scrolling_right,
              ["<c-p>"] = actions.cycle_history_prev,
              ["<c-n>"] = actions.cycle_history_next,
            }
          }
        },
        extensions = {
          file_browser = {
            respect_gitignore = false,
            no_ignore = true,
            hidden = true,
          }
        },
        pickers = {
          find_files = {
            hidden = true,
            no_ignore = true,
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "--no-ignore-vcs",
              "-g",
              "!**/.git/*",
              "-g",
              "!**/node_modules/*",
              "-g", "!**/.repro/*", -- just to hide .repro rtp
            },
          },
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
    "https://github.com/ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "searleser97/telescope.nvim"
    },
    cond = not vim.g.vscode,
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
        mapping = cmp.mapping.preset.insert({
          ['<TAB>'] = cmp.mapping.confirm({select = true}),
        })
      })
    end
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode,
    config = function()
      require("tokyonight").setup({
        style = "storm", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
        transparent = true,
        on_colors = function (colors)
          colors.diff.add = "#28444d"
          colors.diff.change = colors.none
          colors.diff.text = "#87632f"
          colors.diff.text = "#966d30"

          -- colors.gitSigns.add = colors.hint
        end
      })

      vim.cmd("colorscheme tokyonight")
    end
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    cond = not vim.g.vscode,
    config = function()
    require("catppuccin").setup({
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      transparent_background = true
    })

    -- vim.cmd("colorscheme catppuccin")
    end
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
    "akinsho/toggleterm.nvim",
    dir = Is_Windows() and "E:\\forks\\toggleterm.nvim" or nil,
    version = "*",
    config = function()
      require("toggleterm").setup({
        -- direction = "t"
        on_open = function(term)
          vim.cmd("startinsert!")
        end,
        autochdir = true
      })
    end,
    cond = not vim.g.vscode
  },
  {
    "notjedi/nvim-rooter.lua",
    config = function()
      require("nvim-rooter").setup({
        rooter_patterns = { '*_root.txt', 'Cargo.toml', 'pubspec.yaml', 'package.json', 'dirs.proj', '.git', '.hg', '.svn' }
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
    -- dependencies = { "searleser97/telescope.nvim" },
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
      "nvim-neotest/nvim-nio",
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
    -- dependencies = { "searleser97/telescope.nvim" },
    cond = not vim.g.vscode
  },
  {
    "sindrets/diffview.nvim",
    cond = not vim.g.vscode,
    config = function ()
      require("diffview").setup({
        enhanced_diff_hl = true,
        use_icons = true,
        view = {
          merge_tool = { layout = "diff3_vertical" },
          default = { layout = "diff2_vertical" },
          file_history = { layout = "diff2_vertical" }
        },
        keymaps = {
          file_panel = {
            { "n", "<c-r>", "<cmd>DiffviewRefresh<cr>", { desc = "DiffviewRefresh" } },
          }
        }
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
    dir = Is_Windows() and "E:\\forks\\sessions.nvim" or nil,
    cond = not vim.g.vscode,
    config = function()
      require("sessions").setup({
        use_unique_session_names = true,
        session_filepath = vim.fn.stdpath("data") .. "/sessions",
        absolute = true,
      })
    end
  },
  {
    "folke/which-key.nvim",
    cond = not vim.g.vscode,
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    lazy = false
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = {
      -- "searleser97/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    cond = not vim.g.vscode,
    config = function ()
      require("telescope").load_extension("file_browser")
    end
  },
  { "rickhowe/diffchar.vim" },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons', opt = true },
    cond = not vim.g.vscode,
    config = function ()
      require('lualine').setup()
    end
  },
  { 
    "Decodetalkers/csharpls-extended-lsp.nvim",
    dir = Is_Windows() and "E:\\forks\\csharpls-extended-lsp.nvim" or nil,
    cond = not vim.g.vscode,
    lazy = false
  },
  {
    "github/copilot.vim",
    cond = not vim.g.vscode
  }
})

