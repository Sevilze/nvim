-- Tmux integration plugins
return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    priority = 1000,
    config = function()
      if vim.env.TMUX == nil or vim.env.TMUX == "" then
        vim.env.TMUX = "force-tmux-mode"
        vim.notify("Forced TMUX environment variable for vim-tmux-navigator", vim.log.levels.INFO)
      end

      vim.g.tmux_navigator_no_mappings = 1

      -- Normal mode mappings with alt keys
      vim.api.nvim_set_keymap('n', '<A-Left>', ':TmuxNavigateLeft<CR>', { silent = true, noremap = true })
      vim.api.nvim_set_keymap('n', '<A-Down>', ':TmuxNavigateDown<CR>', { silent = true, noremap = true })
      vim.api.nvim_set_keymap('n', '<A-Up>', ':TmuxNavigateUp<CR>', { silent = true, noremap = true })
      vim.api.nvim_set_keymap('n', '<A-Right>', ':TmuxNavigateRight<CR>', { silent = true, noremap = true })

      vim.api.nvim_set_keymap('n', '<A-h>', ':TmuxNavigateLeft<CR>', { silent = true, noremap = true })
      vim.api.nvim_set_keymap('n', '<A-j>', ':TmuxNavigateDown<CR>', { silent = true, noremap = true })
      vim.api.nvim_set_keymap('n', '<A-k>', ':TmuxNavigateUp<CR>', { silent = true, noremap = true })
      vim.api.nvim_set_keymap('n', '<A-l>', ':TmuxNavigateRight<CR>', { silent = true, noremap = true })

      -- Terminal mode mappings with alt keys
      -- vim.api.nvim_set_keymap('t', '<A-Left>', '<C-\\><C-n>:TmuxNavigateLeft<CR>', { silent = true, noremap = true })
      -- vim.api.nvim_set_keymap('t', '<A-Down>', '<C-\\><C-n>:TmuxNavigateDown<CR>', { silent = true, noremap = true })
      -- vim.api.nvim_set_keymap('t', '<A-Up>', '<C-\\><C-n>:TmuxNavigateUp<CR>', { silent = true, noremap = true })
      -- vim.api.nvim_set_keymap('t', '<A-Right>', '<C-\\><C-n>:TmuxNavigateRight<CR>', { silent = true, noremap = true })

      -- vim.api.nvim_set_keymap('t', '<A-h>', '<C-\\><C-n>:TmuxNavigateLeft<CR>', { silent = true, noremap = true })
      -- vim.api.nvim_set_keymap('t', '<A-j>', '<C-\\><C-n>:TmuxNavigateDown<CR>', { silent = true, noremap = true })
      -- vim.api.nvim_set_keymap('t', '<A-k>', '<C-\\><C-n>:TmuxNavigateUp<CR>', { silent = true, noremap = true })
      -- vim.api.nvim_set_keymap('t', '<A-l>', '<C-\\><C-n>:TmuxNavigateRight<CR>', { silent = true, noremap = true })
    end,
  },

  {
    "preservim/vimux",
    lazy = true,
    cmd = {
      "VimuxRunCommand",
      "VimuxRunLastCommand",
      "VimuxOpenRunner",
      "VimuxCloseRunner",
      "VimuxInspectRunner",
      "VimuxInterruptRunner",
      "VimuxZoomRunner",
      "VimuxClearRunnerHistory",
    },
    config = function()
      -- Set up Vimux configuration
      vim.g.VimuxHeight = "30"
      vim.g.VimuxOrientation = "h"
      vim.g.VimuxUseNearest = 1

      vim.keymap.set("n", "<leader>tr", ":VimuxRunCommand<Space>", { desc = "tmux run command" })
      vim.keymap.set("n", "<leader>tl", ":VimuxRunLastCommand<CR>", { desc = "tmux run last command" })
      vim.keymap.set("n", "<leader>to", ":VimuxOpenRunner<CR>", { desc = "tmux open runner" })
      vim.keymap.set("n", "<leader>tc", ":VimuxCloseRunner<CR>", { desc = "tmux close runner" })
      vim.keymap.set("n", "<leader>ti", ":VimuxInspectRunner<CR>", { desc = "tmux inspect runner" })
      vim.keymap.set("n", "<leader>tx", ":VimuxInterruptRunner<CR>", { desc = "tmux interrupt runner" })
      vim.keymap.set("n", "<leader>tz", ":VimuxZoomRunner<CR>", { desc = "tmux zoom runner" })
    end,
  },

  {
    "tmux-plugins/vim-tmux-focus-events",
    lazy = false,
    config = function()
      vim.o.autoread = true

      -- Trigger autoread when files change on disk
      vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
        pattern = "*",
        command = "if mode() != 'c' | checktime | endif",
      })

      -- Notification after file change
      vim.api.nvim_create_autocmd("FileChangedShellPost", {
        pattern = "*",
        callback = function()
          vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN)
        end,
      })
    end,
  },
}
