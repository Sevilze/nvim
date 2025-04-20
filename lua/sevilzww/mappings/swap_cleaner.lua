-- Swap file cleaner mappings and commands
local M = {}

M.setup = function()
  -- Create a command to clean swap files
  vim.api.nvim_create_user_command("CleanSwapFiles", function()
    local swap_dir = vim.fn.expand("~/.local/state/nvim/swap")
    local cmd = string.format("find %s -type f -name \"*.swp\" -delete", swap_dir)
    local result = vim.fn.system(cmd)
    
    local cmd2 = string.format("find %s -type f -name \"*.swo\" -delete", swap_dir)
    local result2 = vim.fn.system(cmd2)
    
    vim.notify("Neovim swap files cleaned", vim.log.levels.INFO)
  end, { desc = "Clean Neovim swap files" })
  
  vim.keymap.set("n", "<leader>cs", "<cmd>CleanSwapFiles<CR>", { desc = "clean swap files" })
end

return M
