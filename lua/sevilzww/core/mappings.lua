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
map("i", "jk", "<Esc>", { desc = "escape insert mode" })

local function safe_undo_redo(operation, mode_prefix)
  mode_prefix = mode_prefix or ""
  return function()
    vim.api.nvim_exec_autocmds("User", { pattern = "UndoRedoOperation" })
    if mode_prefix == "" then
      vim.cmd("normal! " .. operation)
    else
      vim.cmd("normal! " .. mode_prefix .. operation)
    end
  end
end

map("i", "<C-z>", safe_undo_redo("u", "<C-o>"), { desc = "undo in insert mode" })
map("i", "<C-S-z>", safe_undo_redo("<C-r>", "<C-o>"), { desc = "redo in insert mode" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

map("n", "<C-z>", safe_undo_redo("u"), { desc = "undo" })
map("n", "<C-S-z>", safe_undo_redo("<C-r>"), { desc = "redo" })

-- Undo and redo in visual mode
map("v", "<C-z>", function()
  vim.api.nvim_exec_autocmds("User", { pattern = "UndoRedoOperation" })
  vim.cmd("normal! \\<Esc>u")
end, { desc = "undo in visual mode" })
map("v", "<C-S-z>", function()
  vim.api.nvim_exec_autocmds("User", { pattern = "UndoRedoOperation" })
  vim.cmd("normal! \\<Esc>\\<C-r>")
end, { desc = "redo in visual mode" })

local function safe_paste(paste_cmd)
  return function()
    vim.g._formatting_blocked = true
    vim.schedule(function()
      vim.g._formatting_blocked = false
    end)
    vim.cmd("normal! " .. paste_cmd)
  end
end

map("n", "p", safe_paste("p"), { desc = "paste after cursor (safe)" })
map("n", "P", safe_paste("P"), { desc = "paste before cursor (safe)" })
map("v", "p", safe_paste("p"), { desc = "paste in visual mode (safe)" })
map("v", "P", safe_paste("P"), { desc = "paste in visual mode (safe)" })

map("i", "<C-v>", function()
  vim.g._formatting_blocked = true
  vim.schedule(function()
    vim.g._formatting_blocked = false
  end)
  return "<C-r>+"
end, { desc = "paste from clipboard (safe)", expr = true })

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

-- require("sevilzww.core.file_deletion_blocker").setup()

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
require("sevilzww.mappings.autosave")
require("sevilzww.mappings.rust").setup()
require("sevilzww.mappings.flutter").setup()
require("sevilzww.mappings.swap_cleaner").setup()
require("sevilzww.mappings.lazygit").setup()
require("sevilzww.mappings.git_conflict").setup()
require("sevilzww.mappings.diffview").setup()
require("sevilzww.mappings.refactoring").setup()

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
