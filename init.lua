-- Neovim configuration entry point
vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- Load the core configuration
require("sevilzww.core.lazy").setup()
require "nvchad.autocmds"

-- Schedule mappings and options to be loaded after everything else
vim.schedule(function()
  require "sevilzww.core.mappings"

  vim.defer_fn(function()
    require "sevilzww.core.options"
    vim.opt.number = true
    vim.opt.relativenumber = true
  end, 10)
end)
