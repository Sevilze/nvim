local M = {}

M.formatters_by_ft = {
  -- Lua
  lua = { "stylua" },
  
  -- Web development
  html = { "prettier" },
  css = { "prettier" },
  javascript = { "prettier" },
  typescript = { "prettier" },
  javascriptreact = { "prettier" },
  typescriptreact = { "prettier" },
  json = { "prettier" },
  yaml = { "prettier" },
  markdown = { "prettier" },
  
  -- Python
  python = { "black", "isort" },
  
  -- C/C++
  c = { "clang_format" },
  cpp = { "clang_format" },
  
  -- Rust
  rust = { "rustfmt" },
  
  -- Dart
  dart = { "dart_format" },
  
  -- Java
  java = { "google_java_format" },
  
  -- Shell
  sh = { "shfmt" },
  bash = { "shfmt" },
}

M.format_on_save = false

M.format_options = {
  async = false,
  quiet = false,
  lsp_fallback = true,
  timeout_ms = 4000,
}

M.format_on_buffer_leave = {
  enabled = true,
  timeout_ms = 4000,
  lsp_fallback = true,
  notify = true,
}

M.format_on_refactor = {
  enabled = true,
  timeout_ms = 4000,
  lsp_fallback = true,
  notify = true,
}

M.notify_on_format = true

return M
