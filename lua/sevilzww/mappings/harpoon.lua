-- Harpoon mappings
local M = {}

local function jump_to_context(item)
  local context_text = ""
  if context_text and context_text ~= "" then
    local pattern = vim.fn.escape(vim.fn.trim(context_text), '\\[]^$.*/')
    local found = vim.fn.search(pattern, 'w')
    if found == 0 then
      pattern = vim.fn.escape(vim.fn.trim(context_text):gsub("%s+", ".*"), '\\[]^$.*/')
      found = vim.fn.search(pattern, 'w')
    end
    if found > 0 then
      vim.cmd('normal! zz') -- Center the buffer line to the screen
    else
      vim.api.nvim_win_set_cursor(0, {item.row or 1, item.col and (item.col - 1) or 0})
      vim.notify("Original context not found, jumped to stored line number.", vim.log.levels.WARN)
    end
  else
    vim.api.nvim_win_set_cursor(0, {item.row or 1, item.col and (item.col - 1) or 0})
  end
end

local function notify(msg, level)
  local timeout = 1000
  if level == vim.log.levels.ERROR then
    timeout = 5000
  elseif level == vim.log.levels.WARN then
    timeout = 3000
  end

  vim.notify(msg, level or vim.log.levels.INFO, {
    timeout = timeout,
  })
end

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
          vim.keymap.set( "n", tostring(i), function()
            local index = i

            local success, item_info = pcall(function()
              local harpoon = require("harpoon")
              local list = harpoon:list()

              if index <= list:length() then
                return {
                  exists = true,
                  row = list.items[index].row,
                  col = list.items[index].col,
                  context = list.items[index].context
                }
              else
                return { exists = false }
              end
            end)
            vim.cmd("bdelete!")

            vim.schedule(function()
              if success and item_info.exists then
                local nav_success, _ = pcall(function()
                  local harpoon = require("harpoon")
                  local list = harpoon:list()
                  list:select(index)
                end)

                if nav_success and item_info.row then
                  vim.schedule(function()
                    pcall(jump_to_context, item_info)
                  end)
                end
              else

                if not success then
                  vim.schedule(function()
                    local second_success, _ = pcall(function()
                      local harpoon = require("harpoon")
                      local list = harpoon:list()

                      if index <= list:length() then
                        list:select(index)

                        if list.items[index] and list.items[index].row then
                          vim.schedule(function()
                            jump_to_context({
                              row = list.items[index].row,
                              col = list.items[index].col,
                              context = list.items[index].context
                            })
                          end)
                        end
                      else
                        notify("No Harpoon item at index " .. index, vim.log.levels.WARN)
                      end
                    end)

                    if not second_success then
                      notify("Failed to navigate to Harpoon item " .. index, vim.log.levels.ERROR)
                    end
                  end)
                else
                  notify("No Harpoon item at index " .. index, vim.log.levels.WARN)
                end
              end
            end)
          end, { buffer = buf, noremap = true, silent = true, desc = "Select item " .. i })

          vim.keymap.set("n", "<leader>m" .. i, function()
            vim.cmd("bdelete!")
            vim.schedule(function()
              local list = require("harpoon"):list()
              if i <= list:length() then
                list:remove_at(i)
                vim.schedule(function()
                  require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
                  notify("Removed Harpoon mark #" .. i)
                end)
              else
                notify("No Harpoon mark at index " .. i, vim.log.levels.WARN)
              end
            end)
          end, { buffer = buf, noremap = true, silent = true, desc = "Remove item " .. i })
        elseif i >= 10 then
          -- Use leader prefix for numbers 10-30
          vim.keymap.set("n", "<leader>" .. i, function()
            harpoon:list():select(i)
          end, { buffer = buf, noremap = true, silent = true, desc = "Select item " .. i })

          -- Add removal mapping with leader leader m prefix
          vim.keymap.set("n", "<leader><leader>m" .. i, function()
            vim.cmd("bdelete!")
            vim.schedule(function()
              local list = require("harpoon"):list()
              if i <= list:length() then
                list:remove_at(i)
                vim.schedule(function()
                  require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
                  notify("Removed Harpoon mark #" .. i)
                end)
              else
                notify("No Harpoon mark at index " .. i, vim.log.levels.WARN)
              end
            end)
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
        vim.schedule(function()
          local success, result = pcall(function()
            local harpoon = require("harpoon")
            local list = harpoon:list()
            if list and list.items and i <= #list.items then
              local item = list.items[i]
              list:select(i)
              if item.row then
                vim.schedule(function()
                  jump_to_context(item)
                end)
              end
            else
              notify("No Harpoon item at index " .. i, vim.log.levels.WARN)
            end
          end)

          if not success then
            vim.schedule(function()
              local harpoon = require("harpoon")
              local list = harpoon:list()
              if list and list.items and i <= #list.items then
                local item = list.items[i]
                list:select(i)
                if item.row then
                  vim.schedule(function()
                    jump_to_context(item)
                  end)
                end
              else
                notify("No Harpoon mark at index " .. i, vim.log.levels.WARN)
              end
            end)
          end
        end)
      end, { desc = "harpoon to file " .. i })

      map("n", "<leader>m" .. i, function()
        local list = harpoon:list()
        if i <= list:length() then
          list:remove_at(i)
          notify("Removed Harpoon mark #" .. i)
          if vim.bo.filetype == "harpoon" then
            vim.cmd("bdelete!")
            vim.schedule(function()
              require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
            end)
          end
        else
          notify("No Harpoon mark at index " .. i, vim.log.levels.WARN)
        end
      end, { desc = "harpoon remove item " .. i })
    elseif i >= 10 then
      map("n", "<leader><leader>" .. i, function()
        vim.schedule(function()
          local success, result = pcall(function()
            local harpoon = require("harpoon")
            local list = harpoon:list()
            if list and list.items and i <= #list.items then
              list:select(i)
            else
              notify("No Harpoon item at index " .. i, vim.log.levels.WARN)
            end
          end)

          if not success then
            vim.schedule(function()
              local harpoon = require("harpoon")
              local list = harpoon:list()
              if list and list.items and i <= #list.items then
                list:select(i)
              else
                notify("No Harpoon item at index " .. i, vim.log.levels.WARN)
              end
            end)
          end
        end)
      end, { desc = "harpoon to file " .. i })

      map("n", "<leader><leader>m" .. i, function()
        local list = harpoon:list()
        if i <= list:length() then
          list:remove_at(i)
          notify("Removed Harpoon mark #" .. i)
          if vim.bo.filetype == "harpoon" then
            vim.cmd("bdelete!")
            vim.schedule(function()
              require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
            end)
          end
        else
          notify("No Harpoon mark at index " .. i, vim.log.levels.WARN)
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
    local harpoon = require("harpoon")
    local was_menu_open = vim.bo.filetype == "harpoon"

    if was_menu_open then
      vim.cmd("bdelete!")
    end

    harpoon:list():clear()
    if was_menu_open then
      vim.schedule(function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
        notify("Cleared Harpoon list")
      end)
    else
      notify("Cleared Harpoon list")
    end
  end, { desc = "harpoon clear list" })

  map("n", "<leader>ml", function()
    vim.cmd("HarpoonReload")
  end, { desc = "harpoon reload from file" })

  map("n", "<leader>ms", function()
    vim.cmd("HarpoonSave")
  end, { desc = "harpoon save to file" })
end

return M
