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

local Is_Windows = require('myutils').Is_Windows

local gitFilePatterns = { "COMMIT_EDITMSG", "git-rebase-todo" }
local isNeovimOpenedWithGitFile = function()
  if vim.fn.argc() == 0 then
    return false
  else
    local arg = vim.fn.argv(0)
    for _, pattern in ipairs(gitFilePatterns) do
      if type(arg) == "string" and string.match(arg, pattern) then
        return true
      end
    end
    return false
  end
end

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
      {'nvim-telescope/telescope.nvim'},

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},     -- Required
      {'hrsh7th/cmp-nvim-lsp'}, -- Required
      {'L3MON4D3/LuaSnip'},     -- Required
    },
    cond = not vim.g.vscode,
    event = { 'VeryLazy' },
    config = function()

      local lsp_zero = require("lsp-zero").preset({})

      lsp_zero.on_attach(function(client, buffer)
        lsp_zero.highlight_symbol(client, buffer)
        local telescope_builtin = require('telescope.builtin')
        vim.keymap.set('n', 'gd', telescope_builtin.lsp_definitions, { noremap = true, desc = "go to definition" })
        vim.keymap.set('n', 'gt', telescope_builtin.lsp_type_definitions, { noremap = true, desc = "go to type definition" })
        vim.keymap.set('n', 'gi', telescope_builtin.lsp_implementations, { noremap = true, desc = "go to implementation" })
        vim.keymap.set('n', 'gr', telescope_builtin.lsp_references, { noremap = true, desc = "go to references" })
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { noremap = true, desc = "go to references" })
        vim.keymap.set('n', '<leader>sd', function()
          vim.diagnostic.open_float()
          vim.diagnostic.open_float() -- the second call moves my cursor inside the diagnostic window
        end, { noremap = true, desc = "show diagnostics" })
        vim.keymap.set('n', 'H', function()
          local hoverContents = (function()
            local params = vim.lsp.util.make_position_params()
            local results, err = vim.lsp.buf_request_sync(0, 'textDocument/hover', params)
            if err then
              print("Error: ", err)
              return {}
            end
            if not results then
              return {}
            else
              local hoverContents = {}
              for _, result in pairs(results) do
                if result and result.result and result.result.contents then
                  for _, content in pairs(vim.lsp.util.convert_input_to_markdown_lines(result.result.contents)) do
                    table.insert(hoverContents, content)
                  end
                end
              end
              return hoverContents
            end
          end)()
          local cursor = vim.api.nvim_win_get_cursor(0)
          local line = cursor[1] - 1
          local diagnostics = vim.diagnostic.get(0, { lnum = line })
          local combined = {}
          local highlights = {}
          local highlightYOffset = 2
          if #diagnostics > 0 then
            table.insert(combined, "# Diagnostics")
            table.insert(combined, "")
          end
          local lineCnt = 0
          for i, diagnostic in pairs(diagnostics) do
            local startOfDiagnostic = i .. ". "
            local msgLines = vim.lsp.util.convert_input_to_markdown_lines(diagnostic.message)
            for j, msgLine in pairs(msgLines) do
              local formattedMsgLine = ""
              if j == 1 then
                formattedMsgLine = startOfDiagnostic
              end
              if j > 1 then
                for _ = 1, #startOfDiagnostic do
                  formattedMsgLine = formattedMsgLine .. " "
                end
              end
              formattedMsgLine = formattedMsgLine .. msgLine
              if j == #msgLines then
                formattedMsgLine = formattedMsgLine
                if diagnostic.code then
                  formattedMsgLine = formattedMsgLine .. " [" .. diagnostic.code .. "]"
                end
              end
              table.insert(combined, formattedMsgLine)
              table.insert(highlights, { line = lineCnt + highlightYOffset, severity = diagnostic.severity, endCol = #startOfDiagnostic + #msgLine + 1, startCol = #startOfDiagnostic })
              lineCnt = lineCnt + 1
            end
          end

          if #combined > 0 and  #hoverContents > 0 then
            table.insert(combined, "----------------")
            table.insert(combined, "# LSP Info")
          end

          for _, hoverContent in pairs(hoverContents) do
            table.insert(combined, hoverContent)
          end

          if vim.tbl_isempty(combined) then
            return
          end

          local highlight_map = {
            [vim.diagnostic.severity.ERROR] = 'DiagnosticFloatingError',
            [vim.diagnostic.severity.WARN] = 'DiagnosticFloatingWarn',
            [vim.diagnostic.severity.INFO] = 'DiagnosticFloatingInfo',
            [vim.diagnostic.severity.HINT] = 'DiagnosticFloatingHint',
          }

          local buf, win = vim.lsp.util.open_floating_preview(combined, "markdown", { border = 'rounded', focusable = true, focus = true })
          vim.api.nvim_set_current_win(win)
          for _, highlight in pairs(highlights) do
            vim.api.nvim_buf_add_highlight(buf, -1,  highlight_map[highlight.severity], highlight.line, highlight.startCol, highlight.endCol)
          end
        end, { noremap = true, desc = "Hover Info" })
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { noremap = true, desc = "code action" }) end)

        require("mason").setup({})
        require("mason-lspconfig").setup({
          handlers = {
            lsp_zero.default_setup,
            ["csharp_ls"] = function()
              local config = {
                handlers = {
                  ["textDocument/definition"] = require('csharpls_extended').handler,
                  ["textDocument/typeDefinition"] = require('csharpls_extended').handler
                },
                on_attach = function (client, bufnr)                                                
                  vim.keymap.set('n', 'gd', function()
                    -- TODO: get data from quickfix list and feed it to telescope here
                    require('csharpls_extended').lsp_definitions()
                  end, { noremap = true, desc = "go to definition", buffer = true })                               
                end
              }
              require("lspconfig").csharp_ls.setup(config)
            end,
            ["lua_ls"] = function()
              local lua_opts = lsp_zero.nvim_lua_ls()
              lua_opts.settings.Lua.workspace.library = {
                vim.env.VIMRUNTIME,
                (function()
                  if Is_Windows() then
                    return os.getenv('USERPROFILE') .. '\\AppData\\Local\\luvit-meta'
                  else
                    return os.getenv('HOME') .. '/.config/luvit-meta'
                  end
                end)()
              }
              require("lspconfig").lua_ls.setup(lua_opts)
            end
          }
        });
        require("telescope").load_extension("csharpls_definition")
    end
  },
  {
    "https://github.com/mbbill/undotree",
    event = { 'VeryLazy' },
    cond = not vim.g.vscode
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = { 'BufNewFile', 'BufReadPost' },
    build = ":TSUpdate",
    cond = not vim.g.vscode,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "bash", "lua", "vim", "vimdoc", "rust", "typescript", "javascript", "json", "tsx", "c_sharp" }
      })
    end
  },
  {
    "nvim-lua/plenary.nvim",
    cond = not vim.g.vscode
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        '<c-s>f',
        function()
          require('telescope.builtin').find_files({
            cwd = require('myutils').getPathToGitDirOr(vim.loop.cwd()),
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
        '<leader>help',
        function() require('telescope.builtin').help_tags() end,
        noremap = true
      },
      {
        '<c-s>s',
        function() require('telescope.builtin').treesitter() end,
        noremap = true, desc = "show symbols"
      }
    },
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
          layout_strategy = "flex",
          layout_config = {
            vertical = { width = 0.95, height = 0.95, preview_height = 0.6 },
            horizontal = { width = 0.95, height = 0.95, preview_width = 0.6 }
          },
          path_display = {"tail"}, -- "smart", "tail"
          mappings = {
            i = {
              ["<cr>"] = actions.select_default + actions.center,
              ["<c-Left>"] = actions.preview_scrolling_left,
              ["<c-Right>"] = actions.preview_scrolling_right,
              ["<c-Up>"] = actions.cycle_history_prev,
              ["<c-Down>"] = actions.cycle_history_next,
              ["<c-v>"] = function()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-r>+", true, true, true), 'i' , false)
              end,
              ["<c-p>"] = function()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<c-r>"', true, true, true), 'i' , false)
              end
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
                ["<cr>"] = actions.select_default
              }
            }
          }
        },
        pickers = {
          git_branches = {
            mappings = {
              i = { ["<cr>"] = actions.git_switch_branch + actions.center },
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
      {
        '<leader>ha',
        function() require('harpoon'):list():add() end,
        noremap = true,
        desc = "harpoon add",
      },
      {
        '<c-h>l',
        function()
          require('harpoon').ui:toggle_quick_menu(require('harpoon'):list(), {
            ui_width_ratio = 0.95,
          })
        end,
        noremap = true, desc = "harpoon list"
      },
      unpack((function()
        local key_mappings = {}
        for i = 1, 9 do
          table.insert(key_mappings, {
            '<F' .. i .. '>',
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
      "https://github.com/hrsh7th/cmp-buffer",
      "https://github.com/hrsh7th/cmp-nvim-lsp-signature-help"
    },
    cond = not vim.g.vscode,
    event = { 'VeryLazy' },
    config = function()
      local cmp = require("cmp")
      local types = require("cmp.types")
      cmp.setup({
        sources = {
          { name = "copilot", group_index = 1 },
          { name = 'nvim_lsp_signature_help', group_index = 1 },
          { name = 'async_path', group_index = 1 },
          { name = 'nvim_lsp', group_index = 1  },
          { name = 'buffer', group_index = 1 },
          { name = 'nvim_lua', group_index = 1  },
        },
        preselect = 'item',
        completion = {
          completeopt = 'menu,menuone,noinsert'
        },
        mapping = {
          ['<tab>'] = { i = cmp.mapping.confirm({select = true}) },
          ['<Down>'] = {
            i = cmp.mapping.select_next_item({ behavior = types.cmp.SelectBehavior.Select }),
          },
          ['<Up>'] = {
            i = cmp.mapping.select_prev_item({ behavior = types.cmp.SelectBehavior.Select }),
          },
        }
      })
    end
  },
  {
    "folke/tokyonight.nvim",
    event = { 'VeryLazy' },
    name = "tokyonight",
    priority = 1000,
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
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
    keys = require('toggleterm_utils').keys,
    config = function()
      require("toggleterm").setup({
        autochdir = true,
        start_in_insert = true,
        persist_mode = false,
        responsiveness = {
          horizontal_breakpoint = 135
        }
      })

      vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        desc = 'Insert mode in terminal when entering it',
        pattern = 'term://*',
        callback = function()
          vim.defer_fn(function()
            vim.cmd('startinsert!')
          end, 100)
        end
      })

      vim.api.nvim_create_autocmd({ 'BufLeave' }, {
        desc = 'Normal mode when leaving a terminal buffer',
        pattern = 'term://*',
        callback = function()
          vim.defer_fn(function()
            local current_buf = vim.api.nvim_get_current_buf()
            if (not string.match(vim.fn.bufname(current_buf), "toggleterm#%d+")) then
              vim.cmd('stopinsert!')
            end
          end, 100)
        end
      })

    end,
    cond = not vim.g.vscode,
    event = { 'VeryLazy' }
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
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = {
      "nvim-treesitter/nvim-treesitter"
    },
    event = { 'VeryLazy' },
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
     {
       '<leader>ts',
       function() require('treesj').toggle({ split = { recursive = true } }) end,
       noremap = true, desc = "toggle split",
     }
    },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      use_default_keymaps = false,
      max_join_length = 1000
    }
  },
  {
    'akinsho/flutter-tools.nvim',
    event = { 'VeryLazy' },
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
    event = { 'VeryLazy' },
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
    event = { 'VeryLazy' },
    config = function ()
      require("ibl").setup()
    end,
  },
  {
    "sindrets/diffview.nvim",
    cond = not vim.g.vscode,
    keys = {
      {
        '<c-g>s',
        "<cmd>DiffviewToggle<cr>",
        noremap = true, desc = "git status", mode = { 'n', 't' }
      }
    },
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

      vim.api.nvim_create_user_command("DiffviewToggle", function(e)
        local view = require("diffview.lib").get_current_view()

        if view then
          vim.cmd("DiffviewClose")
        else
          vim.cmd("DiffviewOpen " .. e.args)
        end
      end, { nargs = "*" })
    end
  },
  {
    "nvim-tree/nvim-web-devicons",
    event = { 'VeryLazy' },
    cond = not vim.g.vscode
  },
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      -- Actions
      {'<leader>hs', function() require('gitsigns').stage_hunk() end, desc = "hunk stage" },
      {'<leader>hr', function() require('gitsigns').reset_hunk() end, desc = "hunk reset" },
      {'<leader>su', function() require('gitsigns').undo_stage_hunk() end, desc = "stage undo" },
      {
        '<leader>hp',
        function()
          require('gitsigns').preview_hunk()
          require('gitsigns').preview_hunk()
        end,
        desc = "hunk preview"
      },
      {'<leader>td', function() require('gitsigns').toggle_deleted() end, desc = "toggle deleted lines" },
      {
        '<leader>hs',
        function() require('gitsigns').stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
        desc = "hunk stage", mode = "x"
      },
      {
        '<leader>hr',
        function() require('gitsigns').reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end,
        desc = "hunk reset" , mode = "x"
      },
      {
        '<leader>gb',
        function()
          require('gitsigns').blame_line({ full=true })
          require('gitsigns').blame_line({ full=true })
        end,
        desc = "git blame", mode = 'n'
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
    event = { 'VeryLazy' },
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
      local handler = function(url_data)
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
      require("gitlinker").setup({
        callbacks = {
          ["dynamicscrm.visualstudio.com"] = handler,
          ["dev.azure.com"] = handler,
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
    lazy = vim.fn.argc() > 0,
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
    event = { 'VeryLazy' }
  },
  {
    "rickhowe/diffchar.vim",
    event = { 'VeryLazy' }
  },
  {
    "nvim-lualine/lualine.nvim",
    event = { 'VeryLazy' },
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'folke/tokyonight.nvim',
      opt = true,
    },
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
        ["auto"] = "auto"
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
      end, {
        nargs = 1,
        complete = function()
          return vim.tbl_keys(contrastantColors)
        end
      })
    end
  },
  {
    "Decodetalkers/csharpls-extended-lsp.nvim",
    dir = Is_Windows() and "E:\\forks\\csharpls-extended-lsp.nvim" or nil,
    cond = not vim.g.vscode,
    lazy = { 'VeryLazy' }
  },
  {
    "zbirenbaum/copilot-cmp",
    dependencies = "zbirenbaum/copilot.lua",
    event = { "VeryLazy" },
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
    lazy = vim.fn.argc() == 0,
    event = { 'VeryLazy' },
    cond = not vim.g.vscode,
    opts = {
      behaviours = {
        bigfile = {
          extra_patterns = {
            { filesize = 0, pattern = "COMMIT_EDITMSG" },
            { filesize = 0, pattern = "git-rebase-todo" }
          }
        }
      }
    }
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    cmd = "CopilotChat",
    keys = {
      { '<c-g><c-c>', function() require("CopilotChat").toggle() end, mode = { 'n', 'x' }, noremap = true },
      {
        "<leader>ch",
        function()
          local actions = require("CopilotChat.actions")
          require("CopilotChat.integrations.telescope").pick(actions.help_actions())
        end,
        desc = "Copilot Help",
      },
      {
        "<leader>cp",
        function()
          local actions = require("CopilotChat.actions")
          require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
        end,
        desc = "Copilot Prompts (predefined)",
      },
    },
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
      { "nvim-telescope/telescope.nvim" },
      { "hrsh7th/nvim-cmp" }
    },
    build = Is_Windows() and nil or "make tiktoken", -- Only on MacOS or Linux
    config = function()
      require("CopilotChat.integrations.cmp").setup()
      require("CopilotChat").setup({
        debug = false, -- Enable debugging
        context = "buffers",
        window = {
          layout = 'float',
          width = 0.8,
          height = 0.8,
        },
        mappings = {
          complete = {
            insert = '',
          },
        },
      })
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = 'copilot-*',
        callback = function()
          vim.opt_local.relativenumber = true
          vim.opt_local.number = true
        end
      })
    end
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = { "VeryLazy" },
    config = true
  },
  {
    'willothy/wezterm.nvim',
    cond = not vim.g.vscode,
    lazy = false,
    config = function()
      require("wezterm").set_user_var('vim_keybindings_status', 'enabled')
      vim.api.nvim_create_autocmd({ 'VimLeave' }, {
        desc = 'VimLeave',
        pattern = '*',
        callback = function()
          require("wezterm").set_user_var('vim_keybindings_status', 'disabled')
        end
      })
    end
  },
  {
    "kylechui/nvim-surround",
    event = { 'VeryLazy' },
    opts = {}
  },
  {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>ff",
      function() require("conform").format({ async = true }) end,
      desc = "Format File",
    },
  },
  -- This will provide type hinting with LuaLS
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    -- Define your formatters
    formatters_by_ft = {
      lua = { "stylua" },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      rust = { "rustfmt", lsp_format = "fallback" },
    },
    -- Set default options
    default_format_opts = {
      lsp_format = "fallback",
    },
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
})

