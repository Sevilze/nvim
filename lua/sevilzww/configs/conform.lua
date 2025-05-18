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
  
  ["*"] = { "trim_whitespace", "trim_newlines" },
}

M.format_on_save = {
  timeout_ms = 1000,
  lsp_fallback = true,
}

M.format_options = {
  async = false,
  quiet = false,
  lsp_fallback = true,
}

M.notify_on_format = true

return M
