-- Set filetype to markdown for better handling, but don't convert the file
vim.bo.filetype = "markdown"

-- Ensure jupytext doesn't try to convert this file
vim.b.jupytext_disable = true

-- Activate quarto for LSP features
local quarto_ok, quarto = pcall(require, "quarto")
if quarto_ok then
  quarto.activate()
else
  vim.notify("Quarto plugin not found. Some features may not work properly.", vim.log.levels.WARN)
end

-- Set up Python LSP for code blocks
local otter_ok, otter = pcall(require, "otter")
if otter_ok then
  -- Ensure otter attaches to this buffer
  otter.activate({
    bufnr = vim.api.nvim_get_current_buf(),
    ft = "python"
  })

  -- Force enable diagnostics for this buffer
  vim.diagnostic.enable(vim.api.nvim_get_current_buf())
else
  vim.notify("Otter plugin not found. LSP features in code blocks may not work properly.", vim.log.levels.WARN)
end

-- Initialize Molten if not already initialized
local molten_status_ok, molten_status = pcall(require, "molten.status")
if molten_status_ok then
  -- Try to initialize with python3 kernel
  vim.defer_fn(function()
    -- Check if we're still in the same buffer
    if vim.api.nvim_get_current_buf() == vim.api.nvim_get_current_buf() then
      -- Force initialization regardless of current status
      vim.cmd("MoltenInit python3")

      -- Import outputs after a short delay to ensure kernel is ready
      vim.defer_fn(function()
        if require("molten.status").initialized() == "Molten" then
          vim.cmd("MoltenImportOutput")
        end
      end, 1000)
    end
  end, 100)  -- Short delay to ensure buffer is fully loaded
end

-- Set up local options for better notebook editing
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.conceallevel = 0  -- Don't conceal markdown syntax

-- Set up autocommands for this buffer
local augroup = vim.api.nvim_create_augroup("IPYNBSettings", { clear = true })

-- Auto-initialize and import outputs when entering notebook buffer
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup,
  buffer = vim.api.nvim_get_current_buf(),
  callback = function()
    -- Check if Molten is initialized
    local molten_status_ok, molten_status = pcall(require, "molten.status")
    if molten_status_ok then
      if molten_status.initialized() ~= "Molten" then
        -- Initialize Molten if not already initialized
        vim.cmd("MoltenInit python3")

        -- Import outputs after a short delay to ensure kernel is ready
        vim.defer_fn(function()
          if require("molten.status").initialized() == "Molten" then
            vim.cmd("MoltenImportOutput")
          end
        end, 500)
      else
        -- If already initialized, just import outputs
        vim.cmd("MoltenImportOutput")
      end
    end
  end,
  once = false,  -- Run every time we enter the buffer
})

-- Auto-export outputs when saving notebook
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  buffer = vim.api.nvim_get_current_buf(),
  callback = function()
    -- Try to export outputs if molten is initialized
    if require("molten.status").initialized() == "Molten" then
      vim.cmd("MoltenExportOutput!")
    end
  end,
})

-- Display a helpful message
vim.defer_fn(function()
  vim.notify("Jupyter notebook mode activated. Use <leader>jh for help.", vim.log.levels.INFO)
end, 1000)
