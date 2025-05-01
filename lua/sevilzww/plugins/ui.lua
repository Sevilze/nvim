-- UI related plugins
return {
  {
    "nvchad/base46",
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  {
    "nvchad/ui",
    lazy = false,
    config = function()
      require "nvchad"
    end,
  },

  {
    "stevearc/dressing.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("dressing").setup({
        input = {
          enabled = true,
          default_prompt = "Input",
          prompt_align = "left",
          insert_only = true,
          start_in_insert = true,
          border = "rounded",
          relative = "cursor",

          prefer_width = 40,
          width = nil,
          max_width = { 140, 0.9 },
          min_width = { 20, 0.2 },

          win_options = {
            winblend = 10,
            wrap = false,
            list = true,
            listchars = "precedes:…,extends:…",
            sidescrolloff = 0,
          },

          mappings = {
            n = {
              ["<Esc>"] = "Close",
              ["<CR>"] = "Confirm",
            },
            i = {
              ["<C-c>"] = "Close",
              ["<CR>"] = "Confirm",
              ["<Up>"] = "HistoryPrev",
              ["<Down>"] = "HistoryNext",
            },
          },
        },
        select = {
          enabled = true,
          backend = { "telescope", "fzf_lua", "fzf", "builtin", "nui" },

          trim_prompt = true,
          telescope = nil,

          builtin = {
            border = "rounded",
            relative = "editor",

            win_options = {
              winblend = 10,
            },

            width = nil,
            max_width = { 140, 0.8 },
            min_width = { 40, 0.2 },
            height = nil,
            max_height = 0.9,
            min_height = { 10, 0.2 },

            mappings = {
              ["<Esc>"] = "Close",
              ["<C-c>"] = "Close",
              ["<CR>"] = "Confirm",
            },
          },
        },
      })

    end,
  },

  {
    "rcarriga/nvim-notify",
    lazy = false,
    priority = 1000,
    config = function()
      local notify = require("notify")
      notify.setup({
        background_colour = "#000000",
        max_width = 80,
        timeout = 100,
        render = "default",
        stages = "fade_in_slide_out",
        top_down = true,
      })

      vim.notify = notify
    end,
  },

  "nvzone/volt",
  "nvzone/menu",
  { "nvzone/minty", cmd = { "Huefy", "Shades" } },

  {
    "nvim-tree/nvim-web-devicons",
    opts = function()
      dofile(vim.g.base46_cache .. "devicons")
      return { override = require "nvchad.icons.devicons" }
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = "User FilePost",
    opts = {
      indent = { char = "│", highlight = "IblChar" },
      scope = { char = "│", highlight = "IblScopeChar" },
    },
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "blankline")

      local hooks = require "ibl.hooks"
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
      require("ibl").setup(opts)

      dofile(vim.g.base46_cache .. "blankline")
    end,
  },

  -- file tree
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = function()
      local nvimtree_config = require "nvchad.configs.nvimtree"

      nvimtree_config.view.side = "right"
      nvimtree_config.view.width = 35

      nvimtree_config.ui = nvimtree_config.ui or {}
      nvimtree_config.ui.confirm = {
        remove = true,
        trash = true,
      }

      nvimtree_config.renderer = nvimtree_config.renderer or {}
      nvimtree_config.renderer.icons = nvimtree_config.renderer.icons or {}
      nvimtree_config.renderer.icons.show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      }

      vim.api.nvim_create_user_command("CheckNvimTreeConfig", function()
        local tree_config = require("nvim-tree.config")
        local tree_view = tree_config.view
        local msg = "NvimTree configuration:\n"
        msg = msg .. "  side: " .. tostring(tree_view.side) .. "\n"
        msg = msg .. "  width: " .. tostring(tree_view.width)
        vim.notify(msg, vim.log.levels.INFO)
      end, { desc = "Check NvimTree configuration" })

      -- Create a command to force NvimTree to reload with the correct configuration
      vim.api.nvim_create_user_command("ReloadNvimTree", function()
        pcall(vim.cmd, "NvimTreeClose")

        for k, v in pairs(package.loaded) do
          if k:match("^nvim%-tree") then
            package.loaded[k] = nil
          end
        end

        local nvim_tree = require("nvim-tree")
        nvim_tree.setup({
          view = {
            side = "right",
            width = 35,
          },
          ui = {
            confirm = {
              remove = true,
              trash = true,
            }
          }
        })

        vim.cmd("NvimTreeOpen")
        vim.notify("NvimTree reloaded with side = right", vim.log.levels.INFO)
      end, { desc = "Reload NvimTree with correct configuration" })

      return nvimtree_config
    end,
    config = function(_, opts)
      require("nvim-tree").setup(opts)
    end,
  },

  {
    "folke/which-key.nvim",
    keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
    opts = function()
      dofile(vim.g.base46_cache .. "whichkey")
      return {}
    end,
  },
}
