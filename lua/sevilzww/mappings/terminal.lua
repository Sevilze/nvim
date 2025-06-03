-- Terminal mappings
local map = vim.keymap.set

local function get_current_dir()
  local file_dir = vim.fn.expand("%:p:h")

  -- If we're not in a file, use the current working directory
  if file_dir == "" then
    return vim.fn.getcwd()
  end

  return file_dir
end

-- Function to open a terminal in the current directory
local function open_terminal_in_current_dir()
  local current_dir = get_current_dir()
  require("nvchad.term").new {
    pos = "sp",
    cmd = "cd " .. current_dir .. " && $SHELL",
  }

  vim.notify("Terminal opened in: " .. current_dir, vim.log.levels.INFO)
end

-- terminal escape key
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- Other terminal mappings
map("n", "<leader>ht", function()
  require("nvchad.term").new { pos = "sp" }
end, { desc = "terminal new horizontal term" })

map("n", "<leader>v", function()
  require("nvchad.term").new { pos = "vsp" }
end, { desc = "terminal new vertical term" })

-- toggleable
map({ "n", "t" }, "<A-v>", function()
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "terminal toggleable vertical term" })

map({ "n", "t" }, "<A-g>", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "terminal toggleable horizontal term" })

map({ "n", "t" }, "<A-i>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })
