-- Core options configuration
require "nvchad.options"

vim.g.augment_workspace_folders = { vim.fn.expand("~/.config/nvim") }
-- Initialize global autosave state (true = enabled)
if vim.g.autosave_state == nil then
  vim.g.autosave_state = true
end
local opt = vim.opt

opt.number = true
opt.relativenumber = true
vim.cmd([[set number relativenumber]])

-- Create a command to check line number settings
vim.api.nvim_create_user_command("CheckLineNumbers", function()
  local number = vim.opt.number:get()
  local relativenumber = vim.opt.relativenumber:get()
  local msg = "Line number settings:\n"
  msg = msg .. "  number: " .. tostring(number) .. "\n"
  msg = msg .. "  relativenumber: " .. tostring(relativenumber)
  vim.notify(msg, vim.log.levels.INFO)
end, { desc = "Check line number settings" })

-- Create a command to force enable hybrid line numbers
vim.api.nvim_create_user_command("EnableHybridNumbers", function()
  vim.opt.number = false
  vim.opt.relativenumber = false

  vim.defer_fn(function()
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.cmd([[redraw]])
    vim.notify("Hybrid line numbers enabled", vim.log.levels.INFO)
  end, 100)
end, { desc = "Force enable hybrid line numbers" })

-- Create an autocmd to ensure line numbers are displayed correctly
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
  pattern = "*",
  callback = function()
    if vim.bo.buftype == "" and vim.bo.filetype ~= "nvdash" and
       not (vim.opt.number:get() and vim.opt.relativenumber:get()) then
      vim.opt.number = true
      vim.opt.relativenumber = true
    end
  end,
})

-- Create an autocmd that runs after Neovim has fully started
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      -- Only set line numbers for actual file buffers, not the dashboard
      if vim.bo.buftype == "" and vim.bo.filetype ~= "nvdash" then
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.cmd([[redraw]])
      end
    end, 100)
  end,
})

-- Cursor line highlighting
opt.cursorline = true

-- Other options
opt.scrolloff = 8        -- Keep 8 lines above/below cursor when scrolling
opt.sidescrolloff = 8    -- Keep 8 columns left/right of cursor when scrolling horizontally
opt.signcolumn = "yes"   -- Always show the sign column to avoid text shifting
