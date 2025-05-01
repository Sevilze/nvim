local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>gdo", "<cmd>DiffviewOpen<CR>", { desc = "Open Diffview" })
  vim.keymap.set("n", "<leader>gdh", "<cmd>DiffviewFileHistory %<CR>", { desc = "Open file history" })
  vim.keymap.set("n", "<leader>gdH", "<cmd>DiffviewFileHistory<CR>", { desc = "Open repo history" })
  vim.keymap.set("n", "<leader>gdf", "<cmd>DiffviewToggleFiles<CR>", { desc = "Toggle the file panel" })
  vim.keymap.set("n", "<leader>gdc", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" })
  
  vim.notify("Diffview mappings loaded", vim.log.levels.INFO)
end

function M.get_keymaps()
  return {
    disable_defaults = false,
    view = {
      { "n", "<tab>", "<cmd>DiffviewToggleFiles<CR>", { desc = "Toggle the file panel" } },
      { "n", "<leader>gdf", "<cmd>DiffviewToggleFiles<CR>", { desc = "Toggle the file panel" } },
      { "n", "<leader>gdc", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" } },
    },
    file_panel = {
      { "n", "<cr>", "<cmd>lua require('diffview.actions').select_entry()<CR>", { desc = "Open the diff for the selected entry" } },
      { "n", "s", "<cmd>lua require('diffview.actions').toggle_stage_entry()<CR>", { desc = "Stage / unstage the selected entry" } },
      { "n", "cc", "<cmd>lua require('diffview.actions').conflict_choose('ours')<CR>", { desc = "Choose the OURS version of a conflict" } },
      { "n", "ct", "<cmd>lua require('diffview.actions').conflict_choose('theirs')<CR>", { desc = "Choose the THEIRS version of a conflict" } },
      { "n", "cb", "<cmd>lua require('diffview.actions').conflict_choose('base')<CR>", { desc = "Choose the BASE version of a conflict" } },
      { "n", "ca", "<cmd>lua require('diffview.actions').conflict_choose('all')<CR>", { desc = "Choose all the versions of a conflict" } },
      { "n", "cA", "<cmd>lua require('diffview.actions').conflict_choose('all-next')<CR>", { desc = "Choose all the versions of a conflict and move to the next unresolved conflict" } },
    },
    file_history_panel = {
      { "n", "<cr>", "<cmd>lua require('diffview.actions').select_entry()<CR>", { desc = "Open the diff for the selected entry" } },
      { "n", "L", "<cmd>lua require('diffview.actions').open_commit_log()<CR>", { desc = "Show commit details" } },
    },
  }
end

return M
