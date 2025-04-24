-- Telescope mappings
local map = vim.keymap.set

local telescope = require("telescope")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<leader>a"] = function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          require("harpoon"):list():append({
            value = selection.path,
            row = selection.lnum and selection.lnum or 1,
            col = selection.col and selection.col or 1,
          })
          vim.notify("Added " .. vim.fs.basename(selection.path) .. ":" .. (selection.lnum or 1) .. " to Harpoon", vim.log.levels.INFO)
        end,
      },
    },
  },
  pickers = {
    live_grep = {
      mappings = {
        i = {
          ["<leader>a"] = function(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection and selection.path then
              require("harpoon"):list():append({
                value = selection.path,
                row = selection.lnum and selection.lnum or 1,
                col = selection.col and selection.col or 1,
                context = selection.text,
              })
              vim.notify("Added " .. vim.fs.basename(selection.path) .. ":" .. (selection.lnum or 1) .. " to Harpoon", vim.log.levels.INFO)
            end
          end,
        },
      },
    },
  },
})

map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })

map("n", "<leader>th", function()
  require("nvchad.themes").open()
end, { desc = "telescope nvchad themes" })

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "telescope find all files" }
)
