-- New Neovim instance with terminal mappings
local map = vim.keymap.set

-- Function to launch a new Neovim instance with a terminal using tmux
local function launch_nvim_with_terminal()
  local current_dir = vim.fn.getcwd()
  local in_tmux = vim.env.TMUX ~= nil
  local terminal_cmd

  if in_tmux then
    -- If already in tmux, create a new window with nvim and terminal
    terminal_cmd = string.format("tmux new-window -c \"%s\" -n \"nvim+term\" \"nvim -c 'terminal'\"", current_dir)
  else
    -- If not in tmux, start a new tmux session with nvim and terminal
    terminal_cmd = string.format("tmux new-session -c \"%s\" -d -s nvim-term \"nvim -c 'terminal'\" && tmux attach-session -t nvim-term", current_dir)
  end
  vim.fn.system(terminal_cmd)
  vim.notify("Launched new Neovim instance with terminal in tmux", vim.log.levels.INFO)
end

map("n", "<leader>h", function()
  launch_nvim_with_terminal()
end, { desc = "launch new nvim instance with terminal" })

-- Create a command to launch a new Neovim instance with terminal
vim.api.nvim_create_user_command("NewNvimWithTerminal", function()
  launch_nvim_with_terminal()
end, { desc = "Launch a new Neovim instance with terminal" })
