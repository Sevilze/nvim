-- Augment mappings
local map = vim.keymap.set

map("n", "<leader>aa", "<cmd>Augment chat<CR>", { desc = "augment chat" })
map("n", "<leader>as", "<cmd>Augment chat-new<CR>", { desc = "augment new chat" })
map("n", "<leader>ad", "<cmd>Augment chat-toggle<CR>", { desc = "augment toggle chat" })
