local map = vim.keymap.set

-- Format current buffer
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "Format current buffer" })

-- Toggle formatting behaviors
map("n", "<leader>tfl", "<cmd>ToggleFormatOnBufferLeave<CR>", { desc = "Toggle format on buffer leave" })
map("n", "<leader>tfr", "<cmd>ToggleFormatOnRefactor<CR>", { desc = "Toggle format on refactor" })
