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

      -- State tracking for focus event safety
      local focus_state = {
        last_focus_time = 0,
        focus_debounce_ms = 100,
        pending_checktime = false,
        autosave_in_progress = false,
      }

      -- Safe checktime function with validation
      local function safe_checktime()
        -- Don't run checktime if we're in certain modes or states
        local current_mode = vim.fn.mode()
        if current_mode == 'c' or current_mode == 'i' or current_mode == 'R' then
          return
        end

        -- Don't run checktime if autosave is in progress
        if vim.g._autosave_in_progress or focus_state.autosave_in_progress then
          return
        end

        -- Don't run checktime if file deletion blocking is active and we're in a dangerous state
        if vim.g.file_deletion_blocked then
          local current_buf = vim.api.nvim_get_current_buf()
          if not vim.api.nvim_buf_is_valid(current_buf) then
            return
          end

          local buf_name = vim.api.nvim_buf_get_name(current_buf)
          if buf_name == "" then
            return
          end

          -- Check if buffer has unsaved changes
          if vim.bo[current_buf].modified then
            -- Don't run checktime on modified buffers to prevent data loss
            return
          end
        end

        -- Validate buffer state before running checktime
        local current_buf = vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(current_buf) then
          return
        end

        local buf_name = vim.api.nvim_buf_get_name(current_buf)
        if buf_name ~= "" then
          -- Check if the file still exists before running checktime
          local file_exists = vim.fn.filereadable(buf_name) == 1
          if file_exists then
            -- Only run checktime if the file exists and buffer is in a safe state
            pcall(vim.cmd.checktime)
          else
            vim.notify("Skipped checktime for missing file: " .. vim.fs.basename(buf_name), vim.log.levels.DEBUG)
          end
        end
      end

      -- Debounced focus event handler
      local function handle_focus_gained()
        local now = vim.loop.now()

        -- Debounce rapid focus events
        if now - focus_state.last_focus_time < focus_state.focus_debounce_ms then
          return
        end

        focus_state.last_focus_time = now

        -- Schedule safe checktime to avoid race conditions
        if not focus_state.pending_checktime then
          focus_state.pending_checktime = true
          vim.schedule(function()
            safe_checktime()
            focus_state.pending_checktime = false
          end)
        end
      end

      vim.api.nvim_create_autocmd("FocusGained", {
        pattern = "*",
        callback = handle_focus_gained,
        desc = "Safe focus gained handler with file validation"
      })

      -- Safer BufEnter handling
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          -- Only run checktime on BufEnter if we're not in a focus transition
          local now = vim.loop.now()
          if now - focus_state.last_focus_time > 200 then
            vim.schedule(function()
              safe_checktime()
            end)
          end
        end,
        desc = "Safe BufEnter handler"
      })

      -- Track autosave state to prevent conflicts
      vim.api.nvim_create_autocmd("User", {
        pattern = "AutoSaveWritePre",
        callback = function()
          focus_state.autosave_in_progress = true
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "AutoSaveWritePost",
        callback = function()
          vim.schedule(function()
            focus_state.autosave_in_progress = false
          end)
        end,
      })

      vim.api.nvim_create_autocmd("FileChangedShellPost", {
        pattern = "*",
        callback = function(args)
          local buf = args.buf
          if buf and vim.api.nvim_buf_is_valid(buf) then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name ~= "" then
              vim.notify("File changed on disk: " .. vim.fs.basename(buf_name), vim.log.levels.WARN)
            end
          end
        end,
      })

      vim.api.nvim_create_autocmd("FocusLost", {
        pattern = "*",
        callback = function()
          focus_state.pending_checktime = false
        end,
        desc = "Focus lost cleanup"
      })
    end,
  },
}
