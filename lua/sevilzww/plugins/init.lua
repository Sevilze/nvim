-- Main plugins file
return {
  -- Import all plugin specs from separate files
  { import = "sevilzww.plugins.ui" },
  { import = "sevilzww.plugins.editor" },
  { import = "sevilzww.plugins.coding" },
  { import = "sevilzww.plugins.lsp" },
  { import = "sevilzww.plugins.rust" },
  { import = "sevilzww.plugins.debug" },
  { import = "sevilzww.plugins.tmux" },
}
