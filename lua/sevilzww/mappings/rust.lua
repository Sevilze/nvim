local M = {}

-- Empty setup function to maintain compatibility with the existing require call in core/mappings.lua
function M.setup()
end

-- Set up buffer-specific LSP keymaps (called from on_attach)
function M.setup_buffer(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  local map = vim.keymap.set

  map("n", "<leader>rr", "<cmd>RustRun<CR>", opts)
  map("n", "<leader>rt", "<cmd>RustTest<CR>", opts)
  map("n", "<leader>rb", "<cmd>RustBuild<CR>", opts)
  map("n", "<leader>rc", "<cmd>RustCheck<CR>", opts)
  map("n", "<leader>rl", "<cmd>RustClippy<CR>", opts)
  map("n", "<leader>ro", "<cmd>RustOpenCargo<CR>", opts)
  map("n", "<leader>rd", "<cmd>RustDebug<CR>", opts)
  map("n", "<leader>rs", "<cmd>RustDebugStop<CR>", opts)

  map("n", "<leader>ra", function() vim.lsp.buf.code_action() end, opts)
  map("n", "<leader>rh", function() vim.lsp.buf.hover() end, opts)

  -- Rename function with references preview
  map("n", "<leader>rn", function()
    vim.ui.input({ prompt = "New name: " }, function(new_name)
      if new_name and new_name ~= "" then
        vim.lsp.buf.rename(new_name)
        vim.schedule(function()
          if _G.format_after_refactor then
            _G.format_after_refactor(vim.api.nvim_get_current_buf())
          end
        end)
      end
    end)
  end, opts)
end

return M
