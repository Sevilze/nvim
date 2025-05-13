-- LSP related plugins
return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local nvchad_lsp = require("nvchad.configs.lspconfig")
      dofile(vim.g.base46_cache .. "lsp")
      require("nvchad.lsp").diagnostic_config()

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          nvchad_lsp.on_attach(_, args.buf)
        end,
      })

      local lspconfig = require "lspconfig"

      -- Main language servers
      local servers = {
        "html", "cssls",           -- Web
        "pyright",                 -- Python
        "clangd",                  -- C/C++
        "ts_ls",                   -- TypeScript/JavaScript
        "jdtls",                   -- Java
        "jsonls",                  -- JSON
        "lua_ls"                   -- Lua
      }
      local nvlsp = require "nvchad.configs.lspconfig"

      -- Create a custom on_attach function that extends the NvChad one
      local custom_on_attach = function(client, bufnr)
        nvlsp.on_attach(client, bufnr)
      end

      -- lsps with default config
      for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup {
          on_attach = custom_on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
        }
      end

      -- Python (pyright) configuration
      pcall(function()
        lspconfig.pyright.setup {
          on_attach = custom_on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        }
      end)

      -- C/C++ (clangd) configuration
      pcall(function()
        lspconfig.clangd.setup {
          on_attach = custom_on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
          cmd = {
            "clangd",
            "--background-index",
            "--suggest-missing-includes",
            "--clang-tidy",
            "--header-insertion=iwyu",
          },
        }
      end)

      -- TypeScript/JavaScript (ts_ls) configuration
      pcall(function()
        lspconfig.ts_ls.setup {
          on_attach = custom_on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        }
      end)

      -- Java (jdtls) configuration
      pcall(function()
        lspconfig.jdtls.setup {
          on_attach = custom_on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
        }
      end)

      -- Lua (lua_ls) configuration
      pcall(function()
        local mason_path = vim.fn.stdpath("data") .. "/mason"
        local lua_ls_path = mason_path .. "/packages/lua-language-server"
        local lua_ls_binary = lua_ls_path .. "/lua-language-server"

        lspconfig.lua_ls.setup {
          on_attach = custom_on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
          cmd = { lua_ls_binary, "-E", lua_ls_path .. "/libexec/main.lua" },
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                library = {
                  [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                  [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
                  [vim.fn.stdpath("data") .. "/lazy/ui/nvchad_types"] = true,
                  [vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
                },
                maxPreload = 100000,
                preloadFileSize = 10000,
              },
            },
          },
        }
      end)

      pcall(function()
        local home_dir = vim.fn.expand("$HOME")
        local flutter_dir = home_dir .. "/flutter"
        local dart_sdk = flutter_dir .. "/bin/cache/dart-sdk"
        local dart_bin = dart_sdk .. "/bin/dart"

        if vim.fn.filereadable(dart_bin) == 1 then
          vim.fn.system("chmod +x " .. dart_bin)

          lspconfig.dartls.setup {
            on_attach = custom_on_attach,
            on_init = nvlsp.on_init,
            capabilities = nvlsp.capabilities,
            cmd = { dart_bin, "language-server", "--protocol=lsp" },
            init_options = {
              onlyAnalyzeProjectsWithOpenFiles = true,
              suggestFromUnimportedLibraries = true,
              closingLabels = true,
              outline = true,
              flutterOutline = true,
            },
            settings = {
              dart = {
                completeFunctionCalls = true,
                showTodos = true,
                lineLength = 100,
                enableSdkFormatter = true,
                updateImportsOnRename = true,
                renameFilesWithClasses = "prompt",
                analysisExcludedFolders = {
                  vim.fn.expand("$HOME/flutter/packages"),
                  vim.fn.expand("$HOME/.pub-cache"),
                },
              },
            },
          }

          vim.api.nvim_create_user_command("DartLspRestart", function()
            local clients = vim.lsp.get_clients({ name = "dartls" })
            for _, client in ipairs(clients) do
              vim.lsp.stop_client(client.id, true)
            end

            vim.schedule(function()
              vim.cmd("edit")
              vim.notify("Dart LSP restarted", vim.log.levels.INFO)
            end)
          end, { desc = "Restart the Dart LSP" })
        else
          vim.notify("Dart SDK not found at " .. dart_bin .. ". LSP features for Dart/Flutter won't work.", vim.log.levels.WARN)
        end
      end)

      -- Set up auto-refresh for diagnostic list
      local diagnostic_list_open = false
      local diagnostic_list_bufnr = nil
      local diagnostic_list_winnr = nil
      local auto_refresh_enabled = true

      local function is_diagnostic_list_open()
        if diagnostic_list_bufnr and vim.api.nvim_buf_is_valid(diagnostic_list_bufnr) then
          local wins = vim.fn.win_findbuf(diagnostic_list_bufnr)
          if #wins > 0 then
            diagnostic_list_winnr = wins[1]
            return true
          end
        end
        return false
      end

      local function refresh_diagnostic_list()
        if auto_refresh_enabled and is_diagnostic_list_open() then
          vim.diagnostic.setloclist({ open = false })
        end
      end

      -- Create autocmd to track when the diagnostic list is opened
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function(args)
          local buf = args.buf
          local is_loclist = vim.fn.getloclist(0, { filewinid = 0 }).filewinid ~= 0

          if is_loclist then
            local items = vim.fn.getloclist(0)
            -- Safely check if this is a diagnostic list
            if #items > 0 and items[1] and (items[1].type == "E" or items[1].type == "W") then
              diagnostic_list_bufnr = buf
              diagnostic_list_open = true

              -- Set up autocmd to detect when the list is closed
              vim.api.nvim_create_autocmd("BufWipeout", {
                buffer = buf,
                once = true,
                callback = function()
                  diagnostic_list_open = false
                  diagnostic_list_bufnr = nil
                  diagnostic_list_winnr = nil
                end,
              })
            end
          end
        end,
      })

      -- Create autocmd to refresh the diagnostic list when diagnostics change
      local diagnostic_refresh_augroup = vim.api.nvim_create_augroup("DiagnosticListRefresh", { clear = true })
      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        group = diagnostic_refresh_augroup,
        callback = function()
          vim.schedule(refresh_diagnostic_list)
        end,
      })
    end,
  },
}
