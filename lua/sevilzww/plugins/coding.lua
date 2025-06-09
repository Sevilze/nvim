-- Coding related plugins
return {
  {
    "kdheepak/lazygit.nvim",
    lazy = false,
    keys = {
      { "<leader>gg", desc = "LazyGit" },
      { "<leader>gf", desc = "LazyGit Filter" },
      { "<leader>gc", desc = "LazyGit Current File" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    init = function()
      require("sevilzww.mappings.lazygit").setup()
    end,
    config = function()
      local colors = require("base46").get_theme_tb("base_30")

      vim.g.lazygit_floating_window_winblend = 0
      vim.g.lazygit_floating_window_scaling_factor = 0.9
      vim.g.lazygit_floating_window_border_chars = {'╭','─', '╮', '│', '╯','─', '╰', '│'}
      vim.g.lazygit_floating_window_use_plenary = 1
      vim.g.lazygit_use_neovim_remote = 0

      vim.g.lazygit_floating_window_highlight = {
        border = "FloatBorder",
        default = "Normal",
      }

      local function update_lazygit_theme()
        local chadrc = require("sevilzww.chadrc")
        local theme_name = chadrc.base46.theme or "tokyodark"

        local colors = require("base46").get_theme_tb("base_30")
        local base16 = require("base46").get_theme_tb("base_16")

        local config_dir = vim.fn.expand("~/.config/lazygit")
        local config_file = config_dir .. "/config.yml"

        if vim.fn.isdirectory(config_dir) == 0 then
          vim.fn.mkdir(config_dir, "p")
        end

        local theme_mapping = {
          -- Active elements
          activeBorderColor = colors.blue,
          optionsTextColor = colors.blue,
          searchingActiveBorderColor = colors.orange,

          -- Background elements
          selectedLineBgColor = colors.black2,
          selectedRangeBgColor = colors.darker_black,

          -- Git related colors
          cherryPickedCommitBgColor = colors.green,
          cherryPickedCommitFgColor = base16.base00,
          unstagedChangesColor = colors.red,
          commitGraphColor = colors.blue,
          filesChangesColor = colors.teal,

          inactiveBorderColor = "#565f89",
          defaultFgColor = colors.white,
        }

        local f = io.open(config_file, "w")
        if f then
          f:write("# LazyGit configuration - Using NvChad theme: " .. theme_name .. "\n")
          f:write("gui:\n")
          f:write("  nerdFontsVersion: 3\n")
          f:write("  border: 'rounded'\n")
          f:write("  showBottomLine: false\n")

          -- Write theme configuration with dynamically loaded colors
          f:write("  theme:\n")
          f:write("    lightTheme: false\n")
          f:write("    activeBorderColor:\n")
          f:write("      - '" .. theme_mapping.activeBorderColor .. "'\n")
          f:write("      - bold\n")
          f:write("    inactiveBorderColor:\n")
          f:write("      - '" .. theme_mapping.inactiveBorderColor .. "'\n")
          f:write("    optionsTextColor:\n")
          f:write("      - '" .. theme_mapping.optionsTextColor .. "'\n")
          f:write("    selectedLineBgColor:\n")
          f:write("      - '" .. theme_mapping.selectedLineBgColor .. "'\n")
          f:write("    selectedRangeBgColor:\n")
          f:write("      - '" .. theme_mapping.selectedRangeBgColor .. "'\n")
          f:write("    cherryPickedCommitBgColor:\n")
          f:write("      - '" .. theme_mapping.cherryPickedCommitBgColor .. "'\n")
          f:write("    cherryPickedCommitFgColor:\n")
          f:write("      - '" .. theme_mapping.cherryPickedCommitFgColor .. "'\n")
          f:write("    unstagedChangesColor:\n")
          f:write("      - '" .. theme_mapping.unstagedChangesColor .. "'\n")
          f:write("    defaultFgColor:\n")
          f:write("      - '" .. theme_mapping.defaultFgColor .. "'\n")
          f:write("    searchingActiveBorderColor:\n")
          f:write("      - '" .. theme_mapping.searchingActiveBorderColor .. "'\n")
          f:write("    commitGraphColor:\n")
          f:write("      - '" .. theme_mapping.commitGraphColor .. "'\n")
          f:write("    filesChangesColor:\n")
          f:write("      - '" .. theme_mapping.filesChangesColor .. "'\n")
          f:close()
        else
          vim.notify("Failed to update LazyGit config file", vim.log.levels.ERROR)
        end
      end

      update_lazygit_theme()

      vim.api.nvim_create_user_command("LazyGitUpdateTheme", function()
        update_lazygit_theme()
      end, { desc = "Update LazyGit theme to match current NvChad theme" })

      local lazygit_module = require("lazygit")

      if type(lazygit_module.lazygit_filter) ~= "function" then
        lazygit_module.lazygit_filter = function()
          vim.cmd("LazyGitFilter")
        end
      end

      if type(lazygit_module.lazygit_current_file) ~= "function" then
        lazygit_module.lazygit_current_file = function()
          vim.cmd("LazyGitCurrentFile")
        end
      end

      -- Function to export theme colors for tmux
      local function export_tmux_theme_colors()
        package.loaded["sevilzww.chadrc"] = nil
        local chadrc = require("sevilzww.chadrc")
        local theme_name = chadrc.base46.theme or "tokyodark"

        package.loaded["base46"] = nil
        local colors = require("base46").get_theme_tb("base_30")

        local tmux_colors = {
          HEADER_COLOR = colors.blue,
          ACTION_COLOR = colors.orange,
          SESSION_COLOR = colors.teal,
          TEXT_COLOR = colors.white,
          BG_COLOR = colors.black,
          BG_SELECT_COLOR = colors.darker_black or colors.black2 or colors.lightbg,
          BORDER_COLOR = colors.grey,
          PROMPT_COLOR = colors.blue,
          POINTER_COLOR = colors.blue,
          SPINNER_COLOR = colors.blue,
          INFO_COLOR = colors.blue,
          MARKER_COLOR = colors.blue,
          HL_COLOR = colors.grey,
          HL_SELECT_COLOR = colors.blue,
          THEME_NAME = theme_name
        }

        if theme_name == "tokyodark" then
          tmux_colors.BORDER_COLOR = "#565f89"
        end

        local tmux_config_dir = vim.fn.expand("~/.config/tmux")
        local tmux_theme_file = tmux_config_dir .. "/theme_colors.sh"

        if vim.fn.isdirectory(tmux_config_dir) == 0 then
          vim.fn.mkdir(tmux_config_dir, "p")
        end

        local f = io.open(tmux_theme_file, "w")
        if f then
          f:write("#!/bin/bash\n")
          f:write("# NvChad theme colors for tmux - Theme: " .. theme_name .. "\n")
          f:write("# Generated on: " .. os.date() .. "\n\n")

          for var_name, color in pairs(tmux_colors) do
            f:write("export " .. var_name .. "=\"" .. color .. "\"\n")
          end

          f:close()
          vim.fn.system("chmod +x " .. tmux_theme_file)

          if vim.fn.executable("tmux") == 1 and vim.fn.system("tmux -V 2>/dev/null") ~= "" then
            local nvim_config_dir = vim.fn.stdpath("config")
            local copy_cmd = string.format("cd %s && cp .tmux.conf ~/.tmux.conf 2>/dev/null || true", nvim_config_dir)
            vim.fn.system(copy_cmd)
            vim.fn.system("tmux source-file ~/.tmux.conf 2>/dev/null || true")

            local theme_msg = string.format("Theme updated to: %s", theme_name)
            vim.fn.system(string.format('tmux display-message "%s" 2>/dev/null || true', theme_msg))
          end
        else
          vim.notify("Failed to export tmux theme colors", vim.log.levels.ERROR)
        end
      end

      export_tmux_theme_colors()

      vim.api.nvim_create_user_command("UpdateTheme", function()
        package.loaded["sevilzww.chadrc"] = nil
        local updated_chadrc = require("sevilzww.chadrc")
        local updated_theme = updated_chadrc.base46.theme or "tokyodark"
        update_lazygit_theme()
        export_tmux_theme_colors()

        vim.notify("Theme changed to " .. updated_theme .. ". Tmux and LazyGit themes updated.", vim.log.levels.INFO)
      end, { desc = "Update tmux theme colors to match current NvChad theme" })
      vim.keymap.set("n", "<leader>tu", "<cmd>UpdateTheme<CR>", { desc = "Update tmux theme" })
    end,
  },

  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("git-conflict").setup({
        default_mappings = false,
        default_commands = true,
        disable_diagnostics = false,
        highlights = {
          incoming = "DiffAdd",
          current = "DiffText",
        },
      })

      require("sevilzww.mappings.git_conflict").setup()
    end,
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    config = function()
      local diffview_mappings = require("sevilzww.mappings.diffview")

      require("diffview").setup({
        diff_binaries = false,
        enhanced_diff_hl = false,
        git_cmd = { "git" },
        use_icons = true,
        icons = {
          folder_closed = "",
          folder_open = "",
        },
        signs = {
          fold_closed = "",
          fold_open = "",
          done = "✓",
        },
        view = {
          default = {
            layout = "diff2_horizontal",
            winbar_info = false,
          },
          merge_tool = {
            layout = "diff3_horizontal",
            disable_diagnostics = true,
            winbar_info = false,
          },
          file_history = {
            layout = "diff2_horizontal",
            winbar_info = false,
          },
        },
        file_panel = {
          listing_style = "tree",
          tree_options = {
            flatten_dirs = true,
            folder_statuses = "only_folded",
          },
          win_config = {
            position = "right",
            width = 35,
            win_opts = {}
          },
        },
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                diff_merges = "combined",
              },
              multi_file = {
                diff_merges = "first-parent",
              },
            },
          },
          win_config = {
            position = "bottom",
            height = 16,
            win_opts = {}
          },
        },
        commit_log_panel = {
          win_config = {
            win_opts = {},
          }
        },
        default_args = {
          DiffviewOpen = {},
          DiffviewFileHistory = {},
        },
        hooks = {},
        keymaps = diffview_mappings.get_keymaps(),
      })

      diffview_mappings.setup()
    end,
  },

  -- formatting
  {
    "stevearc/conform.nvim",
    lazy = false,
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = function()
      local conform_config = require("sevilzww.configs.conform")
      return {
        formatters_by_ft = conform_config.formatters_by_ft,
        format_on_save = false,
        format_after_save = false,
        notify_on_error = true,
      }
    end,
    config = function(_, opts)
      local conform = require("conform")
      conform.setup(opts)

      vim.g.format_on_buffer_leave = true
      vim.g.format_on_refactor = true

      local function format_buffer(bufnr, reason)
        bufnr = bufnr or vim.api.nvim_get_current_buf()

        if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_name(bufnr) == "" then return end
        local filetype = vim.bo[bufnr].filetype
        local excluded_fts = { "TelescopePrompt", "gitcommit", "gitrebase", "harpoon", "nvdash", "help", "qf" }
        if vim.tbl_contains(excluded_fts, filetype) then return end

        if reason == "buffer_leave" then
          if vim.api.nvim_buf_line_count(bufnr) == 1 and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == "" then return end
        end

        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")

        conform.format({
          bufnr = bufnr,
          timeout_ms = 4000,
          lsp_fallback = true,
          quiet = true,
        }, function(err, did_format)
            if err then
              vim.notify("Formatting failed for " .. filename .. ": " .. tostring(err), vim.log.levels.WARN)
            elseif did_format and reason == "buffer_leave" and vim.g.format_on_buffer_leave then
              vim.notify("Formatted on leave: " .. filename, vim.log.levels.INFO)
            end
        end)
      end

      local original_conform_format = conform.format
      conform.format = function(options, cb)
        -- Block formatting if autosave is running
        if vim.g._autosave_in_progress or vim.g._formatting_blocked then
          return
        end
        return original_conform_format(options, cb)
      end
      
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "Disable LSP formatting capabilities",
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
      })

      -- Format when leaving a buffer
      vim.api.nvim_create_autocmd("BufHidden", {
        group = vim.api.nvim_create_augroup("FormatOnBufferLeave", { clear = true }),
        desc = "Format buffer on leave",
        callback = function(args)
          if vim.g.format_on_buffer_leave then
            vim.schedule(function() format_buffer(args.buf, "buffer_leave") end)
          end
        end,
      })

      -- Block formatting during undo/redo
      vim.api.nvim_create_autocmd("User", {
        pattern = "UndoRedoOperation",
        callback = function()
            vim.g._formatting_blocked = true
            vim.schedule(function() vim.g._formatting_blocked = false end)
        end,
      })

      -- Expose the global function for the refactoring plugin to call
      _G.format_after_refactor = function(bufnr)
        if vim.g.format_on_refactor then
           vim.schedule(function() format_buffer(bufnr, "refactor") end)
        end
      end

      -- User commands for toggling behavior
      vim.api.nvim_create_user_command("ToggleFormatOnBufferLeave", function()
        vim.g.format_on_buffer_leave = not vim.g.format_on_buffer_leave
        local status = vim.g.format_on_buffer_leave and "enabled" or "disabled"
        vim.notify("Format on buffer leave " .. status, vim.log.levels.INFO)
      end, { desc = "Toggle format on buffer leave" })

      vim.api.nvim_create_user_command("ToggleFormatOnRefactor", function()
        vim.g.format_on_refactor = not vim.g.format_on_refactor
        local status = vim.g.format_on_refactor and "enabled" or "disabled"
        vim.notify("Format on refactor " .. status, vim.log.levels.INFO)
      end, { desc = "Toggle format on refactor" })
    end,
  },

  -- load luasnips + cmp related in insert mode only
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      {
        -- snippet plugin
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        config = function(_, opts)
          require("luasnip").config.set_config(opts)
          require "nvchad.configs.luasnip"
        end,
      },

      -- autopairing of (){}[] etc
      {
        "windwp/nvim-autopairs",
        opts = {
          fast_wrap = {},
          disable_filetype = { "TelescopePrompt", "vim" },
        },
        config = function(_, opts)
          require("nvim-autopairs").setup(opts)

          -- setup cmp for autopairs
          local cmp_autopairs = require "nvim-autopairs.completion.cmp"
          require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
      },

      -- cmp sources plugins
      {
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
      },
    },
    opts = function()
      return require "nvchad.configs.cmp"
    end,
  },

  -- Refactoring plugin with Telescope integration
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
    },
    lazy = false,
    config = function()
      local refactoring = require("refactoring")

      refactoring.setup({
        prompt_func_return_type = {
          go = true,
          java = true,
          cpp = true,
          c = true,
          h = true,
          hpp = true,
          cxx = true,
          rust = true,
        },
        prompt_func_param_type = {
          go = true,
          java = true,
          cpp = true,
          c = true,
          h = true,
          hpp = true,
          cxx = true,
          rust = true,
        },
        printf_statements = {},
        print_var_statements = {},
        show_success_message = true,
      })

      require("telescope").load_extension("refactoring")

      local telescope = require("telescope")
      telescope.setup({
        extensions = {
          refactoring = {
            theme = "dropdown",
            layout_config = {
              width = 0.8,
              height = 0.9,
              prompt_position = "top",
            },
            sorting_strategy = "ascending",
          }
        }
      })

      require("sevilzww.mappings.refactoring").setup()
    end,
  },
}
