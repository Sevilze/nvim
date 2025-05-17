local M = {}

function M.setup()
  local map = vim.keymap.set
  
  map("n", "<leader>mi", ":MoltenInit<CR>", { desc = "Initialize Molten kernel", silent = true })
  map("n", "<leader>me", ":<C-u>MoltenEvaluateOperator<CR>", { desc = "Evaluate operator", mode = "n", silent = true })
  map("v", "<leader>me", ":<C-u>MoltenEvaluateVisual<CR>", { desc = "Evaluate visual selection", mode = "v", silent = true })
  map("n", "<leader>mr", ":MoltenReevaluateCell<CR>", { desc = "Re-evaluate cell", silent = true })
  map("n", "<leader>md", ":MoltenDelete<CR>", { desc = "Delete cell", silent = true })
  map("n", "<leader>mh", ":MoltenHideOutput<CR>", { desc = "Hide output", silent = true })
  map("n", "<leader>ms", ":noautocmd MoltenEnterOutput<CR>", { desc = "Enter output window", silent = true })
  map("n", "<leader>mo", ":MoltenOpenInBrowser<CR>", { desc = "Open in browser", silent = true })
  map("n", "<leader>mv", ":MoltenImportOutput<CR>", { desc = "Import output as cell", silent = true })

  map("n", "<leader>ma", ":MoltenEvaluateAll<CR>", { silent = true, desc = "Run all cells" })
  map("n", "<leader>mc", ":MoltenReevaluateCell<CR>", { silent = true, desc = "Rerun current cell" })
  map("n", "<leader>mx", ":MoltenInterrupt<CR>", { silent = true, desc = "Interrupt kernel" })
  map("n", "<leader>mk", ":MoltenRestart<CR>", { silent = true, desc = "Restart kernel" })
end

return M
