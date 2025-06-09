-- Rust related plugins (with rustaceanvim)
return {
  {
    'rust-lang/rust.vim',
    ft = "rust",
    init = function ()
      vim.g.rustfmt_autosave = 0
    end
  },

  {
    'saecki/crates.nvim',
    ft = {"toml"},
    config = function()
      require("crates").setup {
        completion = {
          cmp = {
            enabled = true
          },
        },
      }
      require('cmp').setup.buffer({
        sources = { { name = "crates" }}
      })
    end
  },

  {
    'mrcjkb/rustaceanvim',
    lazy = false,
    config = function ()
      local extension_path = "$HOME/.local/share/nvim/mason/packages/codelldb/extension/"
      local codelldb_path = extension_path .. "adapter/codelldb"
      local liblldb_path = extension_path.. "lldb/lib/liblldb.so"
      local cfg = require('rustaceanvim.config')

      vim.g.rustaceanvim = {
        server = {
          on_attach = function(client, bufnr)
            require("sevilzww.mappings.rust").setup_buffer(client, bufnr)
          end,
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = true,
              check = {
                command = "clippy",
                extraArgs = {
                  "--release",
                },
              },
              cargo = {
                loadOutDirsFromCheck = true,
              },
              procMacro = {
                enable = true,
              },
            },
          },
        },
        dap = {
          adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
        },
      }

      vim.api.nvim_create_user_command("RustRun", function()
        vim.cmd("terminal cargo run")
      end, { desc = "Run Rust program" })

      vim.api.nvim_create_user_command("RustTest", function()
        vim.cmd("terminal cargo test")
      end, { desc = "Run Rust tests" })

      vim.api.nvim_create_user_command("RustBuild", function()
        vim.cmd("terminal cargo build")
      end, { desc = "Build Rust program" })

      vim.api.nvim_create_user_command("RustCheck", function()
        vim.cmd("terminal cargo check")
      end, { desc = "Check Rust program" })

      vim.api.nvim_create_user_command("RustClippy", function()
        vim.cmd("terminal cargo clippy --workspace --all-targets --all-features")
      end, { desc = "Run clippy on Rust program" })

      vim.api.nvim_create_user_command("RustOpenCargo", function()
        local cargo_path = vim.fn.findfile("Cargo.toml", ".;")
        if cargo_path ~= "" then
          vim.cmd("edit " .. cargo_path)
        else
          vim.notify("Cargo.toml not found", vim.log.levels.ERROR)
        end
      end, { desc = "Open Cargo.toml" })

      vim.api.nvim_create_user_command("RustDebug", function()
        require('dap').continue()
      end, { desc = "Start debugging Rust program" })

      vim.api.nvim_create_user_command("RustDebugStop", function()
        require('dap').terminate()
      end, { desc = "Stop debugging Rust program" })
    end
  },
}
