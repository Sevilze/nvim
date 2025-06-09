return {
  {
    "Pocco81/auto-save.nvim",
    lazy = false,
    config = function()
      local autosave = require("auto-save")
      vim.g.autosave_state = true

      autosave.setup({
        enabled = true,
        write_cmd = function()
          vim.g._formatting_blocked = true
          vim.g._autosave_in_progress = true

          vim.cmd("silent! write")

          vim.schedule(function()
            vim.g._formatting_blocked = false
            vim.g._autosave_in_progress = false
          end)
        end,
        execution_message = {
          message = function() return "" end,
          dim = 0,
          cleaning_interval = 1250,
        },
        trigger_events = {
          "InsertLeave",
          "CursorHold",
          "FocusLost"
        },
        condition = function(buf)
          -- Check if autosave is globally disabled
          if vim.g.autosave_state == false then
            return false
          end

          -- Check if buffer is valid
          if not buf or not vim.api.nvim_buf_is_valid(buf) then
            return false
          end

          -- Don't save for certain filetypes
          local excluded_filetypes = { 
            "TelescopePrompt", "gitcommit", "gitrebase", "harpoon", 
            "nvdash", "help", "qf", "terminal" 
          }
          if vim.tbl_contains(excluded_filetypes, vim.bo[buf].filetype) then
            return false
          end

          -- Don't save for certain buftypes
          local excluded_buftypes = { "prompt", "nofile", "help", "quickfix", "terminal" }
          if vim.tbl_contains(excluded_buftypes, vim.bo[buf].buftype) then
            return false
          end

          -- Don't save if buffer has no path
          if vim.fn.expand("%:p") == "" then
            return false
          end

          -- Don't save if buffer is read-only
          if vim.bo[buf].readonly then
            return false
          end

          -- Don't save if buffer is empty
          if vim.fn.getline(1) == "" and vim.fn.line("$") == 1 then
            return false
          end

          -- Only save if buffer is modified
          if not vim.bo[buf].modified then
            return false
          end

          return true
        end,
        write_all_buffers = false,
        debounce_delay = 150,
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