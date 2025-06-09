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
      -- Handle conflicting mappings
      if vim.bo.filetype == "rust" then
        vim.notify("In Rust files, use <leader>rR for refactoring (to avoid conflict with RustRun)", vim.log.levels.INFO)
        return
      end

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

  -- Alternative mapping for Rust files to avoid conflict
  map(
    {"n", "x"},
    "<leader>rR",
    function()
      local telescope_refactoring_ok, _ = pcall(require, 'telescope._extensions.refactoring')
      if telescope_refactoring_ok then
        require('telescope').extensions.refactoring.refactors()
      else
        vim.notify("Telescope refactoring extension not loaded. Try :Telescope refactoring refactors", vim.log.levels.WARN)
        refactoring.select_refactor()
      end
    end,
    { desc = "Refactor operations (Telescope) - Rust safe" }
  )

  -- LSP rename with Telescope references preview
  map("n", "<leader>rn", function()
    -- First show references using Telescope, then perform rename
    local function show_references_and_rename()
      local params = vim.lsp.util.make_position_params()
      vim.lsp.buf_request(0, "textDocument/references", params, function(err, result, ctx, config)
        if err then
          vim.notify("Error getting references: " .. err.message, vim.log.levels.ERROR)
          return
        end

        if not result or vim.tbl_isempty(result) then
          vim.notify("No references found", vim.log.levels.INFO)
          vim.ui.input({ prompt = "New name: " }, function(new_name)
            if new_name and new_name ~= "" then
              vim.lsp.buf.rename(new_name)
              -- Format after rename operation
              vim.schedule(function()
                if _G.format_after_refactor then
                  _G.format_after_refactor(vim.api.nvim_get_current_buf())
                end
              end)
            end
          end)
          return
        end

        -- Use Telescope to show references before renaming
        require("telescope.builtin").lsp_references({
          prompt_title = "References (Press <CR> to rename)",
          attach_mappings = function(prompt_bufnr, map_func)
            map_func("i", "<CR>", function()
              require("telescope.actions").close(prompt_bufnr)
              vim.schedule(function()
                vim.ui.input({ prompt = "New name: " }, function(new_name)
                  if new_name and new_name ~= "" then
                    vim.lsp.buf.rename(new_name)
                    vim.schedule(function()
                      if _G.format_after_refactor then
                        _G.format_after_refactor(vim.api.nvim_get_current_buf())
                      end
                    end)
                  end
                end)
              end)
            end)
            map_func("n", "<CR>", function()
              require("telescope.actions").close(prompt_bufnr)
              vim.schedule(function()
                vim.ui.input({ prompt = "New name: " }, function(new_name)
                  if new_name and new_name ~= "" then
                    vim.lsp.buf.rename(new_name)
                    vim.schedule(function()
                      if _G.format_after_refactor then
                        _G.format_after_refactor(vim.api.nvim_get_current_buf())
                      end
                    end)
                  end
                end)
              end)
            end)
            return true
          end,
        })
      end)
    end

    show_references_and_rename()
  end, { desc = "LSP rename with references preview" })

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

  -- Extract function
  map(
    {"x"},
    "<leader>re",
    refactor_with_formatting('Extract Function'),
    { expr = true, desc = "Extract function" }
  )

  -- Extract function to file
  map(
    {"x"},
    "<leader>rf",
    refactor_with_formatting('Extract Function To File'),
    { expr = true, desc = "Extract function to file" }
  )

  -- Extract variable
  map(
    {"x"},
    "<leader>rv",
    refactor_with_formatting('Extract Variable'),
    { expr = true, desc = "Extract variable" }
  )

  -- Extract block
  map(
    {"n"},
    "<leader>rb",
    refactor_with_formatting('Extract Block'),
    { expr = true, desc = "Extract block" }
  )

  -- Extract block to file
  map(
    {"n"},
    "<leader>rbf",
    refactor_with_formatting('Extract Block To File'),
    { expr = true, desc = "Extract block to file" }
  )

  -- Inline function
  map(
    {"n"},
    "<leader>rI",
    refactor_with_formatting('Inline Function'),
    { expr = true, desc = "Inline function" }
  )

  -- Inline variable
  map(
    {"n", "x"},
    "<leader>ri",
    refactor_with_formatting('Inline Variable'),
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

  -- Quick access to LSP references and definitions with Telescope
  map("n", "<leader>rrf", function()
    require("telescope.builtin").lsp_references()
  end, { desc = "Show references (Telescope)" })

  -- Alternative non-conflicting mappings for LSP navigation
  map("n", "gr", function()
    require("telescope.builtin").lsp_references()
  end, { desc = "Show references (Telescope)" })

  map("n", "gd", function()
    require("telescope.builtin").lsp_definitions()
  end, { desc = "Show definitions (Telescope)" })

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
    -- Show references first, then rename
    local params = vim.lsp.util.make_position_params()
    vim.lsp.buf_request(0, "textDocument/references", params, function(err, result, ctx, config)
      if err then
        vim.notify("Error getting references: " .. err.message, vim.log.levels.ERROR)
        return
      end

      if not result or vim.tbl_isempty(result) then
        vim.notify("No references found", vim.log.levels.INFO)
        vim.ui.input({ prompt = "New name: " }, function(new_name)
          if new_name and new_name ~= "" then
            vim.lsp.buf.rename(new_name)
            vim.schedule(function()
              if _G.format_after_refactor then
                _G.format_after_refactor(vim.api.nvim_get_current_buf())
              end
            end)
          end
        end)
        return
      end

      require("telescope.builtin").lsp_references({
        prompt_title = "References (Press <CR> to rename)",
        attach_mappings = function(prompt_bufnr, map_func)
          map_func("i", "<CR>", function()
            require("telescope.actions").close(prompt_bufnr)
            vim.schedule(function()
              vim.ui.input({ prompt = "New name: " }, function(new_name)
                if new_name and new_name ~= "" then
                  vim.lsp.buf.rename(new_name)
                  vim.schedule(function()
                    if _G.format_after_refactor then
                      _G.format_after_refactor(vim.api.nvim_get_current_buf())
                    end
                  end)
                end
              end)
            end)
          end)
          map_func("n", "<CR>", function()
            require("telescope.actions").close(prompt_bufnr)
            vim.schedule(function()
              vim.ui.input({ prompt = "New name: " }, function(new_name)
                if new_name and new_name ~= "" then
                  vim.lsp.buf.rename(new_name)
                  vim.schedule(function()
                    if _G.format_after_refactor then
                      _G.format_after_refactor(vim.api.nvim_get_current_buf())
                    end
                  end)
                end
              end)
            end)
          end)
          return true
        end,
      })
    end)
  end, { desc = "Rename symbol with references preview" })

  vim.api.nvim_create_user_command("RefactorReferences", function()
    require("telescope.builtin").lsp_references()
  end, { desc = "Show references in Telescope" })
end

return M
