-- Autosave plugin configuration
return {
  {
    "Pocco81/auto-save.nvim",
    lazy = false,
    config = function()
      local autosave = require("auto-save")
      vim.g.autosave_state = true

      autosave.setup({
        enabled = true,
        write_cmd = "write",
        execution_message = {
          message = function() return "" end,
          dim = 0,
          cleaning_interval = 1250,
        },
        -- More frequent trigger events for better responsiveness
        trigger_events = {
          "InsertLeave",
          "TextChanged",
          "TextChangedI",
          "CursorHold",
          "CursorHoldI",
          "FocusLost"
        },
        -- Define the condition function
        condition = function(buf)
          -- Check if autosave is globally disabled
          if vim.g.autosave_state == false then
            return false
          end

          -- Check if buffer is valid first
          if not buf or not vim.api.nvim_buf_is_valid(buf) then
            return false
          end

          local fn = vim.fn
          local utils = require("auto-save.utils.data")

          -- Don't save for certain filetypes
          if vim.tbl_contains({ "TelescopePrompt", "gitcommit", "gitrebase", "harpoon", "nvdash" }, vim.bo.filetype) then
            return false
          end

          -- Don't save for certain buftypes
          if vim.tbl_contains({ "prompt", "nofile", "help", "quickfix", "terminal" }, vim.bo.buftype) then
            return false
          end

          -- Don’t save if buffer has no path
          if fn.expand("%:p") == "" then
            return false
          end

          -- Don't save if buffer is read-only
          if vim.bo.readonly then
            return false
          end

          -- Don't save if buffer is empty
          if fn.getline(1) == "" and fn.line("$") == 1 then
            return false
          end

          -- Only save if buffer is modified
          if not vim.bo.modified then
            return false
          end

          return true
        end,
        write_all_buffers = false,
        debounce_delay = 100,
      })

      -- Add command to toggle autosave
      vim.api.nvim_create_user_command("ToggleAutoSave", function()
        vim.g.autosave_state = not vim.g.autosave_state

        if vim.g.autosave_state then
          autosave.on()
          vim.notify("Autosave enabled.", vim.log.levels.INFO)
        else
          autosave.off()
          vim.notify("Autosave disabled.", vim.log.levels.INFO)
        end
      end, { desc = "Toggle AutoSave" })
    end,
  },
}
