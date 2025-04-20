-- Tmux integration plugins
return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    config = function()
      vim.g.tmux_navigator_no_mappings = 1
      vim.keymap.set("n", "<C-h>", ":<C-U>TmuxNavigateLeft<CR>", { silent = true })
      vim.keymap.set("n", "<C-j>", ":<C-U>TmuxNavigateDown<CR>", { silent = true })
      vim.keymap.set("n", "<C-k>", ":<C-U>TmuxNavigateUp<CR>", { silent = true })
      vim.keymap.set("n", "<C-l>", ":<C-U>TmuxNavigateRight<CR>", { silent = true })
      vim.keymap.set("n", "<C-\\>", ":<C-U>TmuxNavigatePrevious<CR>", { silent = true })
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
