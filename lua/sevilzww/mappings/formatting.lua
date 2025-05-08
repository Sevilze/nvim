local map = vim.keymap.set

-- Format current buffer
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "Format current buffer" })

map("n", "<leader>tf", "<cmd>ToggleFormatOnSave<CR>", { desc = "Toggle format on save" })
