local function notify(msg, level, opts)
  opts = opts or {}
  opts.title = opts.title or "Harpoon"

  if not opts.timeout then
    if level == vim.log.levels.ERROR then
      opts.timeout = 5000
    elseif level == vim.log.levels.WARN then
      opts.timeout = 3000
    else
      opts.timeout = 500
    end
  end

  opts.icon = opts.icon or "󱡅"

  vim.notify(msg, level or vim.log.levels.INFO, opts)
end

-- Cache for Harpoon items to avoid repeated lookups
local harpoon_cache = {
  items = {},
  last_updated = 0,
  ttl = 1000, -- cache lifetime in ms
}

-- Unified Harpoon-Telescope integration functions
local harpoon_telescope_integration = {}

-- Create a standardized Harpoon item with proper context
local function create_harpoon_item(selection, opts)
  opts = opts or {}
  local item = {
    value = selection.path,
    context = {
      row = opts.row or selection.lnum or 1,
      col = opts.col or selection.col or 0,
      text = opts.text or selection.text or "",
    },
  }
  return item
end

-- Unified Harpoon add handler
local function create_harpoon_add_handler(opts)
  opts = opts or {}
  return function(prompt_bufnr)
    local action_state = require "telescope.actions.state"
    local selection = action_state.get_selected_entry(prompt_bufnr)
    if selection and selection.path then
      local schedule_fn = opts.immediate and function(fn) fn() end or vim.schedule
      schedule_fn(function()
        local harpoon = require "harpoon"
        local item = create_harpoon_item(selection, opts)
        harpoon:list():add(item)

        local context_info = ""
        if item.context.row > 1 then
          context_info = ":" .. item.context.row
        end

        local msg = opts.message_prefix or "Added "
        notify(msg .. vim.fs.basename(selection.path) .. context_info .. " to Harpoon", vim.log.levels.INFO)
      end)
    end
  end
end

-- Unified Harpoon remove handler
local function create_harpoon_remove_handler(opts)
  opts = opts or {}
  return function(prompt_bufnr)
    local action_state = require "telescope.actions.state"
    local selection = action_state.get_selected_entry(prompt_bufnr)
    if selection and selection.path then
      local schedule_fn = opts.immediate and function(fn) fn() end or vim.schedule
      schedule_fn(function()
        local harpoon = require "harpoon"
        local list = harpoon:list()

        local normalized_path = vim.loop.fs_realpath(selection.path)
        for i, item in ipairs(list.items) do
          local item_path = vim.loop.fs_realpath(item.value)
          if item_path == normalized_path then
            list:remove_at(i)
            notify("Removed " .. vim.fs.basename(selection.path) .. " from Harpoon", vim.log.levels.INFO)
            break
          end
        end
      end)
    end
  end
end

-- Create unified key mappings for Harpoon operations
local function create_harpoon_mappings(map, opts)
  opts = opts or {}
  map("i", "<leader>a", create_harpoon_add_handler(opts))
  if not opts.disable_remove then
    map("i", "<leader>r", create_harpoon_remove_handler(opts))
  end
end

-- Enhanced display function that adds Harpoon checkmarks
local function create_harpoon_display_enhancer(original_display_fn, opts)
  opts = opts or {}
  return function(entry)
    local display_output, display_hl = original_display_fn(entry)

    if check_harpoon_list(entry.path) then
      local checkmark = opts.checkmark or " ✓"
      display_output = display_output .. checkmark
      if not display_hl then
        display_hl = {}
      end
      local display_len = #display_output
      local checkmark_len = #checkmark
      table.insert(display_hl, {
        { display_len - checkmark_len + 1, display_len },
        opts.highlight or "TelescopeResultsIdentifier"
      })
    end

    return display_output, display_hl
  end
end

-- Assign functions to the integration table
harpoon_telescope_integration.create_harpoon_item = create_harpoon_item
harpoon_telescope_integration.create_harpoon_add_handler = create_harpoon_add_handler
harpoon_telescope_integration.create_harpoon_remove_handler = create_harpoon_remove_handler
harpoon_telescope_integration.create_harpoon_mappings = create_harpoon_mappings
harpoon_telescope_integration.create_harpoon_display_enhancer = create_harpoon_display_enhancer

-- Editor related plugins
return {
  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      local nvchad_gitsigns = require "nvchad.configs.gitsigns"

      nvchad_gitsigns.on_attach = function(bufnr)
        require("sevilzww.mappings.gitsigns").setup(bufnr)
      end

      return nvchad_gitsigns
    end,
    config = function(_, opts)
      require("gitsigns").setup(opts)
    end,
  },

  {
    "ThePrimeagen/harpoon",
    lazy = false,
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require "harpoon"

      local function refresh_cache()
        harpoon_cache.items = {}
        local list = harpoon:list()
        if list and list.items then
          for _, item in ipairs(list.items) do
            local real = vim.loop.fs_realpath(item.value)
            if real then
              harpoon_cache.items[real] = true
            end
          end
        end
        harpoon_cache.last_updated = vim.loop.now()
      end

      check_harpoon_list = function(file_path)
        local now = vim.loop.now()
        if now - harpoon_cache.last_updated > harpoon_cache.ttl then
          refresh_cache()
        end
        local key = vim.loop.fs_realpath(file_path)
        return key and harpoon_cache.items[key] or false
      end

      -- Monkey patch harpoon methods to invalidate cache
      local list_mt = getmetatable(harpoon:list())
      local cache = harpoon_cache

      if list_mt then
        local orig_add = list_mt.add
        list_mt.add = function(self, ...)
          cache.last_updated = 0
          return orig_add(self, ...)
        end

        local orig_remove = list_mt.remove
        if orig_remove then
          list_mt.remove = function(self, ...)
            cache.last_updated = 0
            return orig_remove(self, ...)
          end
        end

        local orig_remove_at = list_mt.remove_at
        if orig_remove_at then
          list_mt.remove_at = function(self, ...)
            cache.last_updated = 0
            return orig_remove_at(self, ...)
          end
        end

        local orig_clear = list_mt.clear
        if orig_clear then
          list_mt.clear = function(self, ...)
            cache.last_updated = 0
            return orig_clear(self, ...)
          end
        end
      end

      -- Simple Harpoon setup focused on buffer list saving
      harpoon:setup {
        settings = {
          save_on_toggle = true,
          sync_on_ui_close = true,
          save_on_change = true,
        },

        default = {
          get_root_dir = function()
            return vim.loop.cwd()
          end,
          create_list_item = function(config, name)
            local item = {
              value = name,
              context = {
                row = 1,
                col = 0,
              },
            }

            if vim.api.nvim_buf_is_valid(0) then
              local cursor = vim.api.nvim_win_get_cursor(0)
              item.context.row = cursor[1]
              item.context.col = cursor[2]
            end

            return item
          end,
        },

        menu = {
          width = vim.api.nvim_win_get_width(0) - 4,
        },
      }

      -- Create directory for Harpoon data if it doesn't exist
      local harpoon_dir = vim.fn.stdpath "data" .. "/harpoon"
      if vim.fn.isdirectory(harpoon_dir) == 0 then
        vim.fn.mkdir(harpoon_dir, "p")
      end

      vim.schedule(function()
        require("sevilzww.mappings.harpoon").setup()
      end)

      local current_list = nil
      local function capture_current_list()
        local harpoon = require "harpoon"
        local list = harpoon:list()
        if list and list.items and #list.items > 0 then
          current_list = {}
          for _, item in ipairs(list.items) do
            if item and item.value then
              table.insert(current_list, {
                value = item.value,
                context = item.context or { row = 1, col = 0 },
              })
            end
          end
          return true
        else
          current_list = {}
          return false
        end
      end

      local function status_dir(dir)
        if dir == vim.fn.expand "~" or dir:match "^/tmp" then
          return false
        end
        return true
      end

      local function save_dir(dir)
        if not status_dir(dir) or not current_list or #current_list == 0 then
          return false
        end

        local project_name = vim.fn.fnamemodify(dir, ":t")
        local save_path = vim.fn.stdpath "data" .. "/harpoon/"
        vim.fn.mkdir(save_path, "p")
        local project_file = save_path .. project_name .. ".json"
        local json_data = vim.fn.json_encode { mark = { items = current_list } }

        local f, err = io.open(project_file, "w")
        if not f then
          vim.notify("Failed to open file for writing: " .. err, vim.log.levels.ERROR)
          return false
        end
        f:write(json_data)
        f:close()

        notify("Saved Harpoon state for: " .. project_name .. " (" .. #current_list .. " items)")
        return true
      end

      -- File validation functions
      local function validate_file_path(file_path)
        if not file_path or file_path == "" then
          return false, "Empty file path"
        end

        -- Convert relative paths to absolute paths
        local abs_path = vim.fn.fnamemodify(file_path, ":p")

        -- Check if file exists
        if vim.fn.filereadable(abs_path) == 1 then
          return true, abs_path
        end

        return false, "File does not exist: " .. abs_path
      end

      local function load_harpoon_for_current_dir()
        local cwd = vim.fn.getcwd()
        local project_name = vim.fn.fnamemodify(cwd, ":t")
        local save_path = vim.fn.stdpath "data" .. "/harpoon/"

        if save_path:sub(-1) ~= "/" then
          save_path = save_path .. "/"
        end

        local project_file = save_path .. project_name .. ".json"
        local file_exists = vim.fn.filereadable(project_file) == 1

        if file_exists then
          local success, content = pcall(function()
            local f = io.open(project_file, "r")
            if f then
              local content = f:read "*all"
              f:close()
              return content
            end
            return nil
          end)

          if success and content then
            local success, data = pcall(function()
              return vim.fn.json_decode(content)
            end)
            if success and data and data.mark and data.mark.items then
              local list = harpoon:list()
              if list then
                list:clear()

                local valid_items = {}
                local removed_count = 0

                for _, item in ipairs(data.mark.items) do
                  local success, result = pcall(function()
                    if type(item) == "table" then
                      -- Ensure proper structure with row/col defaults
                      local context = item.context or {}
                      if type(context) == "string" then
                        context = { text = context }
                      end

                      return {
                        value = item.value,
                        context = {
                          row = context.row or 1,
                          col = context.col or 0,
                          text = context.text or "",
                        },
                      }
                    else
                      return {
                        value = tostring(item),
                        context = {
                          row = 1,
                          col = 0,
                          text = "",
                        },
                      }
                    end
                  end)

                  if success and result.value then
                    local is_valid, validated_path = validate_file_path(result.value)

                    if is_valid then
                      -- File exists, add to valid items
                      result.value = validated_path
                      table.insert(valid_items, result)
                    else
                      -- File doesn't exist, remove from list
                      removed_count = removed_count + 1
                      notify("Removed missing file: " .. vim.fs.basename(result.value), vim.log.levels.WARN)
                    end
                  end
                end

                for _, valid_item in ipairs(valid_items) do
                  list:add(valid_item)
                end

                local total_loaded = #valid_items
                local summary_msg = "Loaded " .. total_loaded .. " items from Harpoon for " .. project_name
                if removed_count > 0 then
                  summary_msg = summary_msg .. " (removed " .. removed_count .. " missing files)"
                end

                notify(summary_msg, removed_count > 0 and vim.log.levels.WARN or vim.log.levels.INFO)

                if removed_count > 0 then
                  vim.schedule(function()
                    capture_current_list()
                    save_dir(cwd)
                  end)
                end

                return true
              end
            end
          end
        end
        return false
      end

      vim.schedule(function()
        load_harpoon_for_current_dir()
      end)



      vim.api.nvim_create_autocmd("DirChangedPre", {
        pattern = "*",
        callback = function(event)
          local old_dir = vim.fn.getcwd()
          if capture_current_list() then
            save_dir(old_dir)
          end
        end,
      })

      vim.api.nvim_create_autocmd("DirChanged", {
        pattern = "*",
        callback = function(event)
          load_harpoon_for_current_dir()
          vim.schedule(capture_current_list)
        end,
      })

      vim.api.nvim_create_user_command("HarpoonSave", function()
        local cwd = vim.fn.getcwd()
        local project_name = vim.fn.fnamemodify(cwd, ":t")

        if not status_dir(cwd) then
          notify "Skipping Harpoon save in home directory"
          return
        end

        capture_current_list()
        local success = save_dir(cwd)

        if not success then
          local harpoon = require "harpoon"
          local list = harpoon:list()

          if not list or not list.items or #list.items == 0 then
            notify("No Harpoon items to save for project: " .. project_name)
          end
        end

        capture_current_list()
      end, {})

      vim.api.nvim_create_user_command("HarpoonReload", function()
        if load_harpoon_for_current_dir() then
          local cwd = vim.fn.getcwd()
          local project_name = vim.fn.fnamemodify(cwd, ":t")

          vim.schedule(function()
            capture_current_list()
          end)

          notify("Reloaded Harpoon state for project: " .. project_name, vim.log.levels.INFO)
        else
          notify("No Harpoon state found for current project", vim.log.levels.WARN)
        end
      end, {})

      -- Function to get Git changed files and add them to Harpoon
      local function add_git_changed_files_to_harpoon()
        local Job = require "plenary.job"

        -- Check if we're in a Git repository
        local git_check = Job:new {
          command = "git",
          args = { "rev-parse", "--is-inside-work-tree" },
          cwd = vim.fn.getcwd(),
        }

        local git_check_result = git_check:sync()
        if git_check.code ~= 0 then
          notify("Not in a Git repository", vim.log.levels.WARN)
          return
        end

        -- Get Git status
        local git_status = Job:new {
          command = "git",
          args = { "status", "--porcelain" },
          cwd = vim.fn.getcwd(),
        }

        local status_output = git_status:sync()
        if git_status.code ~= 0 then
          notify("Failed to get Git status", vim.log.levels.ERROR)
          return
        end

        -- Parse Git status output
        local changed_files = {}
        local file_extensions = {
          "lua",
          "py",
          "js",
          "ts",
          "jsx",
          "tsx",
          "rs",
          "go",
          "c",
          "cpp",
          "h",
          "hpp",
          "java",
          "kt",
          "swift",
          "rb",
          "php",
          "cs",
          "fs",
          "scala",
          "clj",
          "hs",
          "elm",
          "dart",
          "r",
          "jl",
          "nim",
          "zig",
          "v",
          "odin",
          "json",
          "yaml",
          "yml",
          "toml",
          "xml",
          "html",
          "css",
          "scss",
          "sass",
          "md",
          "rst",
          "txt",
          "conf",
          "cfg",
          "ini",
          "env",
          "sh",
          "bash",
          "zsh",
          "fish",
          "ps1",
          "bat",
          "cmd",
          "vim",
          "sql",
          "dockerfile",
          "makefile",
          "cmake",
          "gradle",
        }

        for _, line in ipairs(status_output) do
          if line and line ~= "" then
            local status_code = line:sub(1, 2)
            local file_path = line:sub(4)

            -- Skip if file doesn't exist or is a directory
            if vim.fn.filereadable(file_path) == 1 and vim.fn.isdirectory(file_path) == 0 then
              local ext = vim.fn.fnamemodify(file_path, ":e"):lower()
              local filename = vim.fn.fnamemodify(file_path, ":t"):lower()

              -- Check if it's a text file by extension or common filenames
              local is_text_file = false
              if ext ~= "" then
                for _, valid_ext in ipairs(file_extensions) do
                  if ext == valid_ext then
                    is_text_file = true
                    break
                  end
                end
              else
                local common_files = {
                  "makefile",
                  "dockerfile",
                  "rakefile",
                  "gemfile",
                  "procfile",
                  "readme",
                  "license",
                  "changelog",
                  "todo",
                  "authors",
                }
                for _, common in ipairs(common_files) do
                  if filename == common then
                    is_text_file = true
                    break
                  end
                end
              end

              if is_text_file then
                local status_desc = ""
                if status_code:sub(1, 1) == "M" then
                  status_desc = "Modified"
                elseif status_code:sub(1, 1) == "A" then
                  status_desc = "Added"
                elseif status_code:sub(1, 1) == "D" then
                  status_desc = "Deleted"
                elseif status_code:sub(1, 1) == "R" then
                  status_desc = "Renamed"
                elseif status_code:sub(1, 1) == "C" then
                  status_desc = "Copied"
                elseif status_code:sub(1, 1) == "?" then
                  status_desc = "Untracked"
                else
                  status_desc = "Changed"
                end

                table.insert(changed_files, {
                  path = file_path,
                  status = status_desc,
                  status_code = status_code,
                })
              end
            end
          end
        end

        if #changed_files == 0 then
          notify("No changed text files found in Git repository", vim.log.levels.INFO)
          return
        end

        vim.schedule(function()
          local has_devicons, devicons = pcall(require, "nvim-web-devicons")
          if not has_devicons then
            devicons = {
              get_icon = function()
                return "", ""
              end,
            }
          end

          local pickers = require "telescope.pickers"
          local finders = require "telescope.finders"
          local conf = require("telescope.config").values
          local actions = require "telescope.actions"
          local action_state = require "telescope.actions.state"
          local entry_display = require "telescope.pickers.entry_display"

          local displayer = entry_display.create {
            separator = " ",
            items = {
              { width = 2 },
              { width = 12 },
              { remaining = true },
              { width = 2 },
            },
          }

          local make_display = function(entry)
            local icon, icon_hl = devicons.get_icon(entry.filename, entry.ext, { default = true })
            local in_harpoon = check_harpoon_list(entry.path)

            return displayer {
              { icon, icon_hl },
              { entry.status, "Comment" },
              entry.filename,
              { in_harpoon and "✓" or "", "TelescopeResultsIdentifier" },
            }
          end

          local entry_maker = function(file_info)
            return {
              value = file_info.path,
              ordinal = file_info.path .. " " .. file_info.status,
              display = make_display,
              filename = file_info.path,
              path = file_info.path,
              status = file_info.status,
              ext = vim.fn.fnamemodify(file_info.path, ":e"),
            }
          end

          pickers
            .new({
              prompt_title = "Git Changed Files → Harpoon",
              finder = finders.new_table {
                results = changed_files,
                entry_maker = entry_maker,
              },
              sorter = conf.generic_sorter {},
              previewer = conf.file_previewer {},
              attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                  local selection = action_state.get_selected_entry()
                  if selection then
                    actions.close(prompt_bufnr)
                    vim.schedule(function()
                      vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
                    end)
                  end
                end)

                -- Use unified Harpoon mappings
                create_harpoon_mappings(map, { immediate = true })

                map("i", "<C-a>", function()
                  local picker = action_state.get_current_picker(prompt_bufnr)
                  local harpoon = require "harpoon"
                  local added_count = 0

                  for entry in picker.manager:iter() do
                    local item = create_harpoon_item(entry)
                    harpoon:list():add(item)
                    added_count = added_count + 1
                  end

                  actions.close(prompt_bufnr)
                  notify("Added " .. added_count .. " Git changed files to Harpoon", vim.log.levels.INFO)
                end)

                return true
              end,
            })
            :find()
        end)
      end

      vim.api.nvim_create_user_command("HarpoonGitFiles", function()
        add_git_changed_files_to_harpoon()
      end, { desc = "Add Git changed files to Harpoon" })
    end,
  },

  "nvim-lua/plenary.nvim",

  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      {
        "BurntSushi/ripgrep",
      },
    },
    cmd = "Telescope",
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.schedule(function()
            pcall(require, "sevilzww.mappings.telescope")
          end)
        end,
      })
    end,
    config = function()
      local telescope = require "telescope"
      local actions = require "telescope.actions"
      local action_state = require "telescope.actions.state"
      local sorters = require "telescope.sorters"
      local make_entry = require "telescope.make_entry"

      -- Override the default file entry maker to include a checkmark for harpoon files
      local original_file_maker = make_entry.gen_from_file
      make_entry.gen_from_file = function(opts)
        local entry_maker = original_file_maker(opts)
        return function(line)
          local entry = entry_maker(line)
          local original_display = entry.display

          entry.display = create_harpoon_display_enhancer(
            function(self) return original_display(self) end
          )

          return entry
        end
      end

      telescope.setup {
        defaults = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob=!.git/",
          },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
            },
          },
          path_display = { "smart" },
          mappings = {
            i = vim.tbl_extend("force", {
              ["<C-c>"] = actions.close,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,
            }, {
              -- Add unified Harpoon mappings
              ["<leader>a"] = create_harpoon_add_handler(),
              ["<leader>r"] = create_harpoon_remove_handler(),
            }),
          },
        },
        pickers = {
          find_files = {
            path_display = { "absolute" },
            file_ignore_patterns = {},
          },
          live_grep = {
            mappings = {
              i = {
                ["<leader>a"] = create_harpoon_add_handler({
                  immediate = true,
                  message_prefix = "Added ",
                }),
              },
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      }

      local ok, _ = pcall(telescope.load_extension, "fzf")
      if not ok then
        vim.notify("Failed to load telescope-fzf-native extension. Some searches may be slower.", vim.log.levels.WARN)
      end

      -- Create a custom command for files grouped by extension with async processing
      vim.api.nvim_create_user_command("FindFilesByExt", function()
        vim.schedule(function()
          local has_devicons, devicons = pcall(require, "nvim-web-devicons")
          if not has_devicons then
            vim.notify("nvim-web-devicons not found, icons won't be displayed", vim.log.levels.WARN)
            devicons = {
              get_icon = function()
                return "", ""
              end,
            }
          end

          local pickers = require "telescope.pickers"
          local finders = require "telescope.finders"
          local conf = require("telescope.config").values
          local actions = require "telescope.actions"
          local action_state = require "telescope.actions.state"
          local sorters = require "telescope.sorters"
          local entry_display = require "telescope.pickers.entry_display"
          local Job = require "plenary.job"

          -- Create dropdown theme that matches find_files
          local dropdown = {
            previewer = true,
            layout_strategy = "horizontal",
            layout_config = {
              width = 0.8,
              height = 0.9,
              prompt_position = "top",
              horizontal = {
                preview_width = 0.55,
              },
              preview_cutoff = 120,
            },
            sorting_strategy = "ascending",
            color_devicons = true,
            prompt_title = "Files by Extension",
          }

          local files_by_ext = {}
          local ext_order = {}
          local all_files = {}
          local current_picker = nil
          local current_job = nil
          local file_count = 0
          local last_update_time = vim.loop.now()
          local is_collecting = true
          local batch_size = 100
          local current_batch = {}
          local batch_count = 0

          -- Create entry maker function
          local make_display = function(entry)
            local icon, icon_hl = devicons.get_icon(entry.filename, entry.ext, { default = true })
            local in_harpoon = check_harpoon_list(entry.path)

            local displayer = entry_display.create {
              separator = " ",
              items = {
                { width = 2 },
                { remaining = true },
                { width = in_harpoon and 2 or 0 },
              },
            }

            local base_display = function()
              return displayer {
                { icon, icon_hl },
                entry.filename,
              }
            end

            if in_harpoon then
              return displayer {
                { icon, icon_hl },
                entry.filename,
                { "✓", "TelescopeResultsIdentifier" },
              }
            else
              return base_display()
            end
          end

          -- Entry maker function
          local entry_maker = function(entry)
            return {
              value = entry.path,
              ordinal = entry.path,
              display = make_display,
              filename = entry.path,
              path = entry.path,
              ext = entry.ext,
            }
          end

          local function update_title_only()
            if not current_picker or not current_picker.results_win then
              return
            end

            if current_picker.stats then
              current_picker.stats.processed = file_count
              current_picker.stats.matched = file_count
              if current_picker._status and current_picker._status.text then
                current_picker._status.text = file_count .. " / " .. file_count
                vim.api.nvim_win_set_config(current_picker.results_win, {
                  title = current_picker.results_win_options and current_picker.results_win_options.title,
                })
              end
            end
          end

          local function process_batch()
            if #current_batch == 0 then
              return
            end

            for _, line in ipairs(current_batch) do
              if line and line ~= "" and vim.fn.isdirectory(line) == 0 then
                local rel_path = vim.fn.fnamemodify(line, ":.")
                local ext = string.lower(vim.fn.fnamemodify(line, ":e"))
                ext = ext == "" and "no_ext" or ext

                if not files_by_ext[ext] then
                  files_by_ext[ext] = {}
                  table.insert(ext_order, ext)
                end

                table.insert(files_by_ext[ext], {
                  path = rel_path,
                  ext = ext,
                })

                file_count = file_count + 1
                if file_count % 100 == 0 then
                  update_title_only()
                end
              end
            end

            current_batch = {}
          end

          local function start_collection()
            if current_job then
              current_job:shutdown()
            end

            files_by_ext = {}
            ext_order = {}
            all_files = {}
            file_count = 0
            is_collecting = true
            current_batch = {}
            batch_count = 0
            last_update_time = vim.loop.now()

            if current_picker then
              current_picker:refresh(
                finders.new_table {
                  results = {},
                  entry_maker = entry_maker,
                },
                { reset_prompt = false }
              )

              if current_picker.prompt_bufnr then
                vim.api.nvim_buf_set_option(current_picker.prompt_bufnr, "modifiable", false)
              end
            end

            local timer = vim.loop.new_timer()
            timer:start(
              0,
              100,
              vim.schedule_wrap(function()
                if not is_collecting then
                  timer:stop()
                  timer:close()
                  return
                end

                -- Force a UI refresh by simulating a prompt change
                if current_picker and current_picker.prompt_bufnr then
                  local current_text = vim.api.nvim_buf_get_lines(current_picker.prompt_bufnr, 0, 1, false)[1] or ""
                  vim.api.nvim_buf_set_option(current_picker.prompt_bufnr, "modifiable", true)
                  vim.api.nvim_buf_set_lines(current_picker.prompt_bufnr, 0, 1, false, { current_text .. " " })
                  vim.api.nvim_buf_set_lines(current_picker.prompt_bufnr, 0, 1, false, { current_text })
                end
              end)
            )

            current_job = Job:new {
              command = "rg",
              args = { "--files", "--hidden", "--glob", "!.git/" },
              cwd = vim.fn.getcwd(),
              on_stdout = function(_, line)
                table.insert(current_batch, line)
                batch_count = batch_count + 1

                if batch_count >= batch_size then
                  process_batch()
                  batch_count = 0
                end
              end,
              on_exit = function(j, return_val)
                if #current_batch > 0 then
                  vim.schedule(function()
                    process_batch()
                  end)
                end

                is_collecting = false

                if return_val ~= 0 then
                  vim.schedule(function()
                    vim.notify("Error finding files", vim.log.levels.ERROR)
                  end)
                  return
                end

                -- Only do a full refresh at the end when collection is complete
                vim.schedule(function()
                  if current_picker and current_picker.prompt_bufnr then
                    vim.api.nvim_buf_set_option(current_picker.prompt_bufnr, "modifiable", true)
                    vim.api.nvim_buf_set_lines(current_picker.prompt_bufnr, 0, 1, false, { "" })
                  end

                  table.sort(ext_order)
                  all_files = {}
                  for _, ext_name in ipairs(ext_order) do
                    table.sort(files_by_ext[ext_name], function(a, b)
                      return a.path < b.path
                    end)

                    for _, file_entry in ipairs(files_by_ext[ext_name]) do
                      table.insert(all_files, file_entry)
                    end
                  end

                  current_picker:refresh(
                    finders.new_table {
                      results = all_files,
                      entry_maker = entry_maker,
                    },
                    { reset_prompt = false }
                  )
                  update_title_only()

                  vim.notify("File collection complete. Found " .. file_count .. " files.", vim.log.levels.INFO)
                end)
              end,
            }

            current_job:start()
          end

          local function cleanup()
            if current_job then
              current_job:shutdown()
              current_job = nil
            end
          end

          current_picker = pickers.new(dropdown, {
            finder = finders.new_table {
              results = {},
              entry_maker = entry_maker,
            },
            sorter = sorters.get_generic_fuzzy_sorter(),
            previewer = conf.file_previewer {},
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                  cleanup()
                  actions.close(prompt_bufnr)

                  vim.schedule(function()
                    vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
                  end)
                end
              end)

              -- Override close action to clean up resources
              local original_close = actions.close
              actions.close = function(bufnr)
                cleanup()
                original_close(bufnr)
              end

              -- Use unified Harpoon mappings
              create_harpoon_mappings(map, { immediate = true })

              return true
            end,
          })

          current_picker:find()
          vim.schedule(function()
            start_collection()
          end)
        end)
      end, { desc = "Find files grouped by extension with async processing" })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = function()
      local opts = require "nvchad.configs.treesitter"
      opts.ensure_installed = vim.list_extend(opts.ensure_installed or {}, { "gitignore" })
      return opts
    end,
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "augmentcode/augment.vim",
    lazy = false,
    priority = 1000,
    config = function() end,
  },
}
