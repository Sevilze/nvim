local function notify(msg, level, opts)
  opts = opts or {}
  opts.title = opts.title or "Harpoon"
  opts.timeout = opts.timeout or 500
  opts.icon = opts.icon or "󱡅"

  vim.notify(msg, level or vim.log.levels.INFO, opts)
end

-- Editor related plugins
return {
  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      return require "nvchad.configs.gitsigns"
    end,
  },

  {
    "ThePrimeagen/harpoon",
    lazy = false,
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")

      -- Simple Harpoon setup focused on buffer list saving
      harpoon:setup({
        settings = {
          save_on_toggle = true,
          sync_on_ui_close = true,
          save_on_change = true,
        },

        global_settings = {
          save_on_exit = true,
          mark_branch = false,
          save_path = vim.fn.stdpath("data") .. "/harpoon/",
          projects_enabled = true,
          load_on_startup = true,
        },

        menu = {
          width = vim.api.nvim_win_get_width(0) - 4,
        },
      })

      -- Create directory for Harpoon data if it doesn't exist
      local harpoon_dir = vim.fn.stdpath("data") .. "/harpoon"
      if vim.fn.isdirectory(harpoon_dir) == 0 then
        vim.fn.mkdir(harpoon_dir, "p")
      end

      vim.schedule(function()
        require("sevilzww.mappings.harpoon").setup()
      end)

      local function load_harpoon_for_current_dir()
        local cwd = vim.fn.getcwd()
        local project_name = vim.fn.fnamemodify(cwd, ":t")
        local save_path = vim.fn.stdpath("data") .. "/harpoon/"

        if save_path:sub(-1) ~= "/" then
          save_path = save_path .. "/"
        end

        local project_file = save_path .. project_name .. ".json"
        local file_exists = vim.fn.filereadable(project_file) == 1

        if file_exists then
          local success, content = pcall(function()
            local f = io.open(project_file, "r")
            if f then
              local content = f:read("*all")
              f:close()
              return content
            end
            return nil
          end)

          if success and content then
            local success, data = pcall(function() return vim.fn.json_decode(content) end)
            if success and data and data.mark and data.mark.items then
              local list = harpoon:list()
              if list then
                list:clear()

                for _, item in ipairs(data.mark.items) do
                  list:add(item)
                end

                notify("Loaded " .. #data.mark.items .. " items from Harpoon for " .. project_name)
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

      local function status_dir(dir)
        if dir == vim.fn.expand("~") or dir:match("^/tmp") then
          return false
        end

        return true
      end

      local current_list = nil
      local function capture_current_list()
        local harpoon = require("harpoon")
        local list = harpoon:list()
        if list and list.items and #list.items > 0 then
          current_list = list.items
          return true
        else
          current_list = nil
          return false
        end
      end

      local function save_dir(dir)
        if not status_dir(dir) or not current_list or #current_list == 0 then
          return false
        end

        local project_name = vim.fn.fnamemodify(dir, ":t")
        local save_path = vim.fn.stdpath("data") .. "/harpoon/"
        vim.fn.mkdir(save_path, "p")
        local project_file = save_path .. project_name .. ".json"
        local json_data = vim.fn.json_encode({ mark = { items = current_list } })

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
          notify("Skipping Harpoon save in home directory")
          return
        end

        capture_current_list()
        local success = save_dir(cwd)

        if not success then
          local harpoon = require("harpoon")
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
      }
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
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local sorters = require("telescope.sorters")
      local make_entry = require("telescope.make_entry")

      telescope.setup({
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
            "--glob=!.git/"
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
            i = {
              ["<leader>a"] = function()
                local selection = action_state.get_selected_entry()
                if selection and selection.path then
                  vim.schedule(function()
                    local harpoon = require("harpoon")
                    harpoon:list():add({
                      value = selection.path,
                      context = { text = "" }
                    })
                    vim.notify("Added " .. vim.fs.basename(selection.path) .. " to Harpoon", vim.log.levels.INFO)
                  end)
                end
              end,
              ["<C-c>"] = actions.close,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,
            },
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
                ["<leader>a"] = function(prompt_bufnr)
                  local selection = action_state.get_selected_entry()
                  if selection and selection.path then
                    local context_text = selection.text or ""

                    local item = {
                      value = selection.path,
                      row = selection.lnum or 1,
                      col = selection.col or 0,
                      context = { text = context_text }
                    }

                    require("harpoon"):list():add(item)
                    vim.notify("Added " .. vim.fs.basename(selection.path) .. ":" .. (selection.lnum or 1) .. " to Harpoon", vim.log.levels.INFO)
                  end
                end,
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
          }
        }
      })

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
            devicons = { get_icon = function() return "", "" end }
          end

          local pickers = require("telescope.pickers")
          local finders = require("telescope.finders")
          local conf = require("telescope.config").values
          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")
          local sorters = require("telescope.sorters")
          local entry_display = require("telescope.pickers.entry_display")
          local Job = require("plenary.job")

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

            local displayer = entry_display.create({
              separator = " ",
              items = {
                { width = 2 },
                { remaining = true }
              }
            })

            return displayer({
              { icon, icon_hl },
              entry.filename
            })
          end

          -- Entry maker function
          local entry_maker = function(entry)
            return {
              value = entry.path,
              ordinal = entry.path,
              display = make_display,
              filename = entry.path,
              path = entry.path,
              ext = entry.ext
            }
          end

          local function update_title_only()
            if not current_picker or not current_picker.results_win then return end

            if current_picker.stats then
              current_picker.stats.processed = file_count
              current_picker.stats.matched = file_count
              if current_picker._status and current_picker._status.text then
                current_picker._status.text = file_count .. " / " .. file_count
                vim.api.nvim_win_set_config(current_picker.results_win, {
                  title = current_picker.results_win_options and current_picker.results_win_options.title
                })
              end
            end
          end

          local function process_batch()
            if #current_batch == 0 then return end

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
                  ext = ext
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
              current_picker:refresh(finders.new_table({
                results = {},
                entry_maker = entry_maker,
              }), { reset_prompt = false })

              if current_picker.prompt_bufnr then
                vim.api.nvim_buf_set_option(current_picker.prompt_bufnr, "modifiable", false)
              end
            end

            local timer = vim.loop.new_timer()
            timer:start(0, 100, vim.schedule_wrap(function()
              if not is_collecting then
                timer:stop()
                timer:close()
                return
              end

              -- Force a UI refresh by simulating a prompt change
              if current_picker and current_picker.prompt_bufnr then
                local current_text = vim.api.nvim_buf_get_lines(current_picker.prompt_bufnr, 0, 1, false)[1] or ""
                vim.api.nvim_buf_set_option(current_picker.prompt_bufnr, "modifiable", true)
                vim.api.nvim_buf_set_lines(current_picker.prompt_bufnr, 0, 1, false, {current_text .. " "})
                vim.api.nvim_buf_set_lines(current_picker.prompt_bufnr, 0, 1, false, {current_text})
              end
            end))

            current_job = Job:new({
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
                    vim.api.nvim_buf_set_lines(current_picker.prompt_bufnr, 0, 1, false, {""})
                  end

                  table.sort(ext_order)
                  all_files = {}
                  for _, ext_name in ipairs(ext_order) do
                    table.sort(files_by_ext[ext_name], function(a, b) return a.path < b.path end)

                    for _, file_entry in ipairs(files_by_ext[ext_name]) do
                      table.insert(all_files, file_entry)
                    end
                  end

                  current_picker:refresh(finders.new_table({
                    results = all_files,
                    entry_maker = entry_maker,
                  }), { reset_prompt = false })
                  update_title_only()

                  vim.notify("File collection complete. Found " .. file_count .. " files.", vim.log.levels.INFO)
                end)
              end
            })

            current_job:start()
          end

          local function cleanup()
            if current_job then
              current_job:shutdown()
              current_job = nil
            end
          end

          current_picker = pickers.new(dropdown, {
            finder = finders.new_table({
              results = {},
              entry_maker = entry_maker,
            }),
            sorter = sorters.get_generic_fuzzy_sorter(),
            previewer = conf.file_previewer({}),
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

              map("i", "<leader>a", function()
                local selection = action_state.get_selected_entry()
                if selection then
                  local harpoon = require("harpoon")
                  harpoon:list():add({
                    value = selection.path,
                    context = { text = "" }
                  })

                  vim.notify("Added " .. vim.fs.basename(selection.path) .. " to Harpoon", vim.log.levels.INFO)
                end
              end)

              return true
            end
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
      return require "nvchad.configs.treesitter"
    end,
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "augmentcode/augment.vim",
    lazy = false,
    priority = 1000,
    config = function()
    end,
  },
}
