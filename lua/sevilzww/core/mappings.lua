-- Core mappings (not plugin-specific)
require "nvchad.mappings"

local map = vim.keymap.set

-- General mappings
map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

-- Undo and redo in insert mode
map("i", "<C-z>", "<C-o>u", { desc = "undo in insert mode" })
map("i", "<C-S-z>", "<C-o><C-r>", { desc = "redo in insert mode" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

-- Undo and redo in normal mode
map("n", "<C-z>", "u", { desc = "undo" })
map("n", "<C-S-z>", "<C-r>", { desc = "redo" })

-- Undo and redo in visual mode
map("v", "<C-z>", "<Esc>u", { desc = "undo in visual mode" })
map("v", "<C-S-z>", "<Esc><C-r>", { desc = "redo in visual mode" })

map("n", "<leader>n", function()
  vim.opt.number = not vim.opt.number:get()
  vim.notify("Line numbers: " .. (vim.opt.number:get() and "ON" or "OFF"))
end, { desc = "toggle line number" })

map("n", "<leader>rn", function()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
  vim.notify("Relative line numbers: " .. (vim.opt.relativenumber:get() and "ON" or "OFF"))
end, { desc = "toggle relative number" })

map("n", "<leader>hn", function()
  local number = vim.opt.number:get()
  local relativenumber = vim.opt.relativenumber:get()

  if number and relativenumber then
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.notify("Hybrid line numbers: OFF")
  else
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.notify("Hybrid line numbers: ON")
  end
end, { desc = "toggle hybrid line numbers" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })

-- Load mappings for various plugins
require("sevilzww.mappings.nvimtree")
require("sevilzww.mappings.buffers")
require("sevilzww.mappings.terminal")
require("sevilzww.mappings.lsp")
require("sevilzww.mappings.harpoon")
require("sevilzww.mappings.augment")
require("sevilzww.mappings.whichkey")
require("sevilzww.mappings.formatting")
require("sevilzww.mappings.new_instance")
require("sevilzww.mappings.swap_cleaner").setup()

local telescope_ok, _ = pcall(require, "telescope")
if telescope_ok then
  require("sevilzww.mappings.telescope")
else
  vim.api.nvim_create_autocmd("User", {
    pattern = "TelescopeLoaded",
    callback = function()
      require("sevilzww.mappings.telescope")
    end,
  })
end
