-- Flutter related plugins
return {
  {
    'akinsho/flutter-tools.nvim',
    lazy = false,
    ft = {"dart"},
    dependencies = {
      'nvim-lua/plenary.nvim',
      'stevearc/dressing.nvim',
      'nvim-neotest/nvim-nio',
    },
    config = function()
      local home_dir = vim.fn.expand("$HOME")
      local flutter_dir = home_dir .. "/flutter"
      local flutter_bin_dir = flutter_dir .. "/bin"
      local flutter_bin = flutter_bin_dir .. "/flutter"
      local dart_sdk = flutter_dir .. "/bin/cache/dart-sdk"
      local dart_bin = dart_sdk .. "/bin/dart"

      if vim.fn.filereadable(flutter_bin) == 1 then

        -- Add Flutter to PATH for this session if not already there
        if vim.fn.exepath('flutter') == "" then
          vim.env.PATH = vim.env.PATH .. ":" .. flutter_bin_dir
          vim.notify("Added Flutter to PATH for this session: " .. flutter_bin_dir, vim.log.levels.INFO)
        end

        if vim.fn.isdirectory(dart_sdk) ~= 1 then
          vim.notify("Dart SDK not found at " .. dart_sdk .. ". Some features may not work correctly.", vim.log.levels.WARN)
        end
      else
        vim.notify("Flutter not found at " .. flutter_bin .. ". Some features may not work correctly.", vim.log.levels.WARN)
      end

      local home_dir = vim.fn.expand("$HOME")
      local flutter_bin = home_dir .. "/flutter/bin/flutter"

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
      require("simulators").setup({
        android_emulator = true,
        apple_simulator = false,
        android_emulator_path = vim.fn.executable("emulator") == 1 and "emulator" or "/opt/android-sdk/emulator/emulator",
      })

      require("telescope").load_extension("simulators")
      vim.schedule(function()
        require("sevilzww.mappings.telescope").setup()
      end)


      vim.api.nvim_create_user_command("ListAVDs", function()
        vim.cmd("terminal avdmanager list avd")
      end, { desc = "List available Android Virtual Devices" })
    end,
  },
}
