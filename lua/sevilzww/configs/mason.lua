local M = {}

-- List of packages to ensure are installed
M.ensure_installed = {
  -- LSP
  "lua-language-server",
  "pyright",
  "clangd",
  "rust-analyzer",
  "typescript-language-server",
  "jdtls",
  "json-lsp",
  "html-lsp",
  "css-lsp",
  "dart-debug-adapter",    -- Flutter/Dart

  -- DAP
  "codelldb",
  "debugpy",

  -- Linters
  "eslint_d",
  "flake8",
  "shellcheck",

  -- Formatters
  "stylua",                -- Lua
  "black",                 -- Python
  "isort",                 -- Python imports
  "prettier",              -- JavaScript, TypeScript, HTML, CSS, JSON, etc.
  "clang-format",          -- C/C++
  "rustfmt",               -- Rust
  "google-java-format",    -- Java
  "shfmt",                 -- Shell scripts
}

M.auto_install = true
M.max_concurrent_installers = 4
M.ui = {
  icons = {
    package_installed = "✓",
    package_pending = "➜",
    package_uninstalled = "✗"
  },
  keymaps = {
    toggle_package_expand = "<CR>",
    install_package = "i",
    update_package = "u",
    check_package_version = "c",
    update_all_packages = "U",
    check_outdated_packages = "C",
    uninstall_package = "X",
  },
}

return M
