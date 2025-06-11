local M = {}

local function get_flutter_bin()
  local home_dir = vim.fn.expand("$HOME")
  local flutter_bin = home_dir .. "/flutter/bin/flutter"

  if vim.fn.filereadable(flutter_bin) ~= 1 then
    vim.notify("Flutter executable not found at " .. flutter_bin, vim.log.levels.ERROR)
    return nil
  end

  return flutter_bin
end

-- Empty setup function to maintain compatibility with the existing require call in core/mappings.lua
function M.setup()
  vim.api.nvim_create_user_command("Flutter", function(opts)
    local flutter_bin = get_flutter_bin()
    if flutter_bin then
      vim.cmd("terminal " .. flutter_bin .. " " .. opts.args)
    end
  end, { nargs = "*", desc = "Run any Flutter command" })
end

function M.setup_buffer(client, bufnr)
  local opts = {noremap = true, silent = true, buffer = bufnr}
  local map = vim.keymap.set

  local has_flutter_tools = pcall(require, "flutter-tools")

  if has_flutter_tools then
    -- Flutter-tools commands
    map("n", "<leader>fe", "<cmd>FlutterEmulators<CR>", vim.tbl_extend("force", opts, { desc = "Flutter Emulators" }))
    map("n", "<leader>fo", "<cmd>FlutterOutlineToggle<CR>", vim.tbl_extend("force", opts, { desc = "Flutter Outline" }))
    map("n", "<leader>fv", "<cmd>FlutterDevTools<CR>", vim.tbl_extend("force", opts, { desc = "Flutter DevTools" }))
    map("n", "<leader>fl", "<cmd>DartLspRestart<CR>", vim.tbl_extend("force", opts, { desc = "Dart/Flutter LSP Restart" }))
    map("n", "<leader><leader>fr", "<cmd>FlutterRun<CR>", vim.tbl_extend("force", opts, { desc = "Flutter Run" }))
  else
    vim.notify("flutter-tools.nvim not found. Flutter commands won't work.", vim.log.levels.WARN)
  end

  vim.api.nvim_buf_create_user_command(bufnr, "FlutterClean", function()
    local flutter_bin = get_flutter_bin()
    if flutter_bin then
      vim.cmd("terminal " .. flutter_bin .. " clean")
    end
  end, { desc = "Run flutter clean" })
  map("n", "<leader>fc", "<cmd>FlutterClean<CR>", vim.tbl_extend("force", opts, { desc = "Flutter Clean" }))

  vim.api.nvim_buf_create_user_command(bufnr, "FlutterPubGet", function()
    local flutter_bin = get_flutter_bin()
    if flutter_bin then
      vim.cmd("terminal " .. flutter_bin .. " pub get")
    end
  end, { desc = "Run flutter pub get" })
  map("n", "<leader>fp", "<cmd>FlutterPubGet<CR>", vim.tbl_extend("force", opts, { desc = "Flutter Pub Get" }))

  vim.api.nvim_buf_create_user_command(bufnr, "FlutterTest", function()
    local flutter_bin = get_flutter_bin()
    if flutter_bin then
      vim.cmd("terminal " .. flutter_bin .. " test")
    end
  end, { desc = "Run flutter test" })
  map("n", "<leader>ft", "<cmd>FlutterTest<CR>", vim.tbl_extend("force", opts, { desc = "Flutter Test" }))

  vim.api.nvim_buf_create_user_command(bufnr, "FlutterDevicesSafe", function()
    local flutter_bin = get_flutter_bin()
    if flutter_bin then
      vim.cmd("terminal " .. flutter_bin .. " devices")
    end
  end, { desc = "List Flutter devices safely" })
end
return M
