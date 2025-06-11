local M = {}

-- Empty setup function to maintain compatibility with the existing require call in core/mappings.lua
function M.setup()
end

-- Set up buffer-specific LSP keymaps (called from on_attach)
function M.setup_buffer(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  local map = vim.keymap.set

  map("n", "<leader>rt", "<cmd>RustTest<CR>", opts)
  map("n", "<leader>rb", "<cmd>RustBuild<CR>", opts)
  map("n", "<leader>rc", "<cmd>RustCheck<CR>", opts)
  map("n", "<leader>rl", "<cmd>RustClippy<CR>", opts)
  map("n", "<leader>ro", "<cmd>RustOpenCargo<CR>", opts)
  map("n", "<leader>rd", "<cmd>RustDebug<CR>", opts)
  map("n", "<leader>rs", "<cmd>RustDebugStop<CR>", opts)

  map("n", "<leader>ra", function() vim.lsp.buf.code_action() end, opts)
  map("n", "<leader>rh", function() vim.lsp.buf.hover() end, opts)
end

return M
