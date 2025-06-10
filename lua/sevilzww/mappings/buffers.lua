-- Buffer mappings
local map = vim.keymap.set

-- Autoformatting function before buffer or window leave operations
local function format_and_save_before_action(action_name, action_callback)
  local current_buf = vim.api.nvim_get_current_buf()
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(current_buf), ":t")

  if vim.g.format_on_buffer_leave and vim.api.nvim_buf_is_valid(current_buf) and vim.api.nvim_buf_get_name(current_buf) ~= "" then
    local filetype = vim.bo[current_buf].filetype
    local excluded_fts = { "TelescopePrompt", "gitcommit", "gitrebase", "harpoon", "nvdash", "help", "qf" }

    if not vim.tbl_contains(excluded_fts, filetype) then
      if vim.g.debug_formatting then
        vim.notify("Pre-" .. action_name .. " formatting for: " .. filename, vim.log.levels.DEBUG)
      end

      local conform = require("conform")
      local formatters = conform.list_formatters(current_buf)

      if #formatters > 0 then
        local success, err = pcall(function()
          conform.format({
            bufnr = current_buf,
            timeout_ms = 4000,
            lsp_fallback = true,
            quiet = true,
            async = false,
            _allow_buffer_leave = true,
          })
        end)

        if success then
          vim.notify("Pre-" .. action_name .. " formatted: " .. filename, vim.log.levels.INFO)
        else
          vim.notify("Pre-" .. action_name .. " formatting failed for " .. filename .. ": " .. tostring(err), vim.log.levels.WARN)
        end

        if vim.bo[current_buf].modified then
          local save_success = pcall(function()
            vim.api.nvim_buf_call(current_buf, function()
              -- Temporarily disable autosave to prevent conflicts
              local autosave_state = vim.g.autosave_state
              vim.g.autosave_state = false
              vim.cmd("silent! write")

              -- Restore autosave state
              vim.g.autosave_state = autosave_state
            end)
          end)

          if not save_success then
            vim.notify("Failed to save " .. filename .. " after formatting", vim.log.levels.WARN)
          end
        end
      end

      -- Ensure buffer is not modified before action to prevent prompts
      if vim.bo[current_buf].modified then
        -- Force save if still modified
        pcall(function()
          vim.api.nvim_buf_call(current_buf, function()
            vim.cmd("silent! write!")
          end)
        end)
      end
    end
  end

  -- Execute the action (close buffer or quit window)
  action_callback()
end

-- tabufline
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })

map("n", "<tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

map("n", "<leader>x", function()
  format_and_save_before_action("buffer close", function()
    require("nvchad.tabufline").close_buffer()
  end)
end, { desc = "buffer close" })

map("n", "<leader><leader>x", function()
  format_and_save_before_action("window quit", function()
    vim.cmd("q")
  end)
end, { desc = "quit window" })

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })
