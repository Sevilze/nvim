-- Harpoon mappings
local M = {}

local function jump_to_context(item)
  local context_text = ""
  if context_text and context_text ~= "" then
    local pattern = vim.fn.escape(vim.fn.trim(context_text), "\\[]^$.*/")
    local found = vim.fn.search(pattern, "w")
    if found == 0 then
      pattern = vim.fn.escape(vim.fn.trim(context_text):gsub("%s+", ".*"), "\\[]^$.*/")
      found = vim.fn.search(pattern, "w")
    end
    if found > 0 then
      vim.cmd "normal! zz" -- Center the buffer line to the screen
    else
      vim.api.nvim_win_set_cursor(0, { item.row or 1, item.col and (item.col - 1) or 0 })
      vim.notify("Original context not found, jumped to stored line number.", vim.log.levels.WARN)
    end
  else
    vim.api.nvim_win_set_cursor(0, { item.row or 1, item.col and (item.col - 1) or 0 })
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
  local harpoon = require "harpoon"
  local harpoon_float = require "sevilzww.utils.harpoon_float"
  local map = vim.keymap.set

  -- Harpoon mark and menu
  map("n", "<leader>md", function()
    harpoon:list():add()
    if harpoon_float.is_visible() then
      harpoon_float.refresh()
    end
  end, { desc = "harpoon add file" })

  map("n", "<leader>mr", function()
    harpoon:list():remove()
    if harpoon_float.is_visible() then
      harpoon_float.refresh()
    end
  end, { desc = "harpoon remove current file" })

  -- Safe select function for Harpoon menu
  local function safe_select_item(index)
    local success, err = pcall(function()
      local harpoon = require "harpoon"
      local list = harpoon:list()

      -- Validate list exists and has items
      if not list then
        error "Harpoon list is nil"
      end

      if not list.items then
        error "Harpoon list.items is nil"
      end

      if index > #list.items then
        error("Index " .. index .. " exceeds list length " .. #list.items)
      end

      if index < 1 then
        error("Index " .. index .. " is less than 1")
      end

      local item = list.items[index]
      if not item then
        error("Item at index " .. index .. " is nil")
      end

      if not item.value then
        error("Item value at index " .. index .. " is nil")
      end

      list:select(index)
      return item
    end)

    if not success then
      notify("Failed to select Harpoon item " .. index .. ": " .. tostring(err), vim.log.levels.ERROR)
      return nil
    end

    return err -- This is actually the item when success is true
  end

  -- Set up autocmd to add keybindings to the Harpoon menu buffer
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "harpoon",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()

      -- Override Enter key to use safe selection
      vim.keymap.set("n", "<CR>", function()
        local line = vim.api.nvim_win_get_cursor(0)[1]
        vim.cmd "bdelete!"

        vim.schedule(function()
          local item = safe_select_item(line)
          if item and item.context and item.context.row then
            vim.schedule(function()
              pcall(jump_to_context, item.context)
            end)
          end
        end)
      end, { buffer = buf, noremap = true, silent = true, desc = "Select Harpoon item" })

      -- Map keys for items 1-30 in the menu
      for i = 1, 30 do
        if i <= 9 then
          vim.keymap.set("n", tostring(i), function()
            vim.cmd "bdelete!"

            vim.schedule(function()
              local item = safe_select_item(i)
              if item and item.context and item.context.row then
                vim.schedule(function()
                  pcall(jump_to_context, item.context)
                end)
              end
            end)
          end, { buffer = buf, noremap = true, silent = true, desc = "Select item " .. i })

          vim.keymap.set("n", "<leader>m" .. i, function()
            vim.cmd "bdelete!"
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
            vim.cmd "bdelete!"

            vim.schedule(function()
              local item = safe_select_item(i)
              if item and item.context and item.context.row then
                vim.schedule(function()
                  pcall(jump_to_context, item.context)
                end)
              end
            end)
          end, { buffer = buf, noremap = true, silent = true, desc = "Select item " .. i })

          -- Add removal mapping with leader leader m prefix
          vim.keymap.set("n", "<leader><leader>m" .. i, function()
            vim.cmd "bdelete!"
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
    end,
    once = false,
  })

  -- Normal mode mappings
  for i = 1, 30 do
    if i <= 9 then
      map("n", "<leader>" .. i, function()
        vim.schedule(function()
          local item = safe_select_item(i)
          if item and item.context and item.context.row then
            vim.schedule(function()
              pcall(jump_to_context, item.context)
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
            vim.cmd "bdelete!"
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
          local item = safe_select_item(i)
          if item and item.context and item.context.row then
            vim.schedule(function()
              pcall(jump_to_context, item.context)
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
            vim.cmd "bdelete!"
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

  map("n", "<leader>mf", function()
    local success, err = pcall(function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end)

    if not success then
      notify("Failed to open Harpoon menu: " .. tostring(err), vim.log.levels.ERROR)
    end
  end, { desc = "harpoon menu" })

  -- Toggle floating Harpoon window
  map("n", "<leader>mw", function()
    harpoon_float.toggle()
  end, { desc = "harpoon floating window" })

  -- Toggle previous & next buffers stored within Harpoon list
  map("n", "<leader>mz", function()
    harpoon:list():prev()
  end, { desc = "harpoon prev file" })
  map("n", "<leader>mx", function()
    harpoon:list():next()
  end, { desc = "harpoon next file" })

  -- Clear list command
  map("n", "<leader>mc", function()
    local harpoon = require "harpoon"
    local was_menu_open = vim.bo.filetype == "harpoon"

    if was_menu_open then
      vim.cmd "bdelete!"
    end

    harpoon:list():clear()

    -- Refresh floating window if visible
    if harpoon_float.is_visible() then
      harpoon_float.refresh()
    end

    if was_menu_open then
      vim.schedule(function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
        notify "Cleared Harpoon list"
      end)
    else
      notify "Cleared Harpoon list"
    end
  end, { desc = "harpoon clear list" })

  map("n", "<leader>ml", function()
    vim.cmd "HarpoonReload"
  end, { desc = "harpoon reload from file" })

  map("n", "<leader>ms", function()
    vim.cmd "HarpoonSave"
  end, { desc = "harpoon save to file" })

  map("n", "<leader>mg", function()
    vim.cmd "HarpoonGitFiles"
  end, { desc = "harpoon add git changed files" })

  -- Setup enhanced floating window with current buffer highlighting
  harpoon_float.setup()
end

return M
