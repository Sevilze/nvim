-- LSP mappings
local map = vim.keymap.set

map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })
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
map("n", "<leader>dt", "<cmd>ToggleDiagnosticAutoRefresh<CR>", { desc = "Toggle diagnostic auto-refresh" })

-- Mason mappings
map("n", "<leader>lm", "<cmd>Mason<CR>", { desc = "Open Mason" })
map("n", "<leader>li", "<cmd>InstallLanguageServers<CR>", { desc = "Install all language servers" })
map("n", "<leader>lu", "<cmd>MasonUpdateAll<CR>", { desc = "Update all Mason packages" })
map("n", "<leader>lc", "<cmd>MasonStatus<CR>", { desc = "Check Mason package status" })
