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

      local code_hl_group = "CodeHighlightGroup"
      local highlight_map = {
        [vim.diagnostic.severity.ERROR] = 'DiagnosticFloatingError',
        [vim.diagnostic.severity.WARN] = 'DiagnosticFloatingWarn',
        [vim.diagnostic.severity.INFO] = 'DiagnosticFloatingInfo',
        [vim.diagnostic.severity.HINT] = 'DiagnosticFloatingHint',
      }

      lsp_zero.on_attach(function(client, buffer)
        -- lsp_zero.highlight_symbol(client, buffer)
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
            local params = vim.lsp.util.make_position_params(0, 'utf-8')
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
          if #diagnostics > 0 then
            table.insert(combined, "# Diagnostics")
            table.insert(combined, "")
          end
          for i, diagnostic in pairs(diagnostics) do
            local diagnosticCodeInRange = vim.api.nvim_buf_get_text(
              0,
              diagnostic.lnum,
              diagnostic.col,
              diagnostic.end_lnum,
              diagnostic.end_col,
              {}
            )
            local maxLineLength = 0
            for j, codeLine in pairs(diagnosticCodeInRange) do
              local lineLength = (j == 1 and diagnostic.col or 0) + #codeLine
              if lineLength > maxLineLength then
                maxLineLength = lineLength
              end
            end
            for j, codeLine in pairs(diagnosticCodeInRange) do
              if j == 1 then
                table.insert(combined, "```" .. (#codeLine > 0 and vim.bo.filetype or ""))
                if diagnostic.lnum < diagnostic.end_lnum then
                  local leftPadding = string.rep(" ", diagnostic.col - 1);
                  local rightPadding = string.rep(" ", maxLineLength - #leftPadding - #codeLine)
                  table.insert(highlights, { line = #combined, hl_group = code_hl_group, endCol = maxLineLength, startCol = 0 })
                  table.insert(combined, leftPadding .. codeLine .. rightPadding)
                else -- same line
                  if #codeLine == 0 then
                    local colDesc = "in column: " .. diagnostic.col
                    table.insert(highlights, { line = #combined, hl_group = code_hl_group, endCol = #colDesc, startCol = 0 })
                    table.insert(combined, colDesc)
                  else
                    table.insert(highlights, { line = #combined, hl_group = code_hl_group, endCol = #codeLine, startCol = 0 })
                    table.insert(combined, codeLine)
                  end
                end
              else
                table.insert(highlights, { line = #combined, hl_group = code_hl_group, endCol = maxLineLength, startCol = 0 })
                local rightPadding = string.rep(" ", maxLineLength - #codeLine)
                table.insert(combined, codeLine .. rightPadding)
              end
              if j == #diagnosticCodeInRange then
                  table.insert(combined, "```")
              end
            end

            local startOfDiagnosticMsg = i .. ". "
            local msgLines = vim.lsp.util
              .convert_input_to_markdown_lines(diagnostic.message)
            for j, msgLine in pairs(msgLines) do
              local formattedMsgLine = ""
              if j == 1 then
                formattedMsgLine = startOfDiagnosticMsg
              end
              if j > 1 then
                for _ = 1, #startOfDiagnosticMsg do
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
              table.insert(highlights, { line = #combined, hl_group = highlight_map[diagnostic.severity], endCol = #startOfDiagnosticMsg + #msgLine + 1, startCol = #startOfDiagnosticMsg })
              table.insert(combined, formattedMsgLine)
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

          local buf, win = vim.lsp.util.open_floating_preview(combined, "markdown", { border = 'rounded', focusable = true, focus = true })
          vim.api.nvim_set_current_win(win)
          for _, highlight in pairs(highlights) do
            vim.api.nvim_buf_add_highlight(buf, -1,  highlight.hl_group, highlight.line, highlight.startCol, highlight.endCol)
          end
        end, { noremap = true, desc = "Hover Info" })
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { noremap = true, desc = "code action" }) end)

      require("mason").setup({})
      require("mason-lspconfig").setup({
        handlers = {
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
          end,
          ["rust_analyzer"] = function()
            local rust_opts = {
            }
            require("lspconfig").rust_analyzer.setup(rust_opts)
          end,
          ["vtsls"] = function()
            require("lspconfig").vtsls.setup({
              filetypes = {
                "typescript",
                "typescriptreact",
                "typescript.tsx",
                "javascript",
                "javascriptreact",
                "javascript.jsx",
              },
            })
          end
        }
      });
      vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics,
        {
          underline = {
            severity = {
              min = vim.diagnostic.severity.HINT,
            },
            highlight = "DiagnosticUnderline",
          },
        }
      )
      vim.cmd [[
        highlight DiagnosticUnderlineError gui=underline
        highlight DiagnosticUnderlineWarn gui=underline
        highlight DiagnosticUnderlineInfo gui=underline
        highlight DiagnosticUnderlineHint gui=underline
      ]]
      vim.api.nvim_set_hl(0, code_hl_group, { bg = '#000000' })
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
        ensure_installed = { "bash", "lua", "vim", "vimdoc", "rust", "typescript", "javascript", "json", "tsx", "c_sharp" },
        highlight = { enable = true },
        indent = { enable = true }
      })
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.bond = {
        install_info = {
          url = "https://github.com/jorgenbele/tree-sitter-bond", -- local path or git repo
          files = {"src/parser.c"}, -- note that some parsers also require src/scanner.c or src/scanner.cc
        },
        filetype = "bond", -- if filetype does not match the parser name
      }

      vim.treesitter.language.register('bond', 'bond')

      vim.filetype.add({
        -- Detect and assign filetype based on the extension of the filename
        extension = {
          bond = "bond",
        },
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
            find_command = function(prompt)
              return {
                "rg",
                -- "--no-ignore",
                "--files",
                "--hidden",
                "--follow",
                "--no-heading",    -- Don't group matches by each file
                "--with-filename", -- Print the file path with the matched lines
                "--line-number",   -- Show line numbers
                "--column",        -- Show column numbers
                "--smart-case",    -- Smart case search
                "--glob",
                "!**/.git/*",
              }
            end
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
  --[[ {
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
  },]]
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    keys = {
      {
        '<c-s>p',
        function()
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
        max_lines = 5
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
    config = function()
      local treesj = require('treesj')
      local lang_utils = require('treesj.langs.utils')
      local cpp = require('treesj.langs.cpp')
      treesj.setup({
        use_default_keymaps = false,
        max_join_length = 1000,
        langs = {
          c_sharp = lang_utils.merge_preset(cpp, {})
        }
      })
    end,
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
      {
        '<leader>hr',
        function() require('gitsigns').reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end,
        desc = "hunk reset" , mode = "x"
      },
      {'<leader>us', function() require('gitsigns').undo_stage_hunk() end, desc = "undo stage" },
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
        '<leader>hb',
        function()
          require('gitsigns').blame_line({ full=true })
          vim.defer_fn(function() vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-w><c-w>", true, true, true), 'n') end, 500)
        end,
        desc = "hunk blame", mode = 'n'
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
          lualine_a = {"location"},
          lualine_b = {"progress"},
          lualine_c = {"filetype", "fileformat", "encoding"},
          lualine_x = {},
          lualine_y = {},
          lualine_z = {"vim.fn.expand('%')"},
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
        ["light_grey"] = "white",
        ["auto"] = "auto"
      }

      vim.api.nvim_create_user_command('SetStatusLineBG', function(opts)
        -- The following line tells lua to re-require the module, otherwise it just returns the cached module value
        package.loaded["lualine.themes.auto"] = nil
        local autoThemeLocal = require('lualine.themes.auto')
        autoThemeLocal.inactive = autoThemeLocal.normal
        autoThemeLocal.normal.c.gui = "bold"
        autoThemeLocal.inactive.c.gui = "bold"
        if opts.fargs[1] == "auto" then
          require('lualine').setup({ options = { theme = autoThemeLocal } })
        else
          autoThemeLocal.normal.c.bg = opts.fargs[1]
          autoThemeLocal.inactive.c.bg = opts.fargs[1]
          if contrastantColors[opts.fargs[1]] then
            autoThemeLocal.normal.c.fg = contrastantColors[opts.fargs[1]]
            autoThemeLocal.inactive.c.fg = contrastantColors[opts.fargs[1]]
          end
          require('lualine').setup({ options = { theme = autoThemeLocal } })
        end
      end, {
        nargs = 1,
        complete = function()
          return vim.tbl_keys(contrastantColors)
        end
      })
      vim.cmd("SetStatusLineBG light_grey")
    end
  },
  {
    "zbirenbaum/copilot-cmp",
    dependencies = "zbirenbaum/copilot.lua",
    cond = not vim.g.vscode,
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
      { '<leader>cc', function() require("CopilotChat").toggle() end, mode = { 'n', 'x' }, noremap = true },
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
    branch = "main",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
      { "nvim-telescope/telescope.nvim" },
    },
    build = Is_Windows() and nil or "make tiktoken", -- Only on MacOS or Linux
    config = function()
      require("CopilotChat").setup({
        debug = false, -- Enable debugging
        chat_autocomplete = true,
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
        contexts = {
          file = {
            input = function(callback)
              local telescope = require("telescope.builtin")
              local actions = require("telescope.actions")
              local action_state = require("telescope.actions.state")
              telescope.find_files({
                attach_mappings = function(prompt_bufnr)
                  actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    callback(selection[1])
                  end)
                  return true
                end,
              })
            end,
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
  },
  {
    "seblj/roslyn.nvim",
    event = { "VeryLazy" },
    opts = {
      filewatching = false,
      lock_target = false,
      broad_search = true
    }
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {
        '<c-f>b',
        function() vim.cmd("Neotree toggle") end,
        noremap = true, desc = "File Browser"
      }
    },
    opts = {
      window = { -- see https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup for
        position = "float",
        popup = { -- settings that apply to float position only
          size = {
            height = "80%",
            width = "90%",
          },
        },
        mappings = {
          ["<C-d>"] = { "scroll_preview", config = { direction = -10 } },
          ["<C-u>"] = { "scroll_preview", config = { direction = 10 } },
        }
      }
    }
  }
})

local config = {
  -- If a user has a sources list it will replace this one.
  -- Only sources listed here will be loaded.
  -- You can also add an external source by adding it's name to this list.
  -- The name used here must be the same name you would use in a require() call.
  sources = {
    "filesystem",
    "buffers",
    "git_status",
    -- "document_symbols",
  },
  add_blank_line_at_top = false, -- Add a blank line at the top of the tree.
  auto_clean_after_session_restore = false, -- Automatically clean up broken neo-tree buffers saved in sessions
  close_if_last_window = false, -- Close Neo-tree if it is the last window left in the tab
  default_source = "filesystem", -- you can choose a specific source `last` here which indicates the last used source
  enable_diagnostics = true,
  enable_git_status = true,
  enable_modified_markers = true, -- Show markers for files with unsaved changes.
  enable_opened_markers = true,   -- Enable tracking of opened files. Required for `components.name.highlight_opened_files`
  enable_refresh_on_write = true, -- Refresh the tree when a file is written. Only used if `use_libuv_file_watcher` is false.
  enable_cursor_hijack = false, -- If enabled neotree will keep the cursor on the first letter of the filename when moving in the tree.
  git_status_async = true,
  -- These options are for people with VERY large git repos
  git_status_async_options = {
    batch_size = 1000, -- how many lines of git status results to process at a time
    batch_delay = 10,  -- delay in ms between batches. Spreads out the workload to let other processes run.
    max_lines = 10000, -- How many lines of git status results to process. Anything after this will be dropped.
    -- Anything before this will be used. The last items to be processed are the untracked files.
  },
  hide_root_node = false, -- Hide the root node.
  retain_hidden_root_indent = false, -- IF the root node is hidden, keep the indentation anyhow. 
  -- This is needed if you use expanders because they render in the indent.
  log_level = "info", -- "trace", "debug", "info", "warn", "error", "fatal"
  log_to_file = false, -- true, false, "/path/to/file.log", use :NeoTreeLogs to show the file
  open_files_in_last_window = true, -- false = open files in top left window
  open_files_do_not_replace_types = { "terminal", "Trouble", "qf", "edgy" }, -- when opening files, do not use windows containing these filetypes or buftypes
  open_files_using_relative_paths = false,
  -- popup_border_style is for input and confirmation dialogs.
  -- Configurtaion of floating window is done in the individual source sections.
  -- "NC" is a special style that works well with NormalNC set
  popup_border_style = "NC", -- "double", "none", "rounded", "shadow", "single" or "solid"
  resize_timer_interval = 500, -- in ms, needed for containers to redraw right aligned and faded content
  -- set to -1 to disable the resize timer entirely
  --                           -- NOTE: this will speed up to 50 ms for 1 second following a resize
  sort_case_insensitive = false, -- used when sorting files and directories in the tree
  sort_function = nil , -- uses a custom function for sorting files and directories in the tree
  use_popups_for_input = true, -- If false, inputs will use vim.ui.input() instead of custom floats.
  use_default_mappings = true,
  -- source_selector provides clickable tabs to switch between sources.
  source_selector = {
    winbar = false, -- toggle to show selector on winbar
    statusline = false, -- toggle to show selector on statusline
    show_scrolled_off_parent_node = false, -- this will replace the tabs with the parent path
    -- of the top visible node when scrolled down.
    sources = {
      { source = "filesystem" },
      { source = "buffers" },
      { source = "git_status" },
    },
    content_layout = "start", -- only with `tabs_layout` = "equal", "focus"
    --                start  : |/ 󰓩 bufname     \/...
    --                end    : |/     󰓩 bufname \/...
    --                center : |/   󰓩 bufname   \/...
    tabs_layout = "equal", -- start, end, center, equal, focus
    --             start  : |/  a  \/  b  \/  c  \            |
    --             end    : |            /  a  \/  b  \/  c  \|
    --             center : |      /  a  \/  b  \/  c  \      |
    --             equal  : |/    a    \/    b    \/    c    \|
    --             active : |/  focused tab    \/  b  \/  c  \|
    truncation_character = "…", -- character to use when truncating the tab label
    tabs_min_width = nil, -- nil | int: if int padding is added based on `content_layout`
    tabs_max_width = nil, -- this will truncate text even if `text_trunc_to_fit = false`
    padding = 0, -- can be int or table
    -- padding = { left = 2, right = 0 },
    -- separator = "▕", -- can be string or table, see below
    separator = { left = "▏", right= "▕" },
    -- separator = { left = "/", right = "\\", override = nil },     -- |/  a  \/  b  \/  c  \...
    -- separator = { left = "/", right = "\\", override = "right" }, -- |/  a  \  b  \  c  \...
    -- separator = { left = "/", right = "\\", override = "left" },  -- |/  a  /  b  /  c  /...
    -- separator = { left = "/", right = "\\", override = "active" },-- |/  a  / b:active \  c  \...
    -- separator = "|",                                              -- ||  a  |  b  |  c  |...
    separator_active = nil, -- set separators around the active tab. nil falls back to `source_selector.separator`
    show_separator_on_edge = false,
    --                       true  : |/    a    \/    b    \/    c    \|
    --                       false : |     a    \/    b    \/    c     |
    highlight_tab = "NeoTreeTabInactive",
    highlight_tab_active = "NeoTreeTabActive",
    highlight_background = "NeoTreeTabInactive",
    highlight_separator = "NeoTreeTabSeparatorInactive",
    highlight_separator_active = "NeoTreeTabSeparatorActive",
  },
  --
  --event_handlers = {
  --  {
  --    event = "before_render",
  --    handler = function (state)
  --      -- add something to the state that can be used by custom components
  --    end
  --  },
  --  {
  --    event = "file_opened",
  --    handler = function(file_path)
  --      --auto close
  --      require("neo-tree.command").execute({ action = "close" })
  --    end
  --  },
  --  {
  --    event = "file_opened",
  --    handler = function(file_path)
  --      --clear search after opening a file
  --      require("neo-tree.sources.filesystem").reset_search()
  --    end
  --  },
  --  {
  --    event = "file_renamed",
  --    handler = function(args)
  --      -- fix references to file
  --      print(args.source, " renamed to ", args.destination)
  --    end
  --  },
  --  {
  --    event = "file_moved",
  --    handler = function(args)
  --      -- fix references to file
  --      print(args.source, " moved to ", args.destination)
  --    end
  --  },
  --  {
  --    event = "neo_tree_buffer_enter",
  --    handler = function()
  --      vim.cmd 'highlight! Cursor blend=100'
  --    end
  --  },
  --  {
  --    event = "neo_tree_buffer_leave",
  --    handler = function()
  --      vim.cmd 'highlight! Cursor guibg=#5f87af blend=0'
  --    end
  --  },
  -- {
  --   event = "neo_tree_window_before_open",
  --   handler = function(args)
  --     print("neo_tree_window_before_open", vim.inspect(args))
  --   end
  -- },
  -- {
  --   event = "neo_tree_window_after_open",
  --   handler = function(args)
  --     vim.cmd("wincmd =")
  --   end
  -- },
  -- {
  --   event = "neo_tree_window_before_close",
  --   handler = function(args)
  --     print("neo_tree_window_before_close", vim.inspect(args))
  --   end
  -- },
  -- {
  --   event = "neo_tree_window_after_close",
  --   handler = function(args)
  --     vim.cmd("wincmd =")
  --   end
  -- }
  --},
  default_component_configs = {
    container = {
      enable_character_fade = true,
      width = "100%",
      right_padding = 0,
    },
    --diagnostics = {
    --  symbols = {
    --    hint = "H",
    --    info = "I",
    --    warn = "!",
    --    error = "X",
    --  },
    --  highlights = {
    --    hint = "DiagnosticSignHint",
    --    info = "DiagnosticSignInfo",
    --    warn = "DiagnosticSignWarn",
    --    error = "DiagnosticSignError",
    --  },
    --},
    indent = {
      indent_size = 2,
      padding = 1,
      -- indent guides
      with_markers = true,
      indent_marker = "│",
      last_indent_marker = "└",
      highlight = "NeoTreeIndentMarker",
      -- expander config, needed for nesting files
      with_expanders = nil, -- if nil and file nesting is enabled, will enable expanders
      expander_collapsed = "",
      expander_expanded = "",
      expander_highlight = "NeoTreeExpander",
    },
    icon = {
      folder_closed = "",
      folder_open = "",
      folder_empty = "󰉖",
      folder_empty_open = "󰷏",
      -- The next two settings are only a fallback, if you use nvim-web-devicons and configure default icons there
      -- then these will never be used.
      default = "*",
      highlight = "NeoTreeFileIcon",
      provider = function(icon, node, state) -- default icon provider utilizes nvim-web-devicons if available
        if node.type == "file" or node.type == "terminal" then
          local success, web_devicons = pcall(require, "nvim-web-devicons")
          local name = node.type == "terminal" and "terminal" or node.name
          if success then
            local devicon, hl = web_devicons.get_icon(name)
            icon.text = devicon or icon.text
            icon.highlight = hl or icon.highlight
          end
        end
      end
    },
    modified = {
      symbol = "[+] ",
      highlight = "NeoTreeModified",
    },
    name = {
      trailing_slash = false,
      highlight_opened_files = false, -- Requires `enable_opened_markers = true`. 
      -- Take values in { false (no highlight), true (only loaded), 
      -- "all" (both loaded and unloaded)}. For more information,
      -- see the `show_unloaded` config of the `buffers` source.
      use_git_status_colors = true,
      highlight = "NeoTreeFileName",
    },
    git_status = {
      symbols = {
        -- Change type
        added     = "✚", -- NOTE: you can set any of these to an empty string to not show them
        deleted   = "✖",
        modified  = "",
        renamed   = "󰁕",
        -- Status type
        untracked = "",
        ignored   = "",
        unstaged  = "󰄱",
        staged    = "",
        conflict  = "",
      },
      align = "right",
    },
    -- If you don't want to use these columns, you can set `enabled = false` for each of them individually
    file_size = {
      enabled = true,
      width = 12, -- width of the column
      required_width = 64, -- min width of window required to show this column
    },
    type = {
      enabled = true,
      width = 10, -- width of the column
      required_width = 110, -- min width of window required to show this column
    },
    last_modified = {
      enabled = true,
      width = 20, -- width of the column
      required_width = 88, -- min width of window required to show this column
      format = "%Y-%m-%d %I:%M %p", -- format string for timestamp (see `:h os.date()`)
      -- or use a function that takes in the date in seconds and returns a string to display
      --format = require("neo-tree.utils").relative_date, -- enable relative timestamps
    },
    created = {
      enabled = false,
      width = 20, -- width of the column
      required_width = 120, -- min width of window required to show this column
      format = "%Y-%m-%d %I:%M %p", -- format string for timestamp (see `:h os.date()`)
      -- or use a function that takes in the date in seconds and returns a string to display
      --format = require("neo-tree.utils").relative_date, -- enable relative timestamps
    },
    symlink_target = {
      enabled = false,
      text_format = " ➛ %s", -- %s will be replaced with the symlink target's path.
    },
  },
  renderers = {
    directory = {
      { "indent" },
      { "icon" },
      { "current_filter" },
      {
        "container",
        content = {
          { "name", zindex = 10 },
          {
            "symlink_target",
            zindex = 10,
            highlight = "NeoTreeSymbolicLinkTarget",
          },
          { "clipboard", zindex = 10 },
          { "diagnostics", errors_only = true, zindex = 20, align = "right", hide_when_expanded = true },
          { "git_status", zindex = 10, align = "right", hide_when_expanded = true },
          { "file_size", zindex = 10, align = "right" },
          { "type", zindex = 10, align = "right" },
          { "last_modified", zindex = 10, align = "right" },
          { "created", zindex = 10, align = "right" },
        },
      },
    },
    file = {
      { "indent" },
      { "icon" },
      {
        "container",
        content = {
          {
            "name",
            zindex = 10
          },
          {
            "symlink_target",
            zindex = 10,
            highlight = "NeoTreeSymbolicLinkTarget",
          },
          { "clipboard", zindex = 10 },
          { "bufnr", zindex = 10 },
          { "modified", zindex = 20, align = "right" },
          { "diagnostics",  zindex = 20, align = "right" },
          { "git_status", zindex = 10, align = "right" },
          { "file_size", zindex = 10, align = "right" },
          { "type", zindex = 10, align = "right" },
          { "last_modified", zindex = 10, align = "right" },
          { "created", zindex = 10, align = "right" },
        },
      },
    },
    message = {
      { "indent", with_markers = false },
      { "name", highlight = "NeoTreeMessage" },
    },
    terminal = {
      { "indent" },
      { "icon" },
      { "name" },
      { "bufnr" }
    }
  },
  nesting_rules = {},
  -- Global custom commands that will be available in all sources (if not overridden in `opts[source_name].commands`)
  --
  -- You can then reference the custom command by adding a mapping to it:
  --    globally    -> `opts.window.mappings`
  --    locally     -> `opt[source_name].window.mappings` to make it source specific.
  --
  -- commands = {              |  window {                 |  filesystem {
  --   hello = function()      |    mappings = {           |    commands = {
  --     print("Hello world")  |      ["<C-c>"] = "hello"  |      hello = function()
  --   end                     |    }                      |        print("Hello world in filesystem")
  -- }                         |  }                        |      end
  --
  -- see `:h neo-tree-custom-commands-global`
  commands = {}, -- A list of functions

  window = { -- see https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup for
    -- possible options. These can also be functions that return these options.
    position = "left", -- left, right, top, bottom, float, current
    width = 40, -- applies to left and right positions
    height = 15, -- applies to top and bottom positions
    auto_expand_width = false, -- expand the window when file exceeds the window width. does not work with position = "float"
    popup = { -- settings that apply to float position only
      size = {
        height = "80%",
        width = "50%",
      },
      position = "50%", -- 50% means center it
      title = function (state) -- format the text that appears at the top of a popup window
        return "Neo-tree " .. state.name:gsub("^%l", string.upper)
      end,
      -- you can also specify border here, if you want a different setting from
      -- the global popup_border_style.
    },
    same_level = false, -- Create and paste/move files/directories on the same level as the directory under cursor (as opposed to within the directory under cursor).
    insert_as = "child", -- Affects how nodes get inserted into the tree during creation/pasting/moving of files if the node under the cursor is a directory:
    -- "child":   Insert nodes as children of the directory under cursor.
    -- "sibling": Insert nodes  as siblings of the directory under cursor.
    -- Mappings for tree window. See `:h neo-tree-mappings` for a list of built-in commands.
    -- You can also create your own commands by providing a function instead of a string.
    mapping_options = {
      noremap = true,
      nowait = true,
    },
    mappings = {
      ["<space>"] = {
        "toggle_node",
        nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
      },
      ["<2-LeftMouse>"] = "open",
      ["<cr>"] = "open",
      -- ["<cr>"] = { "open", config = { expand_nested_files = true } }, -- expand nested file takes precedence
      ["<esc>"] = "cancel", -- close preview or floating neo-tree window
      ["P"] = { "toggle_preview", config = {
        use_float = true,
        use_image_nvim = false,
        -- title = "Neo-tree Preview", -- You can define a custom title for the preview floating window.
      } },
      ["<C-f>"] = { "scroll_preview", config = {direction = -10} },
      ["<C-b>"] = { "scroll_preview", config = {direction = 10} },
      ["l"] = "focus_preview",
      ["S"] = "open_split",
      -- ["S"] = "split_with_window_picker",
      ["s"] = "open_vsplit",
      -- ["sr"] = "open_rightbelow_vs",
      -- ["sl"] = "open_leftabove_vs",
      -- ["s"] = "vsplit_with_window_picker",
      ["t"] = "open_tabnew",
      -- ["<cr>"] = "open_drop",
      -- ["t"] = "open_tab_drop",
      ["w"] = "open_with_window_picker",
      ["C"] = "close_node",
      ["z"] = "close_all_nodes",
      --["Z"] = "expand_all_nodes",
      ["R"] = "refresh",
      ["a"] = {
        "add",
        -- some commands may take optional config options, see `:h neo-tree-mappings` for details
        config = {
          show_path = "none", -- "none", "relative", "absolute"
        }
      },
      ["A"] = "add_directory", -- also accepts the config.show_path and config.insert_as options.
      ["d"] = "delete",
      ["r"] = "rename",
      ["b"] = "rename_basename",
      ["y"] = "copy_to_clipboard",
      ["x"] = "cut_to_clipboard",
      ["p"] = "paste_from_clipboard",
      ["c"] = "copy", -- takes text input for destination, also accepts the config.show_path and config.insert_as options
      ["m"] = "move", -- takes text input for destination, also accepts the config.show_path and config.insert_as options
      ["e"] = "toggle_auto_expand_width",
      ["q"] = "close_window",
      ["?"] = "show_help",
      ["<"] = "prev_source",
      [">"] = "next_source",
    },
  },
  filesystem = {
    window = {
      mappings = {
        ["H"] = "toggle_hidden",
        ["/"] = "fuzzy_finder",
        ["D"] = "fuzzy_finder_directory",
        --["/"] = "filter_as_you_type", -- this was the default until v1.28
        ["#"] = "fuzzy_sorter", -- fuzzy sorting using the fzy algorithm
        -- ["D"] = "fuzzy_sorter_directory",
        ["f"] = "filter_on_submit",
        ["<C-x>"] = "clear_filter",
        ["<bs>"] = "navigate_up",
        ["."] = "set_root",
        ["[g"] = "prev_git_modified",
        ["]g"] = "next_git_modified",
        ["i"] = "show_file_details", -- see `:h neo-tree-file-actions` for options to customize the window.
        ["o"] = { "show_help", nowait=false, config = { title = "Order by", prefix_key = "o" }},
        ["oc"] = { "order_by_created", nowait = false },
        ["od"] = { "order_by_diagnostics", nowait = false },
        ["og"] = { "order_by_git_status", nowait = false },
        ["om"] = { "order_by_modified", nowait = false },
        ["on"] = { "order_by_name", nowait = false },
        ["os"] = { "order_by_size", nowait = false },
        ["ot"] = { "order_by_type", nowait = false },
      },
      fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
        ["<down>"] = "move_cursor_down",
        ["<C-n>"] = "move_cursor_down",
        ["<up>"] = "move_cursor_up",
        ["<C-p>"] = "move_cursor_up",
        ["<esc>"] = "close"
      },
    },
    async_directory_scan = "auto", -- "auto"   means refreshes are async, but it's synchronous when called from the Neotree commands.
    -- "always" means directory scans are always async.
    -- "never"  means directory scans are never async.
    scan_mode = "shallow", -- "shallow": Don't scan into directories to detect possible empty directory a priori
    -- "deep": Scan into directories to detect empty or grouped empty directories a priori.
    bind_to_cwd = true, -- true creates a 2-way binding between vim's cwd and neo-tree's root
    cwd_target = {
      sidebar = "tab",   -- sidebar is when position = left or right
      current = "window" -- current is when position = current
    },
    check_gitignore_in_search = true, -- check gitignore status for files/directories when searching
    -- setting this to false will speed up searches, but gitignored
    -- items won't be marked if they are visible.
    -- The renderer section provides the renderers that will be used to render the tree.
    --   The first level is the node type.
    --   For each node type, you can specify a list of components to render.
    --       Components are rendered in the order they are specified.
    --         The first field in each component is the name of the function to call.
    --         The rest of the fields are passed to the function as the "config" argument.
    filtered_items = {
      visible = false, -- when true, they will just be displayed differently than normal items
      force_visible_in_empty_folder = false, -- when true, hidden files will be shown if the root folder is otherwise empty
      show_hidden_count = true, -- when true, the number of hidden items in each folder will be shown as the last entry
      hide_dotfiles = true,
      hide_gitignored = true,
      hide_hidden = true, -- only works on Windows for hidden files/directories
      hide_by_name = {
        ".DS_Store",
        "thumbs.db"
        --"node_modules",
      },
      hide_by_pattern = { -- uses glob style patterns
        --"*.meta",
        --"*/src/*/tsconfig.json"
      },
      always_show = { -- remains visible even if other settings would normally hide it
        --".gitignored",
      },
      always_show_by_pattern = { -- uses glob style patterns
        --".env*",
      },
      never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
        --".DS_Store",
        --"thumbs.db"
      },
      never_show_by_pattern = { -- uses glob style patterns
        --".null-ls_*",
      },
    },
    find_by_full_path_words = false,  -- `false` means it only searches the tail of a path.
    -- `true` will change the filter into a full path
    -- search with space as an implicit ".*", so
    -- `fi init`
    -- will match: `./sources/filesystem/init.lua
    --find_command = "fd", -- this is determined automatically, you probably don't need to set it
    --find_args = {  -- you can specify extra args to pass to the find command.
    --  fd = {
    --  "--exclude", ".git",
    --  "--exclude",  "node_modules"
    --  }
    --},
    ---- or use a function instead of list of strings
    --find_args = function(cmd, path, search_term, args)
    --  if cmd ~= "fd" then
    --    return args
    --  end
    --  --maybe you want to force the filter to always include hidden files:
    --  table.insert(args, "--hidden")
    --  -- but no one ever wants to see .git files
    --  table.insert(args, "--exclude")
    --  table.insert(args, ".git")
    --  -- or node_modules
    --  table.insert(args, "--exclude")
    --  table.insert(args, "node_modules")
    --  --here is where it pays to use the function, you can exclude more for
    --  --short search terms, or vary based on the directory
    --  if string.len(search_term) < 4 and path == "/home/cseickel" then
    --    table.insert(args, "--exclude")
    --    table.insert(args, "Library")
    --  end
    --  return args
    --end,
    group_empty_dirs = false, -- when true, empty folders will be grouped together
    search_limit = 50, -- max number of search results when using filters
    follow_current_file = {
      enabled = false, -- This will find and focus the file in the active buffer every time
      --               -- the current file is changed while the tree is open.
      leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
    },
    hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
    -- in whatever position is specified in window.position
    -- "open_current",-- netrw disabled, opening a directory opens within the
    -- window like netrw would, regardless of window.position
    -- "disabled",    -- netrw left alone, neo-tree does not handle opening dirs
    use_libuv_file_watcher = false, -- This will use the OS level file watchers to detect changes
    -- instead of relying on nvim autocmd events.
  },
  buffers = {
    bind_to_cwd = true,
    follow_current_file = {
      enabled = true, -- This will find and focus the file in the active buffer every time
      --              -- the current file is changed while the tree is open.
      leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
    },
    group_empty_dirs = true,  -- when true, empty directories will be grouped together
    show_unloaded = false,    -- When working with sessions, for example, restored but unfocused buffers
    -- are mark as "unloaded". Turn this on to view these unloaded buffer.
    terminals_first = false,  -- when true, terminals will be listed before file buffers
    window = {
      mappings = {
        ["<bs>"] = "navigate_up",
        ["."] = "set_root",
        ["bd"] = "buffer_delete",
        ["i"] = "show_file_details", -- see `:h neo-tree-file-actions` for options to customize the window.
        ["o"] = { "show_help", nowait=false, config = { title = "Order by", prefix_key = "o" }},
        ["oc"] = { "order_by_created", nowait = false },
        ["od"] = { "order_by_diagnostics", nowait = false },
        ["om"] = { "order_by_modified", nowait = false },
        ["on"] = { "order_by_name", nowait = false },
        ["os"] = { "order_by_size", nowait = false },
        ["ot"] = { "order_by_type", nowait = false },
      },
    },
  },
  git_status = {
    window = {
      mappings = {
        ["A"] = "git_add_all",
        ["gu"] = "git_unstage_file",
        ["ga"] = "git_add_file",
        ["gr"] = "git_revert_file",
        ["gc"] = "git_commit",
        ["gp"] = "git_push",
        ["gg"] = "git_commit_and_push",
        ["i"] = "show_file_details", -- see `:h neo-tree-file-actions` for options to customize the window.
        ["o"] = { "show_help", nowait=false, config = { title = "Order by", prefix_key = "o" }},
        ["oc"] = { "order_by_created", nowait = false },
        ["od"] = { "order_by_diagnostics", nowait = false },
        ["om"] = { "order_by_modified", nowait = false },
        ["on"] = { "order_by_name", nowait = false },
        ["os"] = { "order_by_size", nowait = false },
        ["ot"] = { "order_by_type", nowait = false },
      },
    },
  },
  document_symbols = {
    follow_cursor = false,
    client_filters = "first",
    renderers = {
      root = {
        {"indent"},
        {"icon", default="C" },
        {"name", zindex = 10},
      },
      symbol = {
        {"indent", with_expanders = true},
        {"kind_icon", default="?" },
        {"container",
          content = {
            {"name", zindex = 10},
            {"kind_name", zindex = 20, align = "right"},
          }
        }
      },
    },
    window = {
      mappings = {
        ["<cr>"] = "jump_to_symbol",
        ["o"] = "jump_to_symbol",
        ["A"] = "noop", -- also accepts the config.show_path and config.insert_as options.
        ["d"] = "noop",
        ["y"] = "noop",
        ["x"] = "noop",
        ["p"] = "noop",
        ["c"] = "noop",
        ["m"] = "noop",
        ["a"] = "noop",
        ["/"] = "filter",
        ["f"] = "filter_on_submit",
      },
    },
    custom_kinds = {
      -- define custom kinds here (also remember to add icon and hl group to kinds)
      -- ccls
      -- [252] = 'TypeAlias',
      -- [253] = 'Parameter',
      -- [254] = 'StaticMethod',
      -- [255] = 'Macro',
    },
    kinds = {
      Unknown = { icon = "?", hl = "" },
      Root = { icon = "", hl = "NeoTreeRootName" },
      File = { icon = "󰈙", hl = "Tag" },
      Module = { icon = "", hl = "Exception" },
      Namespace = { icon = "󰌗", hl = "Include" },
      Package = { icon = "󰏖", hl = "Label" },
      Class = { icon = "󰌗", hl = "Include" },
      Method = { icon = "", hl = "Function" },
      Property = { icon = "󰆧", hl = "@property" },
      Field = { icon = "", hl = "@field" },
      Constructor = { icon = "", hl = "@constructor" },
      Enum = { icon = "󰒻", hl = "@number" },
      Interface = { icon = "", hl = "Type" },
      Function = { icon = "󰊕", hl = "Function" },
      Variable = { icon = "", hl = "@variable" },
      Constant = { icon = "", hl = "Constant" },
      String = { icon = "󰀬", hl = "String" },
      Number = { icon = "󰎠", hl = "Number" },
      Boolean = { icon = "", hl = "Boolean" },
      Array = { icon = "󰅪", hl = "Type" },
      Object = { icon = "󰅩", hl = "Type" },
      Key = { icon = "󰌋", hl = "" },
      Null = { icon = "", hl = "Constant" },
      EnumMember = { icon = "", hl = "Number" },
      Struct = { icon = "󰌗", hl = "Type" },
      Event = { icon = "", hl = "Constant" },
      Operator = { icon = "󰆕", hl = "Operator" },
      TypeParameter = { icon = "󰊄", hl = "Type" },

      -- ccls
      -- TypeAlias = { icon = ' ', hl = 'Type' },
      -- Parameter = { icon = ' ', hl = '@parameter' },
      -- StaticMethod = { icon = '󰠄 ', hl = 'Function' },
      -- Macro = { icon = ' ', hl = 'Macro' },
    }
  },
  example = {
    renderers = {
      custom = {
        {"indent"},
        {"icon", default="C" },
        {"custom"},
        {"name"}
      }
    },
    window = {
      mappings = {
        ["<cr>"] = "toggle_node",
        ["<C-e>"] = "example_command",
        ["d"] = "show_debug_info",
      },
    },
  },
}
