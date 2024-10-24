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

local utils = require('myutils')

require("lazy").setup({
  {
    "ggandor/leap.nvim",
    dependencies = {
      "ggandor/leap.nvim",
      "tpope/vim-repeat"
    },
    keys = {
      { ']]', '<Plug>(leap-forward)', mode = { 'n', 'x' } },
      { '[[', '<Plug>(leap-backward)', mode = { 'n', 'x' } },
    },
    config = function()
      local leap = require("leap")
      -- remove lower case `s`
      table.remove(leap.opts.safe_labels, 1)
      table.remove(leap.opts.labels, 1)
    end
  },
  {
    "ggandor/flit.nvim",
    dependencies = {
      "ggandor/leap.nvim",
      "tpope/vim-repeat"
    },
    keys = {
      { 'f', mode = { 'n', 'x' } },
      { 'F', mode = { 'n', 'x' } },
      { 't', mode = { 'n', 'x' } },
      { 'T', mode = { 'n', 'x' } },
    },
    opts = { labeled_modes = "nv" }
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
    cond = not vim.g.vscode,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "bash", "lua", "vim", "vimdoc", "query", "dart", "typescript", "javascript", "json", "tsx", "c_sharp" }
      })
    end
  },
  {
    "nvim-lua/plenary.nvim",
    cond = not vim.g.vscode
  },
  {
    keys = {
      {
        '<c-s>f',
        function()
          require('telescope.builtin').find_files({
            cwd = utils.getPathToGitDirOr(vim.loop.cwd()),
            hidden = true,
            no_ignore = true,
            no_ignore_parent = true
          })
        end,
        noremap = true, desc = "search files"
      },
      {
        '<c-s>m',
        function() require('telescope.builtin').marks() end,
        noremap = true, desc = "search marks"
      },
      {
        '<c-g>B',
        function() require('telescope.builtin').git_branches() end,
        noremap = true, desc = "git branches"
      },
      {
        '<c-g>S',
        function() require('telescope.builtin').git_stash() end,
        noremap = true, desc = "git stash"
      },
      {
        '<F1>',
        function() require('telescope.builtin').help_tags() end,
        noremap = true
      },
      {
        '<c-s>s',
        function() require('telescope.builtin').treesitter() end,
        noremap = true, desc = "show symbols"
      }
    },
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
          dynamic_preview_title = true,
          layout_strategy = 'vertical',
          layout_config = {
            vertical = { width = 0.95 }
          },
          path_display = {"tail"}, -- "smart", "tail"
          mappings = {
            i = {
              ["<CR>"] = actions.select_default + actions.center,
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
            mappings = {
              i = {
                -- looks like file browser does not support the center action I use in default mappings
                ["<CR>"] = actions.select_default
              }
            }
          }
        },
        pickers = {
          git_branches = {
            mappings = {
              i = { ["<cr>"] = actions.git_switch_branch + actions.center,},
            }
          }
        }
      });
    end
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    keys = {
      {
        '<c-f>b',
        ':Telescope file_browser path=%:p:h select_buffer=true<CR>',
        noremap = true, desc = "File Browser"
      }
    },
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    cond = not vim.g.vscode,
    config = function ()
      require("telescope").load_extension("file_browser")
    end,
  },
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    keys = {
      {
        '<c-s>p',
        function()
          print("entro")
          print("entro")
          print("entro")
          require("telescope-live-grep-args.shortcuts").grep_visual_selection({
            cwd = require('myutils').getPathToGitDirOr(vim.loop.cwd()),
            postfix = " -g \"*.*\"",
          })
        end,
        mode = 'x', noremap = true, desc = "search pattern"
      },
      {
        '<c-s>p',
        function()
          require('telescope').extensions.live_grep_args.live_grep_args({
            cwd = require('myutils').getPathToGitDirOr(vim.loop.cwd()),
            postfix = " -g \"*.*\"",
          })
        end,
        mode = 'n', noremap = true, desc = "search pattern"
      }
    },
    cond = not vim.g.vscode,
    dependencies = {
      "nvim-telescope/telescope.nvim"
    },
    config = function()
      require("telescope").load_extension("live_grep_args")
    end,
  },
  {
    "smartpde/telescope-recent-files",
    keys = {
      {
        '<c-r>f',
        function() require('telescope').extensions.recent_files.pick() end,
        noremap = true, desc = "recent files"
      }
    },
    config = function()
      require("telescope").load_extension("recent_files")
    end,
    dependencies = { "nvim-telescope/telescope.nvim" },
    cond = not vim.g.vscode,
    lazy = true
  },
  {
    "https://github.com/ThePrimeagen/harpoon",
    branch = "harpoon2",
    keys = {
      {'<c-h>a', function() require('harpoon'):list():add() end, noremap = true, desc = "harpoon add" },
      {
        '<c-h>l',
        function()
          require('harpoon').ui:toggle_quick_menu(require('harpoon'):list(), { ui_width_ratio = 0.95 })
        end,
        noremap = true, desc = "harpoon list"
      },
      unpack((function()
        local key_mappings = {}
        for i = 1, 9 do
          table.insert(key_mappings, {
            '<C-' .. i .. '>',
            function() require('harpoon'):list():select(i) end,
            noremap = true,
          })
        end
        return key_mappings
      end)())
    },
    dependencies = {
      "nvim-telescope/telescope.nvim"
    },
    cond = not vim.g.vscode,
    config = function()
      -- harpoon depends on the current working directory remaining static through out the session
      -- therefore, in nvim-rooter, we are just setting directories related to source-control
      require("harpoon"):setup()
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
          { name = "copilot", group_index = 2 },
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
          ['<tab>'] = cmp.mapping.confirm({select = true}),
        })
      })
    end
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    name = "tokyonight",
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
        end
      })

      vim.cmd("colorscheme tokyonight")
    end
  },
  {
    'numToStr/Comment.nvim',
    keys = {
      {
        '<leader>ct',
        function()
          local mode = vim.fn.mode()
          if  mode == 'V' then
            return "<Plug>(comment_toggle_linewise_visual)"
          elseif mode == 'v' then
            return "<Plug>(comment_toggle_blockwise_visual)"
          end
        end,
        mode = 'x', noremap = true, expr = true, replace_keycodes = true, desc = "comment toggle"
      },
      {
        '<leader>ct',
        '<Plug>(comment_toggle_linewise_current)',
        noremap = true, desc = "comment toggle"
      }
    },
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
    config = function()
      require("toggleterm").setup({
        -- direction = "t"
        on_open = function(term)
          vim.cmd("startinsert!")
        end,
        autochdir = true
      })
    end,
    cond = not vim.g.vscode,
    lazy = true
  },
  {
    "notjedi/nvim-rooter.lua",
    config = function()
      require("nvim-rooter").setup({
        rooter_patterns = { '*_root.txt', '.git', '.hg', '.svn' }
      })
    end,
    cond = not vim.g.vscode
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter-context",
    cond = not vim.g.vscode,
    config = function()
      require("treesitter-context").setup({
        multiline_threshold = 2
      })
    end
  },
  {
    'Wansmer/treesj',
    keys = {
     {'<leader>ts', function() require('treesj').toggle({ split = { recursive = true } }) end, noremap = true, desc = "toggle split" }
    },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('treesj').setup({
        use_default_keymaps = false
      })
    end,
  },
  {
    'akinsho/flutter-tools.nvim',
    lazy = true,
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
    lazy = true,
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
    end,
    lazy = false
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
    end,
    lazy = true
  },
  {
    "nvim-tree/nvim-web-devicons",
    cond = not vim.g.vscode
  },
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      -- Actions
      {'<leader>hs', function() require('gitsigns').stage_hunk() end, desc = "hunk stage" },
      {'<leader>hr', function() require('gitsigns').reset_hunk() end, desc = "hunk reset" },
      {'<leader>su', function() require('gitsigns').undo_stage_hunk() end, desc = "stage undo" },
      {'<leader>hp', function() require('gitsigns').preview_hunk() end, desc = "hunk preview" },
      {'<leader>td', function() require('gitsigns').toggle_deleted() end, desc = "toggle deleted lines" },
      {
        '<leader>hs',
        function() require('gitsigns').stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
        desc = "hunk stage", mode = "x"
      },
      {
        '<leader>hr',
        function()
          require('gitsigns').reset_hunk {vim.fn.line('.'), vim.fn.line('v')}
        end,
        desc = "hunk reset" , mode = "x"
      },
      {
        ']c',
        function()
          if vim.wo.diff then return ']c' end

          vim.schedule(function() require('gitsigns').next_hunk() end)
          return '<Ignore>'
        end,
        expr = true, desc = "Hunk Next"
      },
      {
        '[c',
        function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() require('gitsigns').prev_hunk() end)
          return '<Ignore>'
        end,
        expr = true, desc = "Hunk Prev"
      }
    },
    cond = not vim.g.vscode,
    config = function ()
      require('gitsigns').setup()
    end
  },
  {
    "ruifm/gitlinker.nvim",
    keys = {
      {
        '<leader>gl',
        function()
          require("gitlinker").get_buf_range_url("n", {action_callback = require("gitlinker.actions").open_in_browser})
        end,
        silent = true
      },
      {
        '<leader>gl',
        function()
          require("gitlinker").get_buf_range_url("v", {action_callback = require("gitlinker.actions").open_in_browser})
        end,
        silent = true, mode = 'v'
      }
    },
    cond = not vim.g.vscode,
    config = function ()
      require("gitlinker").setup({
        callbacks = {
          ["dynamicscrm.visualstudio.com"] = function(url_data)
            local base_url = require"gitlinker.hosts".get_base_https_url(url_data)
            print(vim.inspect(url_data))
            local url = base_url .. "?path=/" .. url_data.file
            if url_data.lstart then
              url = url .. "&version=GC" .. url_data.rev
              url = url .. "&line=" .. url_data.lstart
              if url_data.lend then url = url .. "&lineEnd=" .. url_data.lend end
              url = url .. "&lineStartColumn=1"
              url = url .. "&lineEndColumn=1000"
              url = url .. "&_a=contents"
            end
            return url
          end
        }
      })
    end,
  },
  {
    "searleser97/sessions.nvim",
    keys = {
      { "<c-o>s", function() require('session_utils').open_session_action() end, noremap = true, desc = "open session" },
      { "<c-s>S", ":SessionsSave ", noremap = true, desc = "Save new Session" }
    },
    event = 'VeryLazy',
    cond = not vim.g.vscode,
    dependencies = {
      "nvim-telescope/telescope.nvim"
    },
    config = function()
      require("sessions").setup({
        use_unique_session_names = true,
        session_filepath = vim.fn.stdpath("data") .. "/sessions",
        absolute = true,
      })
      if (vim.fn.argc() == 0) then
        vim.schedule(require('session_utils').open_session_action)
      end
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
  { "rickhowe/diffchar.vim" },
  {
    "nvim-lualine/lualine.nvim",
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons', opt = true },
    cond = not vim.g.vscode,
    config = function ()
      local autoTheme = require('lualine.themes.auto')
      autoTheme.normal.c.gui = "bold"
      require('lualine').setup({
        options = {
          theme = autoTheme,
        },
        sections = {
          lualine_a = {"location"},
          lualine_b = {"progress"},
          lualine_c = {"filetype", "fileformat", "encoding"},
          lualine_x = {},
          lualine_y = {},
          lualine_z = {"vim.fn.expand('%')"},
        },
        inactive_sections = {
          lualine_x = {"vim.fn.expand('%')"},
          lualine_c = {"location", "progress"}
        },
        tabline = {
          lualine_z = {'tabs'},
          lualine_b = {'branch'},
          lualine_a = {'mode'}
        }
      })

      local contrastantColors = {
        ["purple"] = "white",
        ["red"] = "white",
        ["green"] = "white",
        ["blue"] = "white",
        ["black"] = "white",
        ["magenta"] = "white",
        ["grey"] = "white",
        ["darkgrey"] = "white",
        ["darkblue"] = "white",
        ["darkred"] = "white",
        ["darkgreen"] = "white",
        ["orange"] = "black",
        ["yellow"] = "black",
        ["white"] = "black",
        ["cyan"] = "black",
        ["light_grey"] = "black",
      }

      vim.api.nvim_create_user_command('SetStatusLineBG', function(opts)
        -- The following line tells lua to re-require the module, otherwise it just returns the cached module value
        package.loaded["lualine.themes.auto"] = nil
        local autoThemeLocal = require('lualine.themes.auto')
        autoThemeLocal.normal.c.gui = "bold"
        if opts.fargs[1] == "auto" then
          require('lualine').setup({ options = { theme = autoThemeLocal } })
        else
          autoThemeLocal.normal.c.bg = opts.fargs[1]
          if contrastantColors[opts.fargs[1]] then
            autoThemeLocal.normal.c.fg = contrastantColors[opts.fargs[1]]
          end
          require('lualine').setup({ options = { theme = autoThemeLocal } })
        end
      end, { nargs = 1 })
    end
  },
  {
    "Decodetalkers/csharpls-extended-lsp.nvim",
    dir = Is_Windows() and "E:\\forks\\csharpls-extended-lsp.nvim" or nil,
    cond = not vim.g.vscode,
    lazy = false
  },
  {
    "zbirenbaum/copilot-cmp",
    dependencies = "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    config = function ()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
      require("copilot_cmp").setup()
    end
  },
  {
    "pteroctopus/faster.nvim",
    lazy = false,
    cond = not vim.g.vscode,
    config = function()
      require('faster').setup()
    end
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    cmd = "CopilotChat",
    keys = {
      {
        '<c-g><c-c>',
        function ()
          local cc = require("CopilotChat")
          cc.toggle()
        end,
        mode = {'n', 'x'}, noremap = true
      }
    },
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = {
      debug = true, -- Enable debugging
      window = { layout = 'float' }
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
  {
      'willothy/wezterm.nvim',
      config = true
  }
})

