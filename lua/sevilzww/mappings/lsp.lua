-- LSP mappings
local map = vim.keymap.set

-- Function to toggle the diagnostic list globally
local function toggle_diagnostic_list()
  local wins = vim.fn.getloclist(0, { winid = 0 })
  local is_loclist_open = wins.winid ~= 0

  if is_loclist_open then
    vim.cmd("lclose")
    vim.notify("Diagnostic list closed", vim.log.levels.INFO)
  else
    local diagnostics = vim.diagnostic.get()
    if #diagnostics > 0 then
      vim.diagnostic.setloclist({ open = true })
      vim.notify("Diagnostic list opened", vim.log.levels.INFO)
    else
      vim.notify("No diagnostics to display", vim.log.levels.INFO)
    end
  end
end

map("n", "<leader>ds", toggle_diagnostic_list, { desc = "Toggle diagnostic list" })
map("n", "<leader>dr", function()
  local diagnostics = vim.diagnostic.get()

  -- Only try to refresh if there are diagnostics
  if #diagnostics > 0 then
    vim.diagnostic.setloclist({ open = false })
    vim.notify("Diagnostic list refreshed", vim.log.levels.INFO)
  else
    vim.notify("No diagnostics to display", vim.log.levels.INFO)
  end
end, { desc = "Refresh diagnostic loclist" })

-- Mason mappings
map("n", "<leader>lm", "<cmd>Mason<CR>", { desc = "Open Mason" })
map("n", "<leader>li", "<cmd>InstallLanguageServers<CR>", { desc = "Install all language servers" })
map("n", "<leader>lu", "<cmd>MasonUpdateAll<CR>", { desc = "Update all Mason packages" })
map("n", "<leader>lc", "<cmd>MasonStatus<CR>", { desc = "Check Mason package status" })
