-- Harpoon mappings
local M = {}

M.setup = function()
  local harpoon = require("harpoon")
  local map = vim.keymap.set

  -- Harpoon mark and menu
  map("n", "<leader>md", function() harpoon:list():add() end, { desc = "harpoon add file" })
  map("n", "<leader>mr", function() harpoon:list():remove() end, { desc = "harpoon remove current file" })

  -- Set up autocmd to add keybindings to the Harpoon menu buffer
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "harpoon",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()

      -- Map keys for items 1-30 in the menu
      for i = 1, 30 do
        if i <= 9 then
          vim.keymap.set("n", tostring(i), function()
            harpoon:list():select(i)
          end, { buffer = buf, noremap = true, silent = true, desc = "Select item " .. i })

          vim.keymap.set("n", "<leader>m" .. i, function()
            vim.cmd("bdelete!")
            vim.defer_fn(function()
              local list = require("harpoon"):list()
              if i <= list:length() then
                list:remove_at(i)
                vim.notify("Removed Harpoon mark #" .. i, vim.log.levels.INFO)
                vim.defer_fn(function()
                  require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
                end, 100)
              else
                vim.notify("No Harpoon mark at index " .. i, vim.log.levels.WARN)
              end
            end, 50)
          end, { buffer = buf, noremap = true, silent = true, desc = "Remove item " .. i })
        elseif i >= 10 then
          -- Use leader prefix for numbers 10-30
          vim.keymap.set("n", "<leader>" .. i, function()
            harpoon:list():select(i)
          end, { buffer = buf, noremap = true, silent = true, desc = "Select item " .. i })

          -- Add removal mapping with leader leader m prefix
          vim.keymap.set("n", "<leader><leader>m" .. i, function()
            vim.cmd("bdelete!")
            vim.defer_fn(function()
              local list = require("harpoon"):list()
              if i <= list:length() then
                list:remove_at(i)
                vim.notify("Removed Harpoon mark #" .. i, vim.log.levels.INFO)
                vim.defer_fn(function()
                  require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
                end, 100)
              else
                vim.notify("No Harpoon mark at index " .. i, vim.log.levels.WARN)
              end
            end, 50)
          end, { buffer = buf, noremap = true, silent = true, desc = "Remove item " .. i })
        end
      end

      vim.api.nvim_echo({{
        "Harpoon: 1-9 or <leader>10-30 to select, <leader>m1-9 or <leader><leader>m10-30 to remove",
        "Comment"
      }}, false, {})
    end,
    once = false
  })

  -- Normal mode mappings
  for i = 1, 30 do
    if i <= 9 then
      map("n", "<leader>" .. i, function()
        harpoon:list():select(i)
      end, { desc = "harpoon to file " .. i })

      map("n", "<leader>m" .. i, function()
        local list = harpoon:list()
        if i <= list:length() then
          list:remove_at(i)
          vim.notify("Removed Harpoon mark #" .. i, vim.log.levels.INFO)
          if vim.bo.filetype == "harpoon" then
            vim.cmd("bdelete!")
            vim.defer_fn(function()
              require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
            end, 100)
          end
        else
          vim.notify("No Harpoon mark at index " .. i, vim.log.levels.WARN)
        end
      end, { desc = "harpoon remove item " .. i })
    elseif i >= 10 then
      map("n", "<leader><leader>" .. i, function()
        harpoon:list():select(i)
      end, { desc = "harpoon to file " .. i })

      map("n", "<leader><leader>m" .. i, function()
        local list = harpoon:list()
        if i <= list:length() then
          list:remove_at(i)
          vim.notify("Removed Harpoon mark #" .. i, vim.log.levels.INFO)
          if vim.bo.filetype == "harpoon" then
            vim.cmd("bdelete!")
            vim.defer_fn(function()
              require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
            end, 100)
          end
        else
          vim.notify("No Harpoon mark at index " .. i, vim.log.levels.WARN)
        end
      end, { desc = "harpoon remove item " .. i })
    end
  end

  -- Toggle menu
  map("n", "<leader>mf", function()
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end, { desc = "harpoon menu" })

  -- Toggle previous & next buffers stored within Harpoon list
  map("n", "<leader>mz", function() harpoon:list():prev() end, { desc = "harpoon prev file" })
  map("n", "<leader>mx", function() harpoon:list():next() end, { desc = "harpoon next file" })

  -- Clear list command
  map("n", "<leader>mc", function()
    harpoon:list():clear()
    vim.notify("Cleared Harpoon list", vim.log.levels.INFO)

    if vim.bo.filetype == "harpoon" then
      vim.cmd("bdelete!")
      vim.defer_fn(function()
        require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
      end, 100)
    end
  end, { desc = "harpoon clear list" })
end

return M
