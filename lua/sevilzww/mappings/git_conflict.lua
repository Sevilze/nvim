local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>gco", "<cmd>GitConflictChooseOurs<CR>", { desc = "Choose our changes" })
  vim.keymap.set("n", "<leader>gct", "<cmd>GitConflictChooseTheirs<CR>", { desc = "Choose their changes" })
  vim.keymap.set("n", "<leader>gcb", "<cmd>GitConflictChooseBoth<CR>", { desc = "Choose both changes" })
  vim.keymap.set("n", "<leader>gc0", "<cmd>GitConflictChooseNone<CR>", { desc = "Choose no changes" })
  vim.keymap.set("n", "<leader>gcn", "<cmd>GitConflictNextConflict<CR>", { desc = "Next conflict" })
  vim.keymap.set("n", "<leader>gcp", "<cmd>GitConflictPrevConflict<CR>", { desc = "Previous conflict" })
  vim.keymap.set("n", "<leader>gcl", "<cmd>GitConflictListQf<CR>", { desc = "List all conflicts" })
end

return M
