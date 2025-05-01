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
          vim.notify("LazyGit theme updated to match NvChad theme: " .. theme_name, vim.log.levels.INFO)
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

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          update_lazygit_theme()
          local updated_chadrc = require("sevilzww.chadrc")
          local updated_theme = updated_chadrc.base46.theme or "tokyodark"
          vim.notify("Theme changed to " .. updated_theme .. ". Restart LazyGit to see changes.", vim.log.levels.INFO)
        end,
      })
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
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        -- css = { "prettier" },
        -- html = { "prettier" },
      },
      -- format_on_save = {
      --   -- These options will be passed to conform.format()
      --   timeout_ms = 500,
      --   lsp_fallback = true,
      -- },
    },
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
}
