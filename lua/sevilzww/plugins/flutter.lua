-- Flutter related plugins
return {
  {
    'akinsho/flutter-tools.nvim',
    lazy = false,
    ft = {"dart"},
    dependencies = {
      'nvim-lua/plenary.nvim',
      'stevearc/dressing.nvim',  -- Optional for better UI
      'nvim-neotest/nvim-nio',   -- Required for latest version
    },
    config = function()
      -- Setup Android SDK environment variables
      require("sevilzww.core.android_env").setup()

      -- Check if Flutter exists in the home directory
      local home_dir = vim.fn.expand("$HOME")
      local flutter_dir = home_dir .. "/flutter"
      local flutter_bin_dir = flutter_dir .. "/bin"
      local flutter_bin = flutter_bin_dir .. "/flutter"
      local dart_sdk = flutter_dir .. "/bin/cache/dart-sdk"
      local dart_bin = dart_sdk .. "/bin/dart"

      -- Check if Flutter is installed
      if vim.fn.filereadable(flutter_bin) == 1 then
        -- Make sure the executables have proper permissions
        vim.fn.system("chmod +x " .. flutter_bin)
        if vim.fn.filereadable(dart_bin) == 1 then
          vim.fn.system("chmod +x " .. dart_bin)
        end

        -- Add Flutter to PATH for this session if not already there
        if vim.fn.exepath('flutter') == "" then
          vim.env.PATH = vim.env.PATH .. ":" .. flutter_bin_dir
          vim.notify("Added Flutter to PATH for this session: " .. flutter_bin_dir, vim.log.levels.INFO)
        else
          vim.notify("Flutter found in PATH", vim.log.levels.INFO)
        end

        -- Check if Dart SDK is available
        if vim.fn.isdirectory(dart_sdk) == 1 then
          vim.notify("Dart SDK found at " .. dart_sdk, vim.log.levels.INFO)
        else
          vim.notify("Dart SDK not found at " .. dart_sdk .. ". Some features may not work correctly.", vim.log.levels.WARN)
        end
      else
        vim.notify("Flutter not found at " .. flutter_bin .. ". Some features may not work correctly.", vim.log.levels.WARN)
      end

      -- Create a custom error handler to suppress specific errors
      local function suppress_errors(err, method)
        -- List of errors to suppress
        local suppress_patterns = {
          "textDocument/documentColor",
          "not found: \"textDocument/documentColor\" request handler"
        }

        -- Check if the error message contains any of the patterns to suppress
        for _, pattern in ipairs(suppress_patterns) do
          if err and type(err) == "string" and err:find(pattern) then
            -- Just return nil instead of throwing an error
            return nil
          end
        end

        -- If not suppressed, let the error propagate
        error(err)
      end

      -- Override the request method in the LSP client to handle errors gracefully
      local old_request = vim.lsp.buf_request
      vim.lsp.buf_request = function(bufnr, method, params, handler)
        local success, result = pcall(old_request, bufnr, method, params, handler)
        if not success and method == "textDocument/documentColor" then
          -- Suppress errors for documentColor requests
          return suppress_errors(result, method)
        end
        return result
      end

      local home_dir = vim.fn.expand("$HOME")
      local flutter_bin = home_dir .. "/flutter/bin/flutter"

      -- Check if Flutter executable exists
      if vim.fn.filereadable(flutter_bin) ~= 1 then
        vim.notify("Flutter executable not found at " .. flutter_bin, vim.log.levels.ERROR)
        return
      end

      require("flutter-tools").setup {
        ui = {
          border = "rounded",
          notification_style = 'native',
        },
        decorations = {
          statusline = {
            app_version = true,
            device = true,
            project_config = true,
          }
        },
        debugger = {
          enabled = true,
          run_via_dap = true,
          register_configurations = function(_)
            local dap = require("dap")
            dap.adapters.dart = {
              type = "executable",
              command = dart_bin,
              args = {"debug_adapter"}
            }
            dap.configurations.dart = {
              {
                type = "dart",
                request = "launch",
                name = "Launch Flutter",
                dartSdkPath = vim.fn.expand("$HOME/flutter/bin/cache/dart-sdk/"),
                flutterSdkPath = vim.fn.expand("$HOME/flutter"),
                program = "${workspaceFolder}/lib/main.dart",
                cwd = "${workspaceFolder}",
              }
            }
          end,
        },
        flutter_path = flutter_bin,
        fvm = false,
        widget_guides = {
          enabled = true,
        },
        closing_tags = {
          highlight = "ErrorMsg",
          prefix = ">",
          enabled = true
        },
        dev_log = {
          enabled = true,
          open_cmd = "tabedit",
        },
        dev_tools = {
          autostart = false,
          auto_open_browser = false,
        },
        outline = {
          open_cmd = "30vnew",
          auto_open = false
        },
        lsp = {
          color = {
            enabled = true,
            background = true,
            foreground = true,
            virtual_text = true,
            virtual_text_str = "■",
          },
          setup_handlers = {
            dartls = function(config)
              return true
            end,
          },
          handlers = {
            ["textDocument/documentColor"] = function(err, result, ctx, config)
              return {}
            end,
          },
          on_attach = function(client, bufnr)
            require("sevilzww.mappings.flutter").setup_buffer(client, bufnr)
          end,
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            analysisExcludedFolders = {
              vim.fn.expand("$HOME/flutter/packages"),
              vim.fn.expand("$HOME/.pub-cache"),
            },
            renameFilesWithClasses = "prompt",
            enableSnippets = true,
            updateImportsOnRename = true,
            enableSdkFormatter = true,
            lineLength = 100,
          }
        }
      }
    end,
  },

  {
    "dimaportenko/telescope-simulators.nvim",
    dependencies = {"nvim-telescope/telescope.nvim"},
    config = function ()
      require("sevilzww.core.android_env").setup()

      -- Check if Flutter is in PATH
      if vim.fn.executable("flutter") ~= 1 then
        -- Try to add Flutter to PATH again
        local home_dir = vim.fn.expand("$HOME")
        local flutter_bin_dir = home_dir .. "/flutter/bin"

        if vim.fn.isdirectory(flutter_bin_dir) == 1 then
          vim.env.PATH = flutter_bin_dir .. ":" .. vim.env.PATH
          vim.notify("Added Flutter to PATH from telescope-simulators: " .. flutter_bin_dir, vim.log.levels.INFO)
        end
      end

      require("simulators").setup({
        android_emulator = true,
        apple_simulator = false,
        -- Configure Android emulator path
        android_emulator_path = vim.fn.executable("emulator") == 1 and "emulator" or "/opt/android-sdk/emulator/emulator",
        -- Configure adb path
        adb_path = vim.fn.executable("adb") == 1 and "adb" or "/opt/android-sdk/platform-tools/adb",
      })

      require("telescope").load_extension("simulators")
      vim.schedule(function()
        require("sevilzww.mappings.telescope").setup()
      end)

      -- We're using the CreateAVD command from android_env.lua instead

      -- Create a command to list available AVDs
      vim.api.nvim_create_user_command("ListAVDs", function()
        vim.cmd("terminal avdmanager list avd")
      end, { desc = "List available Android Virtual Devices" })
    end,
  },
}
