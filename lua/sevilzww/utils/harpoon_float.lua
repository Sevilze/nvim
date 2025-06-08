local M = {}

-- State management
local state = {
  win_id = nil,
  buf_id = nil,
  current_selection = 1,
  scroll_offset = 0,
  is_visible = false,
  items = {},
  original_win = nil,
  current_buffer_path = nil,
  hold_mode_active = false,
  hold_mode_timer = nil,
}

-- Configuration
local config = {
  max_items = 10,
  width = 40,
  height = 10,
  border = "rounded",
  title = " Harpoon ",
  highlight = {
    normal = "Normal",
    border = "FloatBorder",
    title = "FloatTitle",
    selected = "Visual",
    current_buffer = "DiagnosticOk",
    number = "Number",
    filename = "String",
  }
}

local function setup_highlights()
  vim.api.nvim_set_hl(0, "HarpoonCurrentBuffer", { fg = "#9ece6a", bold = true })
  config.highlight.current_buffer = "HarpoonCurrentBuffer"
end

-- Utility functions
local function get_display_name(file_path)
  if not file_path then return "" end
  local name = vim.fn.fnamemodify(file_path, ":t")
  if name == "" then
    name = vim.fn.fnamemodify(file_path, ":h:t") .. "/"
  end
  return name
end

-- Filter and compact Harpoon list to remove null/empty items
local function get_valid_items()
  local harpoon = require("harpoon")
  local list = harpoon:list()
  local raw_items = list and list.items or {}
  local valid_items = {}

  -- Filter out null, empty, or invalid items
  for i, item in ipairs(raw_items) do
    if item and item.value and item.value ~= "" then
      local valid_item = {
        value = item.value,
        context = item.context or { row = 1, col = 0 }
      }
      table.insert(valid_items, valid_item)
    end
  end

  return valid_items
end

local function get_current_buffer_path()
  local current_buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(current_buf)
  if buf_name == "" then return nil end
  -- Resolve to absolute path and normalize
  local abs_path = vim.fn.fnamemodify(buf_name, ":p")
  -- Remove trailing slash if it exists
  return abs_path:gsub("/$", "")
end

local function is_current_buffer(item_path)
  if not state.current_buffer_path or not item_path then return false end

  -- Handle both absolute and relative paths
  local item_full_path = vim.fn.fnamemodify(item_path, ":p")
  item_full_path = item_full_path:gsub("/$", "")

  -- Compare normalized paths
  local current_normalized = state.current_buffer_path:gsub("/$", "")
  return item_full_path == current_normalized
end

-- Window positioning
local function get_window_config()
  local editor_width = vim.o.columns
  local row = 2
  local col = editor_width - config.width - 2

  return {
    relative = "editor",
    width = config.width,
    height = config.height,
    row = row,
    col = col,
    style = "minimal",
    border = config.border,
    title = config.title,
    title_pos = "center",
  }
end

local function update_buffer_content()
  if not state.buf_id or not vim.api.nvim_buf_is_valid(state.buf_id) then
    return
  end

  state.current_buffer_path = get_current_buffer_path()
  
  local lines = {}
  local highlights = {}

  state.items = get_valid_items()

  if #state.items == 0 then
    table.insert(lines, "No Harpoon marks")
  else
    local start_idx = state.scroll_offset + 1
    local end_idx = math.min(start_idx + config.max_items - 1, #state.items)

    if state.current_selection > #state.items then
      state.current_selection = math.max(1, #state.items)
    end

    -- Adjust scroll offset to keep current selection visible
    if state.current_selection < start_idx then
      state.scroll_offset = state.current_selection - 1
      start_idx = state.current_selection
      end_idx = math.min(start_idx + config.max_items - 1, #state.items)
    elseif state.current_selection > end_idx then
      state.scroll_offset = state.current_selection - config.max_items
      start_idx = state.scroll_offset + 1
      end_idx = state.current_selection
    end

    -- Generate visible lines with proper justification
    for i = start_idx, end_idx do
      local item = state.items[i]
      local display_name = get_display_name(item.value)

      local number_str = tostring(i)
      local line = string.format("%-3s%s", number_str, display_name)
      table.insert(lines, line)
      local display_line = i - start_idx

      local is_current = is_current_buffer(item.value)
      local filename_hl = is_current and config.highlight.current_buffer or config.highlight.filename

      table.insert(highlights, {
        line = display_line,
        col_start = 0,
        col_end = 3,
        hl_group = config.highlight.number
      })

      table.insert(highlights, {
        line = display_line,
        col_start = 3,
        col_end = -1,
        hl_group = filename_hl
      })
    end
  end

  vim.api.nvim_buf_set_option(state.buf_id, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf_id, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf_id, "modifiable", false)

  local ns_id = vim.api.nvim_create_namespace("harpoon_float")
  vim.api.nvim_buf_clear_namespace(state.buf_id, ns_id, 0, -1)

  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      state.buf_id,
      ns_id,
      hl.hl_group,
      hl.line,
      hl.col_start,
      hl.col_end
    )
  end

  -- Highlight current selection
  if #state.items > 0 and state.current_selection >= 1 and state.current_selection <= #state.items then
    local start_idx = state.scroll_offset + 1
    local selection_display_line = state.current_selection - start_idx

    if selection_display_line >= 0 and selection_display_line < #lines then
      vim.api.nvim_buf_add_highlight(
        state.buf_id,
        ns_id,
        config.highlight.selected,
        selection_display_line,
        0,
        -1
      )
    end
  end
end

local function move_selection(direction)
  if #state.items == 0 then return end

  local old_selection = state.current_selection

  if direction > 0 then
    state.current_selection = math.min(state.current_selection + direction, #state.items)
  else
    state.current_selection = math.max(state.current_selection + direction, 1)
  end

  if old_selection ~= state.current_selection then
    update_buffer_content()
  end
end

local function jump_to_selection(index)
  if index > 0 and index <= #state.items then
    state.current_selection = index
    update_buffer_content()
  end
end

-- Viewport-relative boundary jumping functions with numeric offset
local function jump_viewport_up(offset)
  if #state.items == 0 then return end

  offset = offset or 1
  -- Move the viewport up by offset positions
  -- This means the new top-most visible buffer becomes the old top - offset
  local current_top = state.scroll_offset + 1
  local new_top = math.max(1, current_top - offset)

  -- Update scroll offset to show the new viewport
  state.scroll_offset = new_top - 1

  -- Adjust current selection to stay within the new visible range
  local new_bottom = math.min(new_top + config.max_items - 1, #state.items)
  if state.current_selection > new_bottom then
    state.current_selection = new_bottom
  elseif state.current_selection < new_top then
    state.current_selection = new_top
  end

  update_buffer_content()
end

local function jump_viewport_down(offset)
  if #state.items == 0 then return end

  offset = offset or 1
  -- Move the viewport down by offset positions
  -- This means the new bottom-most visible buffer becomes the old bottom + offset
  local current_top = state.scroll_offset + 1
  local current_bottom = math.min(current_top + config.max_items - 1, #state.items)
  local new_bottom = math.min(current_bottom + offset, #state.items)
  local new_top = math.max(1, new_bottom - config.max_items + 1)

  state.scroll_offset = new_top - 1

  if state.current_selection < new_top then
    state.current_selection = new_top
  elseif state.current_selection > new_bottom then
    state.current_selection = new_bottom
  end

  update_buffer_content()
end

local function reset_scroll_state()
  state.current_selection = 1
  state.scroll_offset = 0
end

-- Hold-key navigation system
local function cleanup_hold_mode()
  if state.hold_mode_timer then
    vim.fn.timer_stop(state.hold_mode_timer)
    state.hold_mode_timer = nil
  end

  if state.hold_mode_active then
    state.hold_mode_active = false
    local buf = vim.api.nvim_get_current_buf()
    pcall(vim.keymap.del, "n", "j", { buffer = buf })
    pcall(vim.keymap.del, "n", "k", { buffer = buf })
  end
end

local function setup_hold_mode()
  if not M.is_visible() then return end

  -- Clean up any existing hold mode
  cleanup_hold_mode()

  state.hold_mode_active = true
  local buf = vim.api.nvim_get_current_buf()

  -- Set up temporary j/k mappings for continuous navigation
  vim.keymap.set("n", "j", function()
    if M.is_visible() and state.hold_mode_active then
      M.move_down(1)
      -- Reset the inactivity timer
      if state.hold_mode_timer then
        vim.fn.timer_stop(state.hold_mode_timer)
      end
      -- Set a new timer for cleanup after 500ms of inactivity
      state.hold_mode_timer = vim.fn.timer_start(500, function()
        cleanup_hold_mode()
      end)
    else
      cleanup_hold_mode()
    end
  end, { buffer = buf, desc = "Harpoon hold: move down", silent = true })

  vim.keymap.set("n", "k", function()
    if M.is_visible() and state.hold_mode_active then
      M.move_up(1)
      -- Reset the inactivity timer
      if state.hold_mode_timer then
        vim.fn.timer_stop(state.hold_mode_timer)
      end
      -- Set a new timer for cleanup after 500ms of inactivity
      state.hold_mode_timer = vim.fn.timer_start(500, function()
        cleanup_hold_mode()
      end)
    else
      cleanup_hold_mode()
    end
  end, { buffer = buf, desc = "Harpoon hold: move up", silent = true })

  -- Initial timer for cleanup after 500ms of inactivity
  state.hold_mode_timer = vim.fn.timer_start(500, function()
    cleanup_hold_mode()
  end)
end

-- Window management
local function create_floating_window()
  state.buf_id = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(state.buf_id, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(state.buf_id, "filetype", "harpoon-float")
  vim.api.nvim_buf_set_option(state.buf_id, "modifiable", false)

  local win_config = get_window_config()
  state.win_id = vim.api.nvim_open_win(state.buf_id, false, win_config)

  vim.api.nvim_win_set_option(state.win_id, "winhl", "Normal:" .. config.highlight.normal)
  vim.api.nvim_win_set_option(state.win_id, "wrap", false)
  vim.api.nvim_win_set_option(state.win_id, "cursorline", false)

  update_buffer_content()
  state.is_visible = true
end

local function close_floating_window()
  cleanup_hold_mode()

  if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
    vim.api.nvim_win_close(state.win_id, true)
  end

  if state.buf_id and vim.api.nvim_buf_is_valid(state.buf_id) then
    vim.api.nvim_buf_delete(state.buf_id, { force = true })
  end

  state.win_id = nil
  state.buf_id = nil
  state.is_visible = false
end

-- Public API
function M.toggle()
  if state.is_visible then
    M.close()
  else
    M.show()
  end
end

function M.show()
  if state.is_visible then
    M.refresh()
    return
  end

  state.original_win = vim.api.nvim_get_current_win()
  reset_scroll_state()
  create_floating_window()
end

function M.close()
  close_floating_window()
end

function M.refresh()
  if state.is_visible then
    update_buffer_content()
  end
end

function M.move_up(count)
  count = count or 1
  move_selection(-count)
end

function M.move_down(count)
  count = count or 1
  move_selection(count)
end

function M.jump_to(index)
  jump_to_selection(index)
end

function M.jump_viewport_up(offset)
  jump_viewport_up(offset)
end

function M.jump_viewport_down(offset)
  jump_viewport_down(offset)
end

function M.select_current()
  if #state.items == 0 or state.current_selection > #state.items then
    return
  end

  local item = state.items[state.current_selection]
  if item then
    M.close()
    vim.schedule(function()
      local harpoon = require("harpoon")
      harpoon:list():select(state.current_selection)
    end)
  end
end

function M.is_visible()
  return state.is_visible
end

function M.setup_navigation()
  local map = vim.keymap.set

  -- Basic navigation
  map("n", "<leader>wj", function()
    if M.is_visible() then M.move_down(1) end
  end, { desc = "Harpoon float: move down", silent = true })

  map("n", "<leader>wk", function()
    if M.is_visible() then M.move_up(1) end
  end, { desc = "Harpoon float: move up", silent = true })

  -- Hold-key navigation with <leader>z
  map("n", "<leader>z", function()
    if M.is_visible() then
      setup_hold_mode()
    end
  end, { desc = "Harpoon float: enable hold navigation mode", silent = true })

  map("n", "<leader>w<CR>", function()
    if M.is_visible() then M.select_current() end
  end, { desc = "Harpoon float: select current item", silent = true })

  map("n", "<leader>wq", function()
    if M.is_visible() then M.close() end
  end, { desc = "Harpoon float: close", silent = true })

  -- Direct item jumping
  for i = 1, 9 do
    map("n", "<leader>w" .. i, function()
      if M.is_visible() then M.jump_to(i) end
    end, { desc = "Harpoon float: jump to " .. i, silent = true })
  end

  for i = 1, 9 do
    map("n", "<M-" .. i .. ">w", function()
      if M.is_visible() then M.jump_viewport_up(i) end
    end, { desc = "Harpoon float: move viewport up by " .. i, silent = true })

    map("n", "<M-" .. i .. ">s", function()
      if M.is_visible() then M.jump_viewport_down(i) end
    end, { desc = "Harpoon float: move viewport down by " .. i, silent = true })
  end

  -- Auto-refresh buffer highlighting
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      if M.is_visible() then
        vim.schedule(function()
          M.refresh()
        end)
      end
    end,
  })

  -- Auto-refresh when Harpoon list changes
  vim.api.nvim_create_autocmd("User", {
    pattern = "HarpoonListChanged",
    callback = function()
      if M.is_visible() then
        M.refresh()
      end
    end,
  })

  -- Handle window resize
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if M.is_visible() then
        if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
          local new_config = get_window_config()
          vim.api.nvim_win_set_config(state.win_id, new_config)
        end
      end
    end,
  })
end

-- Configuration override
function M.setup(user_config)
  if user_config then
    config = vim.tbl_deep_extend("force", config, user_config)
  end

  setup_highlights()
  M.setup_navigation()

  vim.api.nvim_create_user_command("HarpoonFloatToggle", M.toggle, { desc = "Toggle Harpoon floating window" })
  vim.api.nvim_create_user_command("HarpoonFloatShow", M.show, { desc = "Show Harpoon floating window" })
  vim.api.nvim_create_user_command("HarpoonFloatClose", M.close, { desc = "Close Harpoon floating window" })
  vim.api.nvim_create_user_command("HarpoonFloatRefresh", M.refresh, { desc = "Refresh Harpoon floating window" })
end

return M