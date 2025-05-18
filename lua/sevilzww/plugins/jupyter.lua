return {
    {
      "benlubas/molten-nvim",
      version = "^1.0.0",
      dependencies = {
        "3rd/image.nvim",
        "zbirenbaum/neodim",
      },
      build = ":UpdateRemotePlugins",
      -- Load the plugin immediately instead of only on Python files
      lazy = false,
      init = function()
        -- Recommended molten settings for notebook experience
        vim.g.molten_image_provider = "image.nvim"
        vim.g.molten_output_win_max_height = 20
        vim.g.molten_auto_open_output = false
        vim.g.molten_wrap_output = true
        vim.g.molten_virt_text_output = true
        vim.g.molten_virt_lines_off_by_1 = true

        -- Ensure UpdateRemotePlugins is run when Neovim starts
        vim.api.nvim_create_autocmd("VimEnter", {
          callback = function()
            vim.cmd("UpdateRemotePlugins")
          end,
          once = true,
        })
      end,
      config = function()
        require("sevilzww.mappings.jupyter").setup()
        local image_options = {
          backend = "kitty",
          integrations = {
            markdown = {
              enabled = true,
              clear_in_insert_mode = false,
              download_remote_images = true,
              only_render_image_at_cursor = false,
              filetypes = { "markdown", "vimwiki" },
            },
          },
          max_width = 100,
          max_height = 12,
          max_height_window_percentage = math.huge,
          max_width_window_percentage = math.huge,
          window_overlap_clear_enabled = true,
          window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
        }
        require("image").setup(image_options)

        vim.api.nvim_set_hl(0, "MoltenOutputBorder", { link = "FloatBorder" })
        vim.api.nvim_set_hl(0, "MoltenOutputBorderFail", { link = "DiagnosticError" })

        -- Create a command to manually register molten-nvim commands if needed
        vim.api.nvim_create_user_command("MoltenRegister", function()
          vim.cmd("UpdateRemotePlugins")
          vim.notify("Molten commands registered. Please restart Neovim.", vim.log.levels.INFO)
        end, { desc = "Register Molten commands" })

        -- Automatically import/export output chunks for ipynb files
        -- automatically import output chunks from a jupyter notebook
        local imb = function(e) -- init molten buffer
          vim.schedule(function()
            local kernels = vim.fn.MoltenAvailableKernels()
            local try_kernel_name = function()
              local metadata = vim.json.decode(io.open(e.file, "r"):read("a"))["metadata"]
              return metadata.kernelspec.name
            end
            local ok, kernel_name = pcall(try_kernel_name)
            if not ok or not vim.tbl_contains(kernels, kernel_name) then
              kernel_name = nil
              local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
              if venv ~= nil then
                kernel_name = string.match(venv, "/.+/(.+)")
              end
            end
            if kernel_name ~= nil and vim.tbl_contains(kernels, kernel_name) then
              vim.cmd(("MoltenInit %s"):format(kernel_name))
            end
            vim.cmd("MoltenImportOutput")
          end)
        end

        -- automatically import output chunks from a jupyter notebook
        vim.api.nvim_create_autocmd("BufAdd", {
          pattern = { "*.ipynb" },
          callback = function(e)
            -- Set buffer-local variable to disable jupytext conversion
            vim.api.nvim_buf_set_var(e.buf, "jupytext_disable", true)
            imb(e)
          end,
        })

        -- catch files opened like nvim ./hi.ipynb
        vim.api.nvim_create_autocmd("BufEnter", {
          pattern = { "*.ipynb" },
          callback = function(e)
            -- Set buffer-local variable to disable jupytext conversion
            vim.api.nvim_buf_set_var(e.buf, "jupytext_disable", true)

            if vim.api.nvim_get_vvar("vim_did_enter") ~= 1 then
              imb(e)
            end
          end,
        })

        -- automatically export output chunks to a jupyter notebook on write
        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern = { "*.ipynb" },
          callback = function(e)
            -- Ensure jupytext doesn't try to convert this file
            vim.api.nvim_buf_set_var(e.buf, "jupytext_disable", true)

            if require("molten.status").initialized() == "Molten" then
              vim.cmd("MoltenExportOutput!")
            end
          end,
        })

        -- Change Molten settings based on filetype
        -- change the configuration when editing a python file
        vim.api.nvim_create_autocmd("BufEnter", {
          pattern = "*.py",
          callback = function(e)
            if string.match(e.file, ".otter.") then
              return
            end
            if require("molten.status").initialized() == "Molten" then
              vim.fn.MoltenUpdateOption("virt_lines_off_by_1", false)
              vim.fn.MoltenUpdateOption("virt_text_output", false)
            else
              vim.g.molten_virt_lines_off_by_1 = false
              vim.g.molten_virt_text_output = false
            end
          end,
        })

        -- Undo those config changes when we go back to a markdown or quarto file
        vim.api.nvim_create_autocmd("BufEnter", {
          pattern = { "*.qmd", "*.md", "*.ipynb" },
          callback = function(e)
            if string.match(e.file, ".otter.") then
              return
            end
            if require("molten.status").initialized() == "Molten" then
              vim.fn.MoltenUpdateOption("virt_lines_off_by_1", true)
              vim.fn.MoltenUpdateOption("virt_text_output", true)
            else
              vim.g.molten_virt_lines_off_by_1 = true
              vim.g.molten_virt_text_output = true
            end
          end,
        })

        -- Provide a command to create a blank new Python notebook
        local default_notebook = [[
          {
            "cells": [
             {
              "cell_type": "markdown",
              "metadata": {},
              "source": [
                ""
              ]
             }
            ],
            "metadata": {
             "kernelspec": {
              "display_name": "Python 3",
              "language": "python",
              "name": "python3"
             },
             "language_info": {
              "codemirror_mode": {
                "name": "ipython"
              },
              "file_extension": ".py",
              "mimetype": "text/x-python",
              "name": "python",
              "nbconvert_exporter": "python",
              "pygments_lexer": "ipython3"
             }
            },
            "nbformat": 4,
            "nbformat_minor": 5
          }
        ]]

        local function new_notebook(filename)
          local path = filename .. ".ipynb"
          local file = io.open(path, "w")
          if file then
            file:write(default_notebook)
            file:close()
            vim.cmd("edit " .. path)
          else
            print("Error: Could not open new notebook file for writing.")
          end
        end

        vim.api.nvim_create_user_command('NewNotebook', function(opts)
          new_notebook(opts.args)
        end, {
          nargs = 1,
          complete = 'file'
        })
      end,
    },

    {
      "3rd/image.nvim",
      opts = {
        backend = "kitty",
        max_width = 100,
        max_height = 12,
        max_height_window_percentage = math.huge,
        max_width_window_percentage = math.huge,
        window_overlap_clear_enabled = true,
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      },
    },

    {
      "zbirenbaum/neodim",
      event = "LspAttach",
      opts = {
        alpha = 0.5,
        hide = {
          -- Don't hide diagnostics for ipynb files
          underline = function()
            return vim.fn.expand("%:e") ~= "ipynb"
          end,
          virtual_text = function()
            return vim.fn.expand("%:e") ~= "ipynb"
          end,
          signs = function()
            return vim.fn.expand("%:e") ~= "ipynb"
          end,
        },
      },
    },

    -- Jupytext for converting between ipynb and markdown
    {
      "GCBallesteros/jupytext.nvim",
      lazy = false,
      config = function()
        -- Check if jupytext is installed
        local jupytext_installed = vim.fn.executable("jupytext") == 1

        if not jupytext_installed then
          -- Notify the user
          vim.notify("Installing jupytext Python package...", vim.log.levels.INFO)

          -- Try to install jupytext
          local install_cmd = "pip install jupytext"
          local result = vim.fn.system(install_cmd)

          if vim.v.shell_error ~= 0 then
            -- Try with pip3 if pip fails
            install_cmd = "pip3 install jupytext"
            result = vim.fn.system(install_cmd)

            if vim.v.shell_error ~= 0 then
              vim.notify("Failed to install jupytext. Please install it manually with 'pip install jupytext'", vim.log.levels.ERROR)
              return
            end
          end

          vim.notify("jupytext installed successfully!", vim.log.levels.INFO)
        end

        require("jupytext").setup({
          -- Completely disable automatic conversion
          auto_convert_on_open = false,
          convert_on_save = false,
          -- These settings are only used for manual conversion if needed
          style = "markdown",
          output_extension = "md",
          force_ft = "markdown",
        })

        -- Create custom commands for manual conversion
        vim.api.nvim_create_user_command("JupytextToMarkdown", function()
          -- Get current file path
          local current_file = vim.fn.expand("%:p")

          -- Check if it's an ipynb file
          if vim.fn.fnamemodify(current_file, ":e") ~= "ipynb" then
            vim.notify("Current file is not an ipynb file.", vim.log.levels.WARN)
            return
          end

          -- Generate output file path
          local output_file = vim.fn.fnamemodify(current_file, ":r") .. ".md"

          -- Run jupytext to convert
          local cmd = "jupytext --to markdown " .. vim.fn.shellescape(current_file) .. " -o " .. vim.fn.shellescape(output_file)
          local result = vim.fn.system(cmd)

          if vim.v.shell_error ~= 0 then
            vim.notify("Failed to convert to markdown: " .. result, vim.log.levels.ERROR)
          else
            vim.notify("Successfully converted to " .. output_file, vim.log.levels.INFO)

            -- Ask if user wants to open the converted file
            if vim.fn.confirm("Open the converted markdown file?", "&Yes\n&No", 1) == 1 then
              vim.cmd("edit " .. vim.fn.fnameescape(output_file))
            end
          end
        end, {})

        vim.api.nvim_create_user_command("JupytextToNotebook", function()
          -- Get current file path
          local current_file = vim.fn.expand("%:p")

          -- Check if it's a markdown file
          if vim.fn.fnamemodify(current_file, ":e") ~= "md" then
            vim.notify("Current file is not a markdown file.", vim.log.levels.WARN)
            return
          end

          -- Generate output file path
          local output_file = vim.fn.fnamemodify(current_file, ":r") .. ".ipynb"

          -- Run jupytext to convert
          local cmd = "jupytext --to notebook " .. vim.fn.shellescape(current_file) .. " -o " .. vim.fn.shellescape(output_file)
          local result = vim.fn.system(cmd)

          if vim.v.shell_error ~= 0 then
            vim.notify("Failed to convert to notebook: " .. result, vim.log.levels.ERROR)
          else
            vim.notify("Successfully converted to " .. output_file, vim.log.levels.INFO)

            -- Ask if user wants to open the converted file
            if vim.fn.confirm("Open the converted notebook file?", "&Yes\n&No", 1) == 1 then
              vim.cmd("edit " .. vim.fn.fnameescape(output_file))
            end
          end
        end, {})
      end,
    },

    -- Treesitter text objects for code cells
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      dependencies = { "nvim-treesitter/nvim-treesitter" },
      config = function()
        require("nvim-treesitter.configs").setup({
          textobjects = {
            move = {
              enable = true,
              set_jumps = false,
              goto_next_start = {
                ["]b"] = { query = "@code_cell.inner", desc = "next code block" },
              },
              goto_previous_start = {
                ["[b"] = { query = "@code_cell.inner", desc = "previous code block" },
              },
            },
            select = {
              enable = true,
              lookahead = true,
              keymaps = {
                ["ib"] = { query = "@code_cell.inner", desc = "in block" },
                ["ab"] = { query = "@code_cell.outer", desc = "around block" },
              },
            },
            swap = {
              enable = true,
              swap_next = {
                ["<leader>sbl"] = "@code_cell.outer",
              },
              swap_previous = {
                ["<leader>sbh"] = "@code_cell.outer",
              },
            },
          }
        })
      end,
    },

    -- Quarto for LSP features in markdown code cells
    {
      "quarto-dev/quarto-nvim",
      ft = { "quarto", "markdown" },
      dependencies = {
        "jmbuhr/otter.nvim",
        "hrsh7th/nvim-cmp",
        "neovim/nvim-lspconfig",
        "nvim-treesitter/nvim-treesitter",
      },
      config = function()
        require("quarto").setup({
          lspFeatures = {
            enabled = true,
            languages = { "python", "r", "julia" }, -- Support more languages
            diagnostics = {
              enabled = true,
              triggers = { "BufWrite", "CursorHold", "InsertLeave" }, -- More frequent diagnostics
            },
            completion = {
              enabled = true,
            },
          },
          codeRunner = {
            enabled = true,
            default_method = "molten", -- Use molten for code execution
            ft_runners = {
              python = "molten", -- Explicitly set Python to use molten
              markdown = "molten", -- Also use molten for markdown
              quarto = "molten", -- Also use molten for quarto
            },
            never_run_cells_with_warnings = false, -- Allow running cells with warnings
            -- Define markers for code cells to improve detection
            markers = {
              python = {
                -- More comprehensive pattern for Python code blocks
                chunk_start = "^```\\s*{?python.*}?\\s*$",
                chunk_end = "^```\\s*$",
              },
              markdown = {
                -- Also detect Python code blocks in markdown
                chunk_start = "^```\\s*{?python.*}?\\s*$",
                chunk_end = "^```\\s*$",
              },
              ipynb = {
                -- Also detect Python code blocks in ipynb
                chunk_start = "^```\\s*{?python.*}?\\s*$",
                chunk_end = "^```\\s*$",
              },
            },
            -- Ignore Jupytext headers and other non-code sections
            ignore_patterns = {
              -- Jupytext header pattern
              "^---\\s*$",
              "^jupyter:.*$",
              "^  jupytext:.*$",
              "^    text_representation:.*$",
              "^      extension:.*$",
              "^      format_name:.*$",
              "^      format_version:.*$",
              "^      jupytext_version:.*$",
              "^  kernelspec:.*$",
              "^    display_name:.*$",
              "^    language:.*$",
              "^    name:.*$",
            },
          },
          keymap = {
            hover = "K",
            definition = "gd",
            type_definition = "gD",
            rename = "<leader>rn",
            format = "<leader>fm",
            references = "gr",
            document_symbols = "gS",
          },
        })

        -- Register .ipynb files as markdown for better handling
        vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
          pattern = "*.ipynb",
          callback = function(e)
            -- Set filetype to markdown for better handling
            vim.bo.filetype = "markdown"

            -- Ensure jupytext doesn't try to convert this file
            vim.api.nvim_buf_set_var(e.buf, "jupytext_disable", true)

            -- Initialize Molten if not already initialized
            vim.schedule(function()
              if require("molten.status").initialized() ~= "Molten" then
                -- Try to initialize with python3 kernel
                vim.cmd("MoltenInit python3")

                -- Import outputs after a short delay to ensure kernel is ready
                vim.defer_fn(function()
                  if require("molten.status").initialized() == "Molten" then
                    vim.cmd("MoltenImportOutput")
                  end
                end, 1000)
              end
            end)
          end,
        })

        -- Configure otter.nvim for better LSP integration in markdown code blocks
        require("otter").setup({
          lsp = {
            hover = {
              border = "rounded",
            },
            diagnostics = {
              enabled = true,
              virtual_text = true,
              signs = true,
              underline = true,
              severity_sort = true,
              update_in_insert = true, -- Update diagnostics in insert mode
            },
            code_lens = {
              enabled = true,
            },
            -- Explicitly configure language servers for code blocks
            server = {
              python = {
                -- Use pyright for Python code blocks
                name = "pyright",
                settings = {
                  python = {
                    analysis = {
                      typeCheckingMode = "basic",
                      diagnosticSeverityOverrides = {
                        reportUnusedExpression = "none", -- Disable unused expression warnings
                      },
                      -- Enable all diagnostics for better linting
                      diagnosticMode = "workspace",
                      useLibraryCodeForTypes = true,
                      autoSearchPaths = true,
                    },
                  },
                },
              },
            },
          },
          buffers = {
            -- Set to false if you don't want otter to automatically attach to markdown buffers
            auto_attach = true,
            -- Specify filetypes to automatically attach to
            auto_attach_filetypes = { "markdown", "ipynb" },
          },
          handle_leading_whitespace = true, -- Remove leading whitespace from code blocks
          strip_markdown_code_block_delimiter = true, -- Strip the markdown code block delimiters
          -- Keymaps for navigating through code blocks
          keymaps = {
            -- Use <C-n> and <C-p> to navigate between code blocks
            next_chunk = "<C-n>",
            previous_chunk = "<C-p>",
          },
        })

        -- Create an ftplugin for markdown to activate quarto
        local ftplugin_dir = vim.fn.stdpath("config") .. "/ftplugin"
        if vim.fn.isdirectory(ftplugin_dir) == 0 then
          vim.fn.mkdir(ftplugin_dir, "p")
        end

        local md_ftplugin = ftplugin_dir .. "/markdown.lua"
        if vim.fn.filereadable(md_ftplugin) == 0 then
          local f = io.open(md_ftplugin, "w")
          if f then
            f:write('require("quarto").activate()')
            f:close()
          end
        end

        -- Create a command to initialize Jupyter notebook environment
        vim.api.nvim_create_user_command("JupyterInit", function()
          -- Initialize Molten with Python kernel
          vim.cmd("MoltenInit python3")

          -- Wait a bit to ensure Molten is initialized
          vim.defer_fn(function()
            -- Check if Molten is now initialized
            local molten_status_ok, molten_status = pcall(require, "molten.status")
            if molten_status_ok and molten_status.initialized() == "Molten" then
              vim.notify("Molten initialized successfully.", vim.log.levels.INFO)

              -- Import outputs if this is a notebook
              if vim.fn.expand("%:e") == "ipynb" then
                vim.cmd("MoltenImportOutput")
              end
            else
              vim.notify("Failed to initialize Molten. Try running :MoltenInit python3 manually.", vim.log.levels.WARN)
            end

            -- Activate Quarto for the current buffer
            local quarto_ok, quarto = pcall(require, "quarto")
            if quarto_ok then
              quarto.activate()
            else
              vim.notify("Quarto plugin not found. Some features may not work properly.", vim.log.levels.WARN)
            end

            -- Activate Otter for the current buffer
            local otter_ok, otter = pcall(require, "otter")
            if otter_ok then
              otter.activate({
                bufnr = vim.api.nvim_get_current_buf(),
                ft = "python"
              })

              -- Force enable diagnostics for this buffer
              vim.diagnostic.enable(vim.api.nvim_get_current_buf())
            else
              vim.notify("Otter plugin not found. LSP features in code blocks may not work properly.", vim.log.levels.WARN)
            end

            -- Ensure LSP is attached for Python
            local lspconfig = require("lspconfig")
            if lspconfig.pyright then
              -- Check if pyright is already attached
              local clients = vim.lsp.get_active_clients({bufnr = vim.api.nvim_get_current_buf()})
              local pyright_attached = false
              for _, client in ipairs(clients) do
                if client.name == "pyright" then
                  pyright_attached = true
                  break
                end
              end

              -- If not attached, try to attach it
              if not pyright_attached then
                vim.cmd("LspStart pyright")
              end
            end

            -- Show help message
            vim.notify("Jupyter environment fully initialized. Use <leader>jh for help.", vim.log.levels.INFO)
          end, 500)  -- Wait 500ms for Molten to initialize
        end, {})
      end,
    },
  }
