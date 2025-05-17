return {
    {
      "benlubas/molten-nvim",
      version = "^1.0.0",
      dependencies = {
        "3rd/image.nvim",
        "zbirenbaum/neodim",
      },
      build = ":UpdateRemotePlugins",
      init = function()
        vim.g.molten_auto_open_output = false
        vim.g.molten_image_provider = "image.nvim"
        vim.g.molten_output_win_max_height = 20
        vim.g.molten_output_win_cover_gutter = true
        vim.g.molten_virt_text_output = true
        vim.g.molten_virt_lines_off_by_1 = true
        vim.g.molten_wrap_output = true
        vim.g.molten_copy_output = true
        vim.g.molten_output_crop_border = true
        vim.g.molten_output_show_more = true
        vim.g.molten_output_win_style = "minimal"
      end,
      ft = {
        "python",
      },
      config = function()
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
            neorg = {
              enabled = true,
              clear_in_insert_mode = false,
              download_remote_images = true,
              only_render_image_at_cursor = false,
              filetypes = { "norg" },
            },
          },
          max_width = nil,
          max_height = nil,
          max_width_window_percentage = nil,
          max_height_window_percentage = 50,
          window_overlap_clear_enabled = false,
          window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
          editor_only_render_when_focused = false,
          tmux_show_only_in_active_window = false,
          hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" },
        }
  
        require("image").setup(image_options)
  
        vim.api.nvim_set_hl(0, "MoltenOutputBorder", { link = "FloatBorder" })
        vim.api.nvim_set_hl(0, "MoltenOutputBorderFail", { link = "DiagnosticError" })
  
      end,
    },
    
    {
      "3rd/image.nvim",
      opts = {
        backend = "kitty",
        integrations = {
          markdown = {
            enabled = true,
          },
        },
        max_height_window_percentage = 50,
        max_width_window_percentage = 50,
      },
    },
    
    {
      "zbirenbaum/neodim",
      event = "LspAttach",
      opts = {
        alpha = 0.5,
        hide = {
          underline = true,
          virtual_text = true,
          signs = true,
        },
      },
    },
  }
