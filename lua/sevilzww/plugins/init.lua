-- Main plugins file
return {
  -- Import all plugin specs from separate files
  { import = "sevilzww.plugins.ui" },
  { import = "sevilzww.plugins.editor" },
  { import = "sevilzww.plugins.coding" },
  { import = "sevilzww.plugins.lsp" },
  -- Mason plugins are now defined in core/mason.lua
  require("sevilzww.core.mason").plugins,
  { import = "sevilzww.plugins.rust" },
  { import = "sevilzww.plugins.flutter" },
  { import = "sevilzww.plugins.debug" },
  { import = "sevilzww.plugins.tmux" },
  { import = "sevilzww.plugins.autosave" },
}
