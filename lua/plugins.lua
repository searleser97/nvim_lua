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

local javascriptFiletypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

local codeFileTypes = {
  "csharp",
  "lua",
  "rust",
  "cpp",
  "c",
  "cs",
  "ps1",
  "cmd",
  "json",
  "vim",
  "zsh",
  "markdown"
}

-- Add all javascript filetypes
for _, v in ipairs(javascriptFiletypes) do
  table.insert(codeFileTypes, v)
end

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
      { ']]', '<Plug>(leap-forward)',  mode = { 'n', 'x' } },
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
      { 'neovim/nvim-lspconfig' },             -- Required
      { 'williamboman/mason.nvim' },           -- Optional
      { 'williamboman/mason-lspconfig.nvim' }, -- Optional
      { 'nvim-telescope/telescope.nvim' },
    },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    event = { 'VeryLazy' },
    config = function()
      local lsp_zero = require("lsp-zero").preset({})

      local code_hl_group = "CodeHighlightGroup"
      local floating_highlight_map = {
        [vim.diagnostic.severity.ERROR] = 'DiagnosticFloatingError',
        [vim.diagnostic.severity.WARN] = 'DiagnosticFloatingWarn',
        [vim.diagnostic.severity.INFO] = 'DiagnosticFloatingInfo',
        [vim.diagnostic.severity.HINT] = 'DiagnosticFloatingHint',
      }
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
                table.insert(highlights,
                  { line = #combined, hl_group = code_hl_group, endCol = maxLineLength, startCol = 0 })
                table.insert(combined, leftPadding .. codeLine .. rightPadding)
              else -- same line
                if #codeLine == 0 then
                  local colDesc = "in column: " .. diagnostic.col
                  table.insert(highlights,
                    { line = #combined, hl_group = code_hl_group, endCol = #colDesc, startCol = 0 })
                  table.insert(combined, colDesc)
                else
                  table.insert(highlights,
                    { line = #combined, hl_group = code_hl_group, endCol = #codeLine, startCol = 0 })
                  table.insert(combined, codeLine)
                end
              end
            else
              table.insert(highlights,
                { line = #combined, hl_group = code_hl_group, endCol = maxLineLength, startCol = 0 })
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
            table.insert(highlights,
              {
                line = #combined,
                hl_group = floating_highlight_map[diagnostic.severity],
                endCol = #startOfDiagnosticMsg +
                    #msgLine + 1,
                startCol = #startOfDiagnosticMsg
              })
            table.insert(combined, formattedMsgLine)
          end
        end

        if #combined > 0 and #hoverContents > 0 then
          table.insert(combined, "----------------")
          table.insert(combined, "# LSP Info")
        end

        for _, hoverContent in pairs(hoverContents) do
          table.insert(combined, hoverContent)
        end

        if vim.tbl_isempty(combined) then
          return
        end

        local buf, win = vim.lsp.util.open_floating_preview(combined, "markdown",
          { border = 'rounded', focusable = true, focus = true })
        vim.api.nvim_set_current_win(win)
        local ns_id = vim.api.nvim_create_namespace("hover_diagnostics")
        for _, highlight in pairs(highlights) do
          vim.api.nvim_buf_set_extmark(buf, ns_id, highlight.line, highlight.startCol, {
            end_col = highlight.endCol,
            hl_group = highlight.hl_group,
            strict = false
          })
        end
      end, { noremap = true, desc = "Hover Info" })

      vim.api.nvim_set_hl(0, code_hl_group, { bg = '#000000' })

      lsp_zero.on_attach(function(client, buffer)
        -- lsp_zero.highlight_symbol(client, buffer)
        local telescope_builtin = require('telescope.builtin')
        vim.keymap.set('n', 'gd', telescope_builtin.lsp_definitions, { noremap = true, desc = "go to definition" })
        vim.keymap.set('n', 'gt', telescope_builtin.lsp_type_definitions,
          { noremap = true, desc = "go to type definition" })
        vim.keymap.set('n', 'gi', telescope_builtin.lsp_implementations,
          { noremap = true, desc = "go to implementation" })
        vim.keymap.set('n', 'gr', telescope_builtin.lsp_references, { noremap = true, desc = "go to references" })
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { noremap = true, desc = "go to references" })
        vim.keymap.set('n', '<leader>sd', function()
          vim.diagnostic.open_float()
          vim.diagnostic.open_float() -- the second call moves my cursor inside the diagnostic window
        end, { noremap = true, desc = "show diagnostics" })
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { noremap = true, desc = "code action" })
      end)

      local lua_opts = lsp_zero.nvim_lua_ls()
      lua_opts.settings.Lua = {
        runtime = { version = 'LuaJIT' },
        diagnostics = { globals = { 'vim' } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        telemetry = { enable = false }
      }
      vim.lsp.config('lua_ls', lua_opts)
      vim.lsp.config('rust_analyzer', {})
      vim.lsp.config('vtsls', {
        filetypes = javascriptFiletypes,
        init_options = {
          typescript = {
            tsserver = {
              maxTsServerMemory = 24576,
            },
            tsdk = "./node_modules/typescript/lib"
          }
        },
        settings = {
          typescript = {
            tsserver = {
              maxTsServerMemory = 24576,
            },
            tsdk = "./node_modules/typescript/lib"
          }
        },
        trace = "verbose",
      })
      vim.lsp.config('eslint', {
        filetypes = javascriptFiletypes,
      })
      vim.lsp.config('roslyn', {
        handlers = {
          ["workspace/_roslyn_projectNeedsRestore"] = function(_, _, _, _)
            vim.fn.system("dotnet restore")
            return true
          end,
        },
        filetypes = { "csharp", "cs" },
      })

      require("mason").setup({
        registries = {
          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        }
      })

      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "vtsls" }
      });

      -- terminal should support undercurl, when it comes to wezterm, we need to use nightly version when using it on windows
      -- or when using it in unix we need to run a set of commands that we can find in wezterm's wiki
      vim.cmd([[
        highlight DiagnosticUnderlineError gui=undercurl guisp=#FF0000
        highlight DiagnosticUnderlineWarn gui=undercurl guisp=#FFFF00
        highlight DiagnosticUnderlineInfo gui=undercurl guisp=#0000FF
        highlight DiagnosticUnderlineHint gui=undercurl guisp=#FFA500
      ]])

      vim.diagnostic.config({
        underline = true,
        severity_sort = true,
        virtual_text = false,
      })
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
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
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
          files = { "src/parser.c" },                             -- note that some parsers also require src/scanner.c or src/scanner.cc
        },
        filetype = "bond",                                        -- if filetype does not match the parser name
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
        '<c-s>fr',
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
        noremap = true,
        desc = "search files in repo"
      },
      {
        '<c-s>fp',
        function()
          require('telescope.builtin').find_files({
            cwd = require('myutils').getPathToProjectOr(
              require('myutils').getPathToGitDirOr(
                vim.loop.cwd()),
              { "*.csproj", "package.json", ".git" }
            ),
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
        noremap = true,
        desc = "search files in project"
      },
      {
        '<c-s>fh',
        function()
          require('telescope.builtin').find_files({
            cwd = require('myutils').getPathToCurrentDir({ "__tests?__" }),
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
        noremap = true,
        desc = "search files here"
      },
      {
        '<c-s>b',
        function()
          require('telescope.builtin').buffers()
        end,
        noremap = true,
        desc = "search buffers"
      },
      {
        '<c-s>m',
        function() require('telescope.builtin').marks() end,
        noremap = true,
        desc = "search marks"
      },
      {
        '<c-g>B',
        function() require('telescope.builtin').git_branches() end,
        noremap = true,
        desc = "git branches"
      },
      {
        '<c-g>S',
        function() require('telescope.builtin').git_stash() end,
        noremap = true,
        desc = "git stash"
      },
      {
        '<leader>help',
        function() require('telescope.builtin').help_tags() end,
        noremap = true
      },
      {
        '<c-s>s',
        function() require('telescope.builtin').treesitter() end,
        noremap = true,
        desc = "show symbols"
      }
    },
    dependencies = {
      "nvim-lua/plenary.nvim"
    },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
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
          path_display = { "tail" }, -- "smart", "tail"
          mappings = {
            i = {
              ["<cr>"] = actions.select_default,
              ["<c-Left>"] = actions.preview_scrolling_left,
              ["<c-Right>"] = actions.preview_scrolling_right,
              ["<c-Up>"] = actions.cycle_history_prev,
              ["<c-Down>"] = actions.cycle_history_next,
              ["<c-v>"] = function()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-r>+", true, true, true), 'i', false)
              end,
              ["<c-p>"] = function()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<c-r>"', true, true, true), 'i', false)
              end
            }
          }
        },
        extensions = {
          file_browser = {
            respect_gitignore = true,
            hidden = false,
            grouped = true,
            depth = 1,
            hijack_netrw = true,
            mappings = {
              ["i"] = {
                ["<C-o>"] = Is_Windows() and require("myutils").my_open or nil
              },
              ["n"] = {
                ["o"] = Is_Windows() and require("myutils").my_open or nil
              }
            }
          },
          recent_files = {
            only_cwd = true
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
    "nvim-telescope/telescope-live-grep-args.nvim",
    keys = {
      {
        '<c-s>pr',
        function()
          local fileType = vim.bo.filetype
          local isTypeScript = fileType == "typescript" or fileType == "typescriptreact"
          local pattern = isTypeScript and " -g \"*.ts*\" -g \"!*.test.ts*\"" or " -g \"*.*\""

          require("telescope-live-grep-args.shortcuts").grep_visual_selection({
            cwd = require('myutils').getPathToGitDirOr(vim.loop.cwd()),
            postfix = pattern
          })
        end,
        mode = 'x',
        noremap = true,
        desc = "search pattern repo"
      },
      {
        '<c-s>pp',
        function()
          require("telescope-live-grep-args.shortcuts").grep_visual_selection({
            cwd = require('myutils').getPathToProjectOr(
              require('myutils').getPathToGitDirOr(
                vim.loop.cwd()),
              { "*.csproj", "package.json", ".git" }
            ),
            postfix = pattern,
          })
        end,
        mode = 'x',
        noremap = true,
        desc = "search pattern project"
      },
      {
        '<c-s>ph',
        function()
          require("telescope-live-grep-args.shortcuts").grep_visual_selection({
            cwd = require('myutils').getPathToCurrentDir(),
            postfix = pattern,
          })
        end,
        mode = 'x',
        noremap = true,
        desc = "search pattern here"
      },
      {
        '<c-s>pr',
        function()
          require('telescope').extensions.live_grep_args.live_grep_args({
            cwd = require('myutils').getPathToGitDirOr(vim.loop.cwd()),
            postfix = " -g \"*.*\"",
          })
        end,
        mode = 'n',
        noremap = true,
        desc = "search pattern repo"
      },
      {
        '<c-s>pp',
        function()
          require('telescope').extensions.live_grep_args.live_grep_args({
            cwd = require('myutils').getPathToProjectOr(
              require('myutils').getPathToGitDirOr(
                vim.loop.cwd()),
              { "*.csproj", "package.json", ".git" }
            ),
            postfix = " -g \"*.*\"",
          })
        end,
        mode = 'n',
        noremap = true,
        desc = "search pattern project"
      },
      {
        '<c-s>ph',
        function()
          require('telescope').extensions.live_grep_args.live_grep_args({
            cwd = require('myutils').getPathToCurrentDir(),
            postfix = " -g \"*.*\"",
          })
        end,
        mode = 'n',
        noremap = true,
        desc = "search pattern here"
      }
    },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
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
        noremap = true,
        desc = "recent files"
      }
    },
    config = function()
      require("telescope").load_extension("recent_files")
    end,
    dependencies = { "nvim-telescope/telescope.nvim" },
    cond = not vim.g.vscode,
  },
  {
    "https://github.com/searleser97/harpoon",
    -- branch = "harpoon2",
    branch = "allow_data_to_use_partial_config_key_fn",
    keys = {
      {
        '<leader>ha',
        function() require('harpoon'):list(vim.g.session_name):add() end,
        noremap = true,
        desc = "harpoon add",
      },
      {
        '<c-h>l',
        function()
          require('harpoon').ui:toggle_quick_menu(require('harpoon'):list(vim.g.session_name), {
            ui_width_ratio = 0.95,
          })
        end,
        noremap = true,
        desc = "harpoon list"
      },
      unpack((function()
        local key_mappings = {}
        for i = 1, 10 do
          table.insert(key_mappings, {
            '<F' .. i .. '>',
            function() require('harpoon'):list(vim.g.session_name):select(i) end,
            noremap = true,
          })
        end
        return key_mappings
      end)())
    },
    dependencies = {
      "nvim-telescope/telescope.nvim"
    },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    config = function()
      -- harpoon depends on the current working directory remaining static through out the session
      -- therefore, in nvim-rooter, we are just setting directories related to source-control
      require("harpoon"):setup({
        settings = {
          key = function()
            return "single_harpoon_file_for_all_dirs"
          end,
        }
      })
    end
  },
  {
    'saghen/blink.cmp',
    cond = not vim.g.vscode,
    version = "1.*",
    dependencies = { "fang2hou/blink-copilot" },
    opts = {
      enabled = function() return vim.fn.expand('%:t') ~= "[Magenta Input]" end,
      completion = {
        documentation = { auto_show = true },
        menu = { auto_show = true },
        list = { selection = { preselect = false, auto_insert = false } },
      },
      signature = { enabled = true },
      sources = {
        default = { 'copilot', 'lsp', 'buffer', 'snippets', 'path' },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
          },
        },
      }
    }
  },
  {
    "hrsh7th/nvim-cmp",
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    opts = {
      enabled = function() return vim.fn.expand('%:t') == "[Magenta Input]" end
    }
  },
  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    ft = codeFileTypes,
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    config = function()
      require("tokyonight").setup({
        style = "storm", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
        transparent = true,
        on_colors = function(colors)
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
          if mode == 'V' then
            return "<Plug>(comment_toggle_linewise_visual)"
          elseif mode == 'v' then
            return "<Plug>(comment_toggle_blockwise_visual)"
          end
        end,
        mode = 'x',
        noremap = true,
        expr = true,
        replace_keycodes = true,
        desc = "comment toggle"
      },
      {
        '<leader>ct',
        '<Plug>(comment_toggle_linewise_current)',
        noremap = true,
        desc = "comment toggle"
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
    cmd = 'ToggleTerm',
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
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    event = { 'VeryLazy' }
  },
  {
    "notjedi/nvim-rooter.lua",
    config = function()
      require("nvim-rooter").setup({
        rooter_patterns = { '*_root.txt', '.git', '.hg', '.svn' }
      })
    end,
    cond = not vim.g.vscode,
    ft = codeFileTypes
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
        noremap = true,
        desc = "toggle split",
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
    config = function()
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
    cond = false and not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    config = function()
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
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    event = { 'VeryLazy' },
    config = function()
      require("ibl").setup()
    end,
  },
  {
    "sindrets/diffview.nvim",
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
    keys = {
      {
        'gs',
        "<cmd>DiffviewOpen<cr>",
        noremap = true,
        desc = "git status",
        mode = { 'n' }
      },
      {
        '<c-g>L',
        "<cmd>DiffviewFileHistory -n=512<cr>",
        noremap = true,
        desc = "git log branch",
        mode = { 'n' }
      },
      {
        'gl',
        "<cmd>DiffviewFileHistory % -n=512<cr>",
        noremap = true,
        desc = "git log file",
        mode = { 'n' }
      },
      {
        'gl',
        ":DiffviewFileHistory % -L<line1>,<line2> -n=512<CR>",
        noremap = true,
        desc = "git log visual range",
        mode = { 'v' }
      },
      {
        '<c-g>dm',
        "<cmd>DiffviewOpen main..HEAD<cr>",
        noremap = true,
        desc = "git diff with given branch",
        mode = { 'n' }
      },
      {
        '<c-g>im',
        function()
          local merge_commit = vim.fn.input("merge commit: ")
          -- using three dots (...) in the commit range is equivalent to:
          -- git diff --name-only $(git merge-base merge_commit^2 merge_commit^1) merge_commit^1
          -- https://stackoverflow.com/questions/7251477/what-are-the-differences-between-double-dot-and-triple-dot-in-git-dif
          local cmd = "git diff --name-only " .. merge_commit .. "^2..." .. merge_commit .. "^1"
          local file_paths_output = vim.fn.system(cmd):gsub("\r\n", "\n")
          local file_paths = vim.fn.map(vim.split(file_paths_output, "\n", { trimempty = true }),
            function(_, path) return '"' .. path .. '"' end)
          local joined_file_paths = table.concat(file_paths, " ")
          local diffview_cmd = "DiffviewOpen " .. merge_commit .. "^1.." .. merge_commit .. " -- " .. joined_file_paths
          vim.cmd(diffview_cmd)
        end,
        noremap = true,
        desc = "git inspect merge commit",
        mode = { 'n' }
      },
    },
    config = function()
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
    event = { 'VeryLazy' },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile()
  },
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      -- Actions
      { '<leader>hs', function() require('gitsigns').stage_hunk() end, desc = "hunk stage" },
      { '<leader>hr', function() require('gitsigns').reset_hunk() end, desc = "hunk reset" },
      {
        '<leader>hr',
        function() require('gitsigns').reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
        desc = "hunk reset",
        mode = "x"
      },
      { '<leader>us', function() require('gitsigns').undo_stage_hunk() end, desc = "undo stage" },
      {
        '<leader>hp',
        function()
          require('gitsigns').preview_hunk()
          require('gitsigns').preview_hunk()
        end,
        desc = "hunk preview"
      },
      { '<leader>td', function() require('gitsigns').toggle_deleted() end,  desc = "toggle deleted lines" },
      {
        '<leader>hs',
        function() require('gitsigns').stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
        desc = "hunk stage",
        mode = "x"
      },
      {
        '<leader>hb',
        function()
          require('gitsigns').blame_line({ full = true })
        end,
        desc = "hunk blame",
        mode = 'n'
      },
      {
        ']c',
        function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() require('gitsigns').next_hunk() end)
          return '<Ignore>'
        end,
        expr = true,
        desc = "Hunk Next"
      },
      {
        '[c',
        function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() require('gitsigns').prev_hunk() end)
          return '<Ignore>'
        end,
        expr = true,
        desc = "Hunk Prev"
      }
    },
    event = { 'VeryLazy' },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    config = function()
      require('gitsigns').setup()
    end
  },
  {
    "ruifm/gitlinker.nvim",
    keys = {
      {
        '<leader>cl',
        function()
          require("gitlinker").get_buf_range_url("n",
            { action_callback = require("gitlinker.actions").copy_to_clipboard })
        end,
        silent = true,
        desc = "copy link to current line"
      },
      {
        '<leader>cl',
        function()
          require("gitlinker").get_buf_range_url("v",
            { action_callback = require("gitlinker.actions").copy_to_clipboard })
        end,
        silent = true,
        mode = 'v',
        desc = "copy link to selected lines"
      }
    },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    config = function()
      local handler = function(url_data)
        local base_url = require "gitlinker.hosts".get_base_https_url(url_data)
        local normalized_file_path = url_data.file:gsub("\\", "/")
        local repo_path = require('myutils').getPathToGitDirOr(vim.loop.cwd())
        local relative_file_path = normalized_file_path:gsub("^" .. vim.pesc(repo_path) .. "[/\\]?", "")
        local url = base_url .. "?path=/" .. relative_file_path
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
          ["domoreexp.visualstudio.com"] = handler,
          ["dev.azure.com"] = handler,
        }
      })
    end,
  },
  {
    "searleser97/sessions.nvim",
    lazy = vim.fn.argc() > 0,
    priority = 1000,
    keys = {
      { "<c-o>s", function() require('session_utils').open_session_action() end, noremap = true, desc = "open session" },
      { "<c-s>S", ":SessionsSave ",                                              noremap = true, desc = "Save new Session" }
    },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    dependencies = {
      "echasnovski/mini.pick"
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
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
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
    ft = codeFileTypes,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'folke/tokyonight.nvim',
      opt = true,
    },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    config = function()
      local autoTheme = require('lualine.themes.auto')
      require('lualine').setup({
        options = {
          theme = autoTheme,
        },
        sections = {
          lualine_a = { "location" },
          lualine_b = { "progress" },
          lualine_c = { "filetype", "fileformat", "encoding" },
          lualine_x = {},
          lualine_y = {},
          lualine_z = { "vim.fn.expand('%')" },
        },
        inactive_sections = {
          lualine_a = { "location" },
          lualine_b = { "progress" },
          lualine_c = { "filetype", "fileformat", "encoding" },
          lualine_x = {},
          lualine_y = {},
          lualine_z = { "vim.fn.expand('%')" },
        },
        tabline = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_z = { 'tabs' },
          lualine_y = { "vim.g.session_name" }
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
    "pteroctopus/faster.nvim",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode and vim.fn.argc() > 0,
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
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
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
      { "nvim-lua/plenary.nvim" },  -- for curl, log wrapper
      { "nvim-telescope/telescope.nvim" },
    },
    build = Is_Windows() and nil or "make tiktoken", -- Only on MacOS or Linux
    config = function()
      require("CopilotChat").setup({
        model = "claude-3.7-sonnet",
        debug = false, -- Enable debugging
        chat_autocomplete = true,
        context = "quickfix",
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
    cond = not isNeovimOpenedWithGitFile(),
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
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
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
    "seblyng/roslyn.nvim",
    event = { "VeryLazy" },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    opts = {
      filewatching = "roslyn",
      lock_target = true,
      broad_search = false
    }
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    lazy = vim.fn.argc() == 0,
    keys = {
      {
        '<c-f>t',
        function() vim.cmd("Neotree toggle reveal_file=%:p") end,
        noremap = true,
        desc = "File Tree"
      }
    },
    opts = {
      window = {  -- see https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup for
        position = "float",
        popup = { -- settings that apply to float position only
          size = {
            height = "80%",
            width = "90%",
          },
        },
        mappings = {
          ["<PageDown>"] = { "scroll_preview", config = { direction = -10 } },
          ["<PageUp>"] = { "scroll_preview", config = { direction = 10 } },
          ["z"] = function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("z", true, false, true), 'n', false) end,
          ["Z"] = "close_all_nodes"
        }
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        hijack_netrw_behavior = "open_current"
      }
    }
  },
  {
    'stevearc/quicker.nvim',
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    ft = 'qf',
    event = "FileType qf",
    keys = {
      {
        '<leader>qa',
        function()
          local current_bufnr = vim.api.nvim_get_current_buf()
          local current_line_number = vim.api.nvim_win_get_cursor(0)[1]
          local qflist = vim.fn.getqflist()
          for _, item in ipairs(qflist) do
            if item.bufnr == current_bufnr and item.lnum == current_line_number then
              print("Current line already in quickfix list")
              return
            end
          end
          local current_line = vim.api.nvim_get_current_line()
          local line_number = vim.api.nvim_win_get_cursor(0)[1]
          local filename = vim.api.nvim_buf_get_name(current_bufnr)
          vim.fn.setqflist({
            {
              filename = filename,
              lnum = line_number,
              text = current_line,
            },
          }, 'a')
          print(filename .. " added to quickfix list")
        end,
        desc = "quickfix list add current file",
        noremap = true
      },
      {
        '<c-q>e',
        function()
          require("quicker").close()
          vim.fn.setqflist({})
          print("quickfix list cleared")
        end,
        desc = "quickfix empty",
        noremap = true
      },
      {
        "<c-q>t",
        function()
          require("quicker").toggle()
        end,
        desc = "Toggle quickfix context",
      },
    },
    opts = {
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      }
    }
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    keys = {
      {
        "<c-f>br",
        function()
          require("telescope").extensions.file_browser.file_browser({
            cwd = require('myutils').getPathToGitDirOr(vim.loop.cwd()),
          })
        end,
        noremap = true,
        desc = "File Browser in Repository"
      },
      {
        "<c-f>bp",
        function()
          require("telescope").extensions.file_browser.file_browser({
            cwd = require('myutils').getPathToProjectOr(
              require('myutils').getPathToGitDirOr(
                vim.loop.cwd()),
              { "*.csproj", "package.json", ".git" }
            ),
          })
        end,
        noremap = true,
        desc = "File Browser in Project"
      },
      {
        "<c-f>bh",
        function()
          require("telescope").extensions.file_browser.file_browser({
            cwd = require('myutils').getPathToCurrentDir(),
          })
        end,
        noremap = true,
        desc = "File Browser here"
      }
    },
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
  },
  {
    "FabijanZulj/blame.nvim",
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    keys = {
      {
        "<leader>gb",
        "<cmd>BlameToggle<cr>",
        noremap = true,
        desc = "Git Blame"
      }
    },
    opts = {}
  },
  {
    "echasnovski/mini.pick",
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    lazy = false,
    opts = {}
  },
  {
    "mfussenegger/nvim-dap",
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
  },
  {
    "nicholasmata/nvim-dap-cs",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    opts = {}
  },
  {
    "rcarriga/nvim-dap-ui",
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    dependencies = {
      "mfussenegger/nvim-dap",
    },
  },
  {
    -- "dlants/magenta.nvim",
    dir = "~/dev/magenta.nvim",
    cond = not vim.g.vscode and not isNeovimOpenedWithGitFile(),
    lazy = false,
    keys = {
      {
        "<leader>mt",
        function()
          require("magenta").toggle()
        end,
        noremap = true,
        desc = "Toggle Magenta"
      },
      {
        "<c-m>",
        "<Cmd>Magenta predict-edit<CR>",
        mode = { "i", "n" }
      }
    },
    build = "npm install --frozen-lockfile",
    opts = {
      sidebarPosition = "leftabove",
      profiles = {
        {
          name = "copilot",
          provider = "copilot",
          model = "claude-sonnet-4",
          fastModel = "gpt-4o-mini",
        }
      }
    },
  },
  {
    "sphamba/smear-cursor.nvim",
    opts = {
      smear_insert_mode = false,
    }
  },
  {
    "dmtrKovalenko/fff.nvim",
    build = "cargo build --release",
    -- or if you are using nixos
    -- build = "nix run .#release",
    opts = {
      -- pass here all the options
    },
    keys = {
      {
        "ff", -- try it if you didn't it is a banger keybinding for a picker
        function()
          require("fff").find_files() -- or find_in_git_root() if you only want git files
        end,
        desc = "Open file picker",
      },
    },
  }
})
