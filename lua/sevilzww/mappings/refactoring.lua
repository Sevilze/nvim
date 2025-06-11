local M = {}

function M.setup()
  local map = vim.keymap.set

  local ok, refactoring = pcall(require, "refactoring")
  if not ok then
    vim.notify("refactoring.nvim plugin not found", vim.log.levels.WARN)
    return
  end

  local telescope_ok, telescope = pcall(require, "telescope")
  if not telescope_ok then
    vim.notify("telescope.nvim plugin not found", vim.log.levels.WARN)
    return
  end

  map(
    {"n", "x"},
    "<leader>rr",
    function()
      local telescope_refactoring_ok, _ = pcall(require, 'telescope._extensions.refactoring')
      if telescope_refactoring_ok then
        require('telescope').extensions.refactoring.refactors()
      else
        vim.notify("Telescope refactoring extension not loaded. Try :Telescope refactoring refactors", vim.log.levels.WARN)
        refactoring.select_refactor()
      end
    end,
    { desc = "Refactor operations (Telescope)" }
  )

  -- LSP rename with symbol pre-population
  map("n", "<leader>rn", function()
    -- Get the current word under cursor
    local current_word = vim.fn.expand("<cword>")
    if current_word == "" then
      vim.notify("No symbol under cursor", vim.log.levels.WARN)
      return
    end

    local function get_symbol_under_cursor()
      local word1 = vim.fn.expand("<cword>")
      if word1 ~= "" then return word1 end
      return ""
    end

    local symbol = get_symbol_under_cursor()
    if symbol == "" then
      vim.notify("No symbol found under cursor", vim.log.levels.WARN)
      return
    end

    vim.ui.input({
      prompt = "New name: ",
      default = symbol,
      completion = nil,
    }, function(new_name)
      if new_name and new_name ~= "" and new_name ~= symbol then
        vim.lsp.buf.rename(new_name)
        -- Format after rename operation
        vim.schedule(function()
          if _G.format_after_refactor then
            _G.format_after_refactor(vim.api.nvim_get_current_buf())
          end
        end)
      end
    end)
  end, { desc = "LSP rename with symbol pre-population" })

  -- Helper function to format after refactoring
  local function refactor_with_formatting(operation)
    return function()
      local result = refactoring.refactor(operation)
      -- Schedule formatting after refactoring operation completes
      vim.schedule(function()
        if _G.format_after_refactor then
          _G.format_after_refactor(vim.api.nvim_get_current_buf())
        end
      end)
      return result
    end
  end

  -- Extract function (visual mode only)
  map(
    "x",
    "<leader>re",
    function() return refactoring.refactor('Extract Function') end,
    { expr = true, desc = "Extract function" }
  )

  -- Extract function to file (visual mode only)
  map(
    "x",
    "<leader>rf",
    function() return refactoring.refactor('Extract Function To File') end,
    { expr = true, desc = "Extract function to file" }
  )

  -- Extract variable (visual mode only)
  map(
    "x",
    "<leader>rv",
    function() return refactoring.refactor('Extract Variable') end,
    { expr = true, desc = "Extract variable" }
  )

  -- Extract block (normal mode only)
  map(
    "n",
    "<leader>rb",
    function() return refactoring.refactor('Extract Block') end,
    { expr = true, desc = "Extract block" }
  )

  -- Extract block to file (normal mode only)
  map(
    "n",
    "<leader>rbf",
    function() return refactoring.refactor('Extract Block To File') end,
    { expr = true, desc = "Extract block to file" }
  )

  -- Inline function (normal mode only)
  map(
    "n",
    "<leader>rI",
    function() return refactoring.refactor('Inline Function') end,
    { expr = true, desc = "Inline function" }
  )

  -- Inline variable (both normal and visual mode)
  map(
    {"n", "x"},
    "<leader>ri",
    function() return refactoring.refactor('Inline Variable') end,
    { expr = true, desc = "Inline variable" }
  )

  -- Debug operations
  map(
    "n",
    "<leader>rp",
    function()
      refactoring.debug.printf({below = false})
    end,
    { desc = "Debug printf" }
  )

  map(
    {"x", "n"},
    "<leader>rpv",
    function()
      refactoring.debug.print_var()
    end,
    { desc = "Debug print variable" }
  )

  map(
    "n",
    "<leader>rc",
    function()
      refactoring.debug.cleanup({})
    end,
    { desc = "Debug cleanup" }
  )

  -- Alternative mappings using Ex commands for preview functionality
  map("x", "<leader>ree", ":Refactor extract ", { desc = "Extract (with preview)" })
  map("x", "<leader>rff", ":Refactor extract_to_file ", { desc = "Extract to file (with preview)" })
  map("x", "<leader>rvv", ":Refactor extract_var ", { desc = "Extract variable (with preview)" })
  map({"n", "x"}, "<leader>rii", ":Refactor inline_var", { desc = "Inline variable (with preview)" })
  map("n", "<leader>rII", ":Refactor inline_func", { desc = "Inline function (with preview)" })
  map("n", "<leader>rbb", ":Refactor extract_block", { desc = "Extract block (with preview)" })
  map("n", "<leader>rbbf", ":Refactor extract_block_to_file", { desc = "Extract block to file (with preview)" })

  -- Alternative non-conflicting mappings for LSP navigation
  map("n", "<leader>rD", function()
    require("telescope.builtin").lsp_definitions()
  end, { desc = "Show definitions (Telescope)" })

  map("n", "<leader>rS", function()
    require("telescope.builtin").lsp_document_symbols()
  end, { desc = "Show document symbols (Telescope)" })

  map("n", "<leader>rW", function()
    require("telescope.builtin").lsp_dynamic_workspace_symbols()
  end, { desc = "Show workspace symbols (Telescope)" })

  -- Create user commands
  vim.api.nvim_create_user_command("RefactorTelescope", function()
    local telescope_refactoring_ok, _ = pcall(require, 'telescope._extensions.refactoring')
    if telescope_refactoring_ok then
      require('telescope').extensions.refactoring.refactors()
    else
      vim.notify("Telescope refactoring extension not loaded. Using built-in selection.", vim.log.levels.WARN)
      refactoring.select_refactor()
    end
  end, { desc = "Open refactoring operations in Telescope" })

  vim.api.nvim_create_user_command("RefactorRename", function()
    local function get_symbol_under_cursor()
      local symbol = vim.fn.expand("<cword>")
      if symbol ~= "" then return symbol end

      return ""
    end

    local symbol = get_symbol_under_cursor()
    if symbol == "" then
      vim.notify("No symbol found under cursor", vim.log.levels.WARN)
      return
    end

    -- Use vim.ui.input with the current word as default
    vim.ui.input({
      prompt = "New name: ",
      default = symbol
    }, function(new_name)
      if new_name and new_name ~= "" and new_name ~= symbol then
        vim.lsp.buf.rename(new_name)
        vim.schedule(function()
          if _G.format_after_refactor then
            _G.format_after_refactor(vim.api.nvim_get_current_buf())
          end
        end)
      end
    end)
  end, { desc = "Rename symbol with symbol pre-population" })
end

return M
