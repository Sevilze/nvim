local M = {}

function M.setup()
  local map = vim.keymap.set

  -- Setup Quarto runner mappings (prioritized for notebook experience)
  pcall(function()
    local runner = require("quarto.runner")

    -- Primary notebook execution commands (Quarto)
    map("n", "<leader>qc", runner.run_cell, { desc = "Run current cell", silent = true })
    map("n", "<leader>qa", runner.run_above, { desc = "Run cell and above", silent = true })
    map("n", "<leader>qA", runner.run_all, { desc = "Run all cells", silent = true })
    map("n", "<leader>ql", runner.run_line, { desc = "Run line", silent = true })
    map("v", "<leader>q", runner.run_range, { desc = "Run visual selection", silent = true })
    map("n", "<leader>qL", function()
      runner.run_all(true)
    end, { desc = "Run all cells of all languages", silent = true })

    -- Shorter aliases for common operations
    map("n", "<leader>e", runner.run_cell, { desc = "Run cell (alias)", silent = true })
    map("v", "<leader>e", runner.run_range, { desc = "Run selection (alias)", silent = true })
    map("n", "<leader>E", runner.run_all, { desc = "Run all cells (alias)", silent = true })
  end)

  -- Basic Molten commands (as fallback and for advanced features)
  map("n", "<leader>mi", ":MoltenInit<CR>", { desc = "Initialize Molten kernel", silent = true })
  map("n", "<leader>me", ":<C-u>MoltenEvaluateOperator<CR>", { desc = "Evaluate operator", silent = true })
  map("v", "<leader>me", ":<C-u>MoltenEvaluateVisual<CR>gv", { desc = "Evaluate visual selection", silent = true })
  map("n", "<leader>mr", ":MoltenReevaluateCell<CR>", { desc = "Re-evaluate cell", silent = true })
  map("n", "<leader>md", ":MoltenDelete<CR>", { desc = "Delete cell", silent = true })
  map("n", "<leader>mh", ":MoltenHideOutput<CR>", { desc = "Hide output", silent = true })
  map("n", "<leader>ms", ":noautocmd MoltenEnterOutput<CR>", { desc = "Enter output window", silent = true })
  map("n", "<leader>mo", ":MoltenOpenInBrowser<CR>", { desc = "Open in browser", silent = true })
  map("n", "<leader>mv", ":MoltenImportOutput<CR>", { desc = "Import output as cell", silent = true })

  -- Additional Molten commands
  map("n", "<leader>mA", ":MoltenEvaluateAll<CR>", { silent = true, desc = "Run all cells" })
  map("n", "<leader>mc", ":MoltenReevaluateCell<CR>", { silent = true, desc = "Rerun current cell" })
  map("n", "<leader>mx", ":MoltenInterrupt<CR>", { silent = true, desc = "Interrupt kernel" })
  map("n", "<leader>mk", ":MoltenRestart<CR>", { silent = true, desc = "Restart kernel" })

  -- Direct Molten commands that don't rely on quarto.runner
  -- These are useful as fallbacks when quarto.runner isn't working
  map("n", "<leader>ml", function()
    -- Check if Molten is initialized
    if require("molten.status").initialized() == "Molten" then
      -- Get the current line
      local current_line_num = vim.fn.line(".")
      local current_line = vim.fn.getline(current_line_num)

      -- Check if we're in a Jupytext header section
      local in_jupytext_header = false
      if current_line_num <= 20 then  -- Only check near the beginning of the file
        -- Check if the current line or lines above match Jupytext header patterns
        for i = 1, math.min(current_line_num, 15) do
          local line = vim.fn.getline(i)
          if line:match("^jupyter:") or line:match("^  jupytext:") or
             line:match("^    text_representation:") or line:match("^  kernelspec:") then
            in_jupytext_header = true
            break
          end
        end
      end

      -- If we're in a Jupytext header, find the first code line instead
      if in_jupytext_header then
        vim.notify("Cannot execute Jupytext header. Try running a code cell instead.", vim.log.levels.WARN)
        return
      end

      -- Check if the current line is inside a Python code block
      local in_code_block = false
      local line_to_run = current_line_num

      -- Search backward for the start of a code block
      for i = current_line_num, 1, -1 do
        local line = vim.fn.getline(i)
        if line:match("^```%s*$") then
          -- Found end marker before start marker - not in a code block
          break
        end
        if line:match("^```%s*{?python") or line:match("^```%s*python") then
          in_code_block = true
          break
        end
      end

      -- Only execute if we're in a code block or the line looks like Python code
      if in_code_block or
         (current_line:match("^%s*import%s+") or
          current_line:match("^%s*from%s+%S+%s+import") or
          current_line:match("^%s*def%s+") or
          current_line:match("^%s*class%s+") or
          current_line:match("^%s*for%s+") or
          current_line:match("^%s*if%s+") or
          current_line:match("^%s*print%s*%(") or
          current_line:match("^%s*return%s+") or
          current_line:match("=%s*")) then
        -- Get the text from the line
        local line_text = vim.fn.getline(line_to_run)

        -- Use MoltenEvaluateOperator with visual selection or vim.fn.MoltenEvaluateText
        if vim.fn.exists("*MoltenEvaluateText") == 1 then
          vim.fn.MoltenEvaluateText(line_text)
        else
          -- Alternative approach: use MoltenEvaluateOperator
          vim.api.nvim_win_set_cursor(0, {line_to_run, 0})
          vim.cmd("normal! 0v$")
          vim.cmd("MoltenEvaluateOperator")
        end
      else
        vim.notify("Current line doesn't appear to be Python code. Try running a code cell instead.", vim.log.levels.WARN)
      end
    else
      vim.notify("Molten is not initialized. Run :MoltenInit first.", vim.log.levels.WARN)
    end
  end, { desc = "Run current line (direct)", silent = true })

  map("n", "<leader>ma", function()
    -- Check if Molten is initialized
    if require("molten.status").initialized() == "Molten" then
      -- Find the current code cell
      local start_line = vim.fn.line(".")
      local end_line = vim.fn.line(".")
      local current_line = vim.fn.getline(start_line)

      -- Check if we're in a Jupytext header section
      local in_jupytext_header = false
      if start_line <= 20 then  -- Only check near the beginning of the file
        -- Check if the current line or lines above match Jupytext header patterns
        for i = 1, math.min(start_line, 15) do
          local line = vim.fn.getline(i)
          if line:match("^jupyter:") or line:match("^  jupytext:") or
             line:match("^    text_representation:") or line:match("^  kernelspec:") then
            in_jupytext_header = true
            break
          end
        end
      end

      -- If we're in a Jupytext header, find the first code cell instead
      if in_jupytext_header then
        -- Find the end of the Jupytext header (marked by ---)
        local header_end = 0
        for i = 1, 30 do  -- Check the first 30 lines
          local line = vim.fn.getline(i)
          if i > 1 and line:match("^%-%-%-") then
            header_end = i
            break
          end
        end

        -- Find the first code cell after the header
        if header_end > 0 then
          for i = header_end + 1, vim.fn.line("$") do
            local line = vim.fn.getline(i)
            if line:match("^```%s*{?python") or line:match("^```%s*python") then
              start_line = i
              break
            end
          end
        end
      else
        -- Normal case: Search backward for the start of the cell (```python)
        while start_line > 1 do
          local line = vim.fn.getline(start_line)
          if line:match("^```%s*{?python") or line:match("^```%s*python") then
            break
          end
          start_line = start_line - 1
        end
      end

      -- Search forward for the end of the cell (```)
      while end_line < vim.fn.line("$") do
        local line = vim.fn.getline(end_line)
        if line:match("^```%s*$") then
          end_line = end_line - 1  -- Don't include the closing ```
          break
        end
        end_line = end_line + 1
      end

      -- Skip the opening ```python line
      start_line = start_line + 1

      -- Evaluate the range if we found a valid cell
      if start_line <= end_line then
        -- Get the text from the cell range
        local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
        local code = table.concat(lines, "\n")

        -- Use MoltenEvaluateOperator with visual selection or vim.fn.MoltenEvaluateText
        if vim.fn.exists("*MoltenEvaluateText") == 1 then
          vim.fn.MoltenEvaluateText(code)
        else
          -- Alternative approach: set marks and use MoltenEvaluateOperator
          vim.api.nvim_win_set_cursor(0, {start_line, 0})
          vim.cmd("normal! m[")
          vim.api.nvim_win_set_cursor(0, {end_line, 0})
          vim.cmd("normal! m]")
          vim.cmd("MoltenEvaluateOperator")
          vim.cmd("normal! `[v`]")
        end
      else
        vim.notify("No valid Python code cell found.", vim.log.levels.WARN)
      end
    else
      vim.notify("Molten is not initialized. Run :MoltenInit first.", vim.log.levels.WARN)
    end
  end, { desc = "Run current cell (direct)", silent = true })

  -- Create a mapping to add a new code cell above or below
  map("n", "<leader>ca", function()
    local line = vim.fn.line(".")
    -- Use a more explicit Python code block marker for better detection
    vim.api.nvim_buf_set_lines(0, line-1, line-1, false, {"```python", "", "```"})
    vim.api.nvim_win_set_cursor(0, {line+1, 0})
    vim.cmd("startinsert")

    -- Force refresh quarto runner to detect the new cell
    pcall(function()
      local quarto = require("quarto")
      if quarto then
        quarto.activate()
      end
    end)
  end, { desc = "Add code cell above", silent = true })

  map("n", "<leader>cb", function()
    local line = vim.fn.line(".")
    -- Use a more explicit Python code block marker for better detection
    vim.api.nvim_buf_set_lines(0, line, line, false, {"```python", "", "```"})
    vim.api.nvim_win_set_cursor(0, {line+2, 0})
    vim.cmd("startinsert")

    -- Force refresh quarto runner to detect the new cell
    pcall(function()
      local quarto = require("quarto")
      if quarto then
        quarto.activate()
      end
    end)
  end, { desc = "Add code cell below", silent = true })

  -- Create a mapping to add a new markdown cell above or below
  map("n", "<leader>mda", function()
    local line = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(0, line-1, line-1, false, {"", ""})
    vim.api.nvim_win_set_cursor(0, {line, 0})
    vim.cmd("startinsert")
  end, { desc = "Add markdown cell above", silent = true })

  map("n", "<leader>mdb", function()
    local line = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(0, line, line, false, {"", ""})
    vim.api.nvim_win_set_cursor(0, {line+1, 0})
    vim.cmd("startinsert")
  end, { desc = "Add markdown cell below", silent = true })

  -- Navigation between cells using treesitter if available
  pcall(function()
    map("n", "]c", "<cmd>TSTextobjectGotoNextStart @code_cell.inner<CR>", { desc = "Next code cell", silent = true })
    map("n", "[c", "<cmd>TSTextobjectGotoPreviousStart @code_cell.inner<CR>", { desc = "Previous code cell", silent = true })
  end)

  -- Create a help command to display all Jupyter notebook mappings
  vim.api.nvim_create_user_command("JupyterHelp", function()
    local help_text = [[
    # Jupyter Notebook Mappings

    ## Initialization Commands
    <leader>ji - Initialize Jupyter environment (sets up kernel, LSP, etc.)
    <leader>jf - Fix Jupyter runner (use if code execution isn't working)
    <leader>jh - Show this help
    <leader>jm - Convert notebook to markdown (manual conversion)
    <leader>jn - Convert markdown to notebook (manual conversion)

    ## Quarto Runner Commands (Recommended)
    <leader>qc - Run current cell
    <leader>qa - Run cell and above
    <leader>qA - Run all cells
    <leader>ql - Run line
    <leader>q  - Run visual selection (in visual mode)
    <leader>qL - Run all cells of all languages

    ## Quick Aliases
    <leader>e  - Run cell (alias)
    <leader>e  - Run selection (in visual mode)
    <leader>E  - Run all cells (alias)

    ## Cell Management
    <leader>ca - Add code cell above
    <leader>cb - Add code cell below
    <leader>mda - Add markdown cell above
    <leader>mdb - Add markdown cell below

    ## Navigation
    ]c - Go to next code block
    [c - Go to previous code block
    <C-n> - Next code chunk (Otter)
    <C-p> - Previous code chunk (Otter)
    ib - Select inside code block (text object)
    ab - Select around code block (text object)

    ## Cell Manipulation
    <leader>sbl - Swap with next code block
    <leader>sbh - Swap with previous code block

    ## Molten Commands (Advanced)
    <leader>mi - Initialize Molten kernel
    <leader>me - Evaluate operator (use with text objects)
    <leader>mr - Re-evaluate cell
    <leader>md - Delete cell
    <leader>mh - Hide output
    <leader>ms - Enter output window
    <leader>mo - Open in browser
    <leader>mv - Import output as cell
    <leader>mA - Run all cells
    <leader>mc - Rerun current cell
    <leader>mx - Interrupt kernel
    <leader>mk - Restart kernel

    ## Direct Commands (When Quarto Runner Fails)
    <leader>ml - Run current line directly with Molten
    <leader>ma - Run current cell directly with Molten
    <leader>ra - Run all cells (skips Jupytext header)

    ## Commands
    :NewNotebook filename - Create a new notebook
    :JupyterInit - Initialize Jupyter environment
    :JupyterFixRunner - Fix code runner issues
    :MoltenRunAllCells - Run all cells (skips Jupytext header)
    :JupytextToMarkdown - Convert notebook to markdown
    :JupytextToNotebook - Convert markdown to notebook
    :JupyterHelp - Show this help
    ]]

    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

    -- Set the content
    local lines = {}
    for line in help_text:gmatch("([^\n]*)\n?") do
      table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Open in a floating window
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(#lines, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local opts = {
      relative = 'editor',
      width = width,
      height = height,
      row = row,
      col = col,
      style = 'minimal',
      border = 'rounded',
      title = ' Jupyter Notebook Help ',
      title_pos = 'center',
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set mappings for the help window
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { noremap = true, silent = true })
  end, {})

  -- Add a mapping for the help command
  map("n", "<leader>jh", ":JupyterHelp<CR>", { desc = "Jupyter notebook help", silent = true })

  -- Add a mapping for initializing Jupyter environment
  map("n", "<leader>ji", ":JupyterInit<CR>", { desc = "Initialize Jupyter environment", silent = true })


  vim.api.nvim_create_user_command("MoltenRunAllCells", function()
    -- Check if Molten is initialized
    if require("molten.status").initialized() ~= "Molten" then
      vim.notify("Molten is not initialized. Initializing now...", vim.log.levels.INFO)
      vim.cmd("MoltenInit python3")
      vim.defer_fn(function()
        vim.cmd("MoltenRunAllCells")
      end, 500)
      return
    end

    -- Find all Python code cells in the buffer
    local cells = {}
    local in_jupytext_header = false
    local jupytext_header_end = 0
    local in_cell = false
    local cell_start = 0

    -- First, check if there's a Jupytext header
    for i = 1, 20 do  -- Check the first 20 lines
      local line = vim.fn.getline(i)
      if i == 1 and line:match("^%-%-%-") then
        in_jupytext_header = true
      elseif in_jupytext_header and line:match("^%-%-%-") then
        jupytext_header_end = i
        break
      end
    end

    -- Now find all code cells
    local start_line = jupytext_header_end > 0 and jupytext_header_end + 1 or 1
    for i = start_line, vim.fn.line("$") do
      local line = vim.fn.getline(i)

      if not in_cell and (line:match("^```%s*{?python") or line:match("^```%s*python")) then
        in_cell = true
        cell_start = i + 1  -- Skip the opening ```python line
      elseif in_cell and line:match("^```%s*$") then
        in_cell = false
        -- Add the cell range to our list
        if i - 1 >= cell_start then
          table.insert(cells, {start = cell_start, ["end"] = i - 1})
        end
      end
    end

    -- Execute each cell
    if #cells > 0 then
      vim.notify("Running " .. #cells .. " code cells...", vim.log.levels.INFO)

      -- Function to run cells sequentially
      local function run_next_cell(index)
        if index <= #cells then
          local cell = cells[index]
          -- Get the text from the cell range
          local lines = vim.api.nvim_buf_get_lines(0, cell.start - 1, cell["end"], false)
          local code = table.concat(lines, "\n")

          -- Use MoltenEvaluateOperator with visual selection or vim.fn.MoltenEvaluateText
          if vim.fn.exists("*MoltenEvaluateText") == 1 then
            vim.fn.MoltenEvaluateText(code)
          else
            -- Alternative approach: set marks and use MoltenEvaluateOperator
            vim.api.nvim_win_set_cursor(0, {cell.start, 0})
            vim.cmd("normal! m[")
            vim.api.nvim_win_set_cursor(0, {cell["end"], 0})
            vim.cmd("normal! m]")
            vim.cmd("MoltenEvaluateOperator")
            vim.cmd("normal! `[v`]")
          end

          -- Wait a bit before running the next cell
          vim.defer_fn(function()
            run_next_cell(index + 1)
          end, 100)
        else
          vim.notify("Finished running all " .. #cells .. " code cells.", vim.log.levels.INFO)
        end
      end

      -- Start running cells
      run_next_cell(1)
    else
      vim.notify("No Python code cells found in this buffer.", vim.log.levels.WARN)
    end
  end, {})

  -- Add a mapping for running all cells
  map("n", "<leader>rA", ":MoltenRunAllCells<CR>", { desc = "Run all cells (skip header)", silent = true })

  -- Add mappings for Jupytext conversion
  map("n", "<leader>jm", ":JupytextToMarkdown<CR>", { desc = "Convert notebook to markdown", silent = true })
  map("n", "<leader>jn", ":JupytextToNotebook<CR>", { desc = "Convert markdown to notebook", silent = true })
end

return M
