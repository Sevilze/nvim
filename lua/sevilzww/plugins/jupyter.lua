return {
    {
      "benlubas/molten-nvim",
      version = "^1.0.0",
      dependencies = {
        "3rd/image.nvim",
        "zbirenbaum/neodim",
      },
      build = ":UpdateRemotePlugins",
      lazy = false,
      init = function()
        vim.g.molten_image_provider = "image.nvim"
        vim.g.molten_output_win_max_height = 20
        vim.g.molten_auto_open_output = false
        vim.g.molten_wrap_output = true
        vim.g.molten_virt_text_output = true
        vim.g.molten_virt_lines_off_by_1 = true

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

        vim.api.nvim_create_user_command("MoltenRegister", function()
          vim.cmd("UpdateRemotePlugins")
          vim.notify("Molten commands registered. Please restart Neovim.", vim.log.levels.INFO)
        end, { desc = "Register Molten commands" })

        local imb = function(e)
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

        vim.api.nvim_create_autocmd("BufAdd", {
          pattern = { "*.ipynb" },
          callback = function(e)
            vim.api.nvim_buf_set_var(e.buf, "jupytext_disable", true)
            imb(e)
          end,
        })

        vim.api.nvim_create_autocmd("BufEnter", {
          pattern = { "*.ipynb" },
          callback = function(e)
            vim.api.nvim_buf_set_var(e.buf, "jupytext_disable", true)

            if vim.api.nvim_get_vvar("vim_did_enter") ~= 1 then
              imb(e)
            end
          end,
        })

        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern = { "*.ipynb" },
          callback = function(e)
            vim.api.nvim_buf_set_var(e.buf, "jupytext_disable", true)

            if require("molten.status").initialized() == "Molten" then
              vim.cmd("MoltenExportOutput!")
            end
          end,
        })

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

    {
      "GCBallesteros/jupytext.nvim",
      lazy = false,
      config = function()
        local jupytext_installed = vim.fn.executable("jupytext") == 1

        if not jupytext_installed then
          vim.notify("Installing jupytext Python package...", vim.log.levels.INFO)

          local install_cmd = "pip install jupytext"
          local result = vim.fn.system(install_cmd)

          if vim.v.shell_error ~= 0 then
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
          auto_convert_on_open = false,
          convert_on_save = false,
          style = "markdown",
          output_extension = "md",
          force_ft = "markdown",
        })

        vim.api.nvim_create_user_command("JupytextToMarkdown", function()
          local current_file = vim.fn.expand("%:p")

          if vim.fn.fnamemodify(current_file, ":e") ~= "ipynb" then
            vim.notify("Current file is not an ipynb file.", vim.log.levels.WARN)
            return
          end

          local output_file = vim.fn.fnamemodify(current_file, ":r") .. ".md"
          local cmd = "jupytext --to markdown " .. vim.fn.shellescape(current_file) .. " -o " .. vim.fn.shellescape(output_file)
          local result = vim.fn.system(cmd)

          if vim.v.shell_error ~= 0 then
            vim.notify("Failed to convert to markdown: " .. result, vim.log.levels.ERROR)
          else
            vim.notify("Successfully converted to " .. output_file, vim.log.levels.INFO)
            if vim.fn.confirm("Open the converted markdown file?", "&Yes\n&No", 1) == 1 then
              vim.cmd("edit " .. vim.fn.fnameescape(output_file))
            end
          end
        end, {})

        vim.api.nvim_create_user_command("JupytextToNotebook", function()
          local current_file = vim.fn.expand("%:p")

          if vim.fn.fnamemodify(current_file, ":e") ~= "md" then
            vim.notify("Current file is not a markdown file.", vim.log.levels.WARN)
            return
          end

          local output_file = vim.fn.fnamemodify(current_file, ":r") .. ".ipynb"
          local cmd = "jupytext --to notebook " .. vim.fn.shellescape(current_file) .. " -o " .. vim.fn.shellescape(output_file)
          local result = vim.fn.system(cmd)

          if vim.v.shell_error ~= 0 then
            vim.notify("Failed to convert to notebook: " .. result, vim.log.levels.ERROR)
          else
            vim.notify("Successfully converted to " .. output_file, vim.log.levels.INFO)

            if vim.fn.confirm("Open the converted notebook file?", "&Yes\n&No", 1) == 1 then
              vim.cmd("edit " .. vim.fn.fnameescape(output_file))
            end
          end
        end, {})
      end,
    },

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
            languages = { "python", "r", "julia" },
            diagnostics = {
              enabled = true,
              triggers = { "BufWrite", "CursorHold", "InsertLeave" },
            },
            completion = {
              enabled = true,
            },
          },
          codeRunner = {
            enabled = true,
            default_method = "molten",
            ft_runners = {
              python = "molten",
              markdown = "molten",
              quarto = "molten",
            },
            never_run_cells_with_warnings = false,
            markers = {
              python = {
                chunk_start = "^```\\s*{?python.*}?\\s*$",
                chunk_end = "^```\\s*$",
              },
              markdown = {
                chunk_start = "^```\\s*{?python.*}?\\s*$",
                chunk_end = "^```\\s*$",
              },
              ipynb = {
                chunk_start = "^```\\s*{?python.*}?\\s*$",
                chunk_end = "^```\\s*$",
              },
            },
            ignore_patterns = {
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

        vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
          pattern = "*.ipynb",
          callback = function(e)
            vim.bo.filetype = "ipynb"
            vim.api.nvim_buf_set_var(e.buf, "jupytext_disable", true)

            vim.schedule(function()
              local molten_status_ok, molten_status = pcall(require, "molten.status")
              if molten_status_ok and molten_status.initialized() ~= "Molten" then
                vim.cmd("MoltenInit python3")

                vim.defer_fn(function()
                  if require("molten.status").initialized() == "Molten" then
                    vim.cmd("MoltenImportOutput")
                  end
                end, 1000)
              end
            end)
          end,
        })

        require("otter").setup({
          lsp = {
            hover = {
              border = "rounded",
            },
            diagnostics = {
              enabled = true,
              virtual_text = {
                enabled = true,
                prefix = "●",
                source = "if_many",
              },
              signs = true,
              underline = true,
              severity_sort = true,
              update_in_insert = false,
              float = {
                enabled = true,
                border = "rounded",
                source = "always",
              },
            },
            code_lens = {
              enabled = true,
            },
            server = {
              python = {
                name = "pyright",
                settings = {
                  python = {
                    analysis = {
                      typeCheckingMode = "basic",
                      diagnosticMode = "workspace",
                      useLibraryCodeForTypes = true,
                      autoSearchPaths = true,
                      autoImportCompletions = true,
                    },
                  },
                },
              },
            },
          },
          buffers = {
            auto_attach = true,
            auto_attach_filetypes = { "markdown", "ipynb" },
            set_filetype = true,
          },
          handle_leading_whitespace = true,
          strip_markdown_code_block_delimiter = true,
          keymaps = {
            next_chunk = "<C-n>",
            previous_chunk = "<C-p>",
          },
          verbose = {
            enabled = false,
          },
        })

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

        vim.api.nvim_create_user_command("JupyterInit", function()
          vim.cmd("MoltenInit python3")

          vim.defer_fn(function()
            local molten_status_ok, molten_status = pcall(require, "molten.status")
            if molten_status_ok and molten_status.initialized() == "Molten" then
              vim.notify("Molten initialized successfully.", vim.log.levels.INFO)

              if vim.fn.expand("%:e") == "ipynb" then
                vim.cmd("MoltenImportOutput")
              end
            else
              vim.notify("Failed to initialize Molten. Try running :MoltenInit python3 manually.", vim.log.levels.WARN)
            end

            local quarto_ok, quarto = pcall(require, "quarto")
            if quarto_ok then
              quarto.activate()
            else
              vim.notify("Quarto plugin not found. Some features may not work properly.", vim.log.levels.WARN)
            end

            local otter_ok, otter = pcall(require, "otter")
            if otter_ok then
              otter.activate({
                bufnr = vim.api.nvim_get_current_buf(),
                ft = "python"
              })

              vim.diagnostic.enable(vim.api.nvim_get_current_buf())
            else
              vim.notify("Otter plugin not found. LSP features in code blocks may not work properly.", vim.log.levels.WARN)
            end

            local lspconfig = require("lspconfig")
            if lspconfig.pyright then
              local clients = vim.lsp.get_active_clients({bufnr = vim.api.nvim_get_current_buf()})
              local pyright_attached = false
              for _, client in ipairs(clients) do
                if client.name == "pyright" then
                  pyright_attached = true
                  break
                end
              end

              if not pyright_attached then
                vim.cmd("LspStart pyright")
              end
            end

            vim.notify("Jupyter environment fully initialized. Use <leader>jh for help.", vim.log.levels.INFO)
          end, 500)
        end, {})
      end,
    },
  }
