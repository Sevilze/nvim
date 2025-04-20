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
        })

        vim.cmd("NvimTreeOpen")
        vim.notify("NvimTree reloaded with side = right", vim.log.levels.INFO)
      end, { desc = "Reload NvimTree with correct configuration" })

      return nvimtree_config
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
