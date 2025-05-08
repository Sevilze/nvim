-- Mason configuration and commands
local function setup_commands()
  vim.api.nvim_create_user_command("InstallLanguageServers", function()
    local ensure_installed = require("sevilzww.configs.mason").ensure_installed
    vim.cmd("MasonInstall " .. table.concat(ensure_installed, " "))
    vim.notify("Installing " .. #ensure_installed .. " packages...", vim.log.levels.INFO)
  end, { desc = "Install all configured language servers" })

  vim.api.nvim_create_user_command("MasonStatus", function()
    local ok, mason_registry = pcall(require, "mason-registry")
    if not ok then
      vim.notify("Mason registry not available yet. Try again after Mason is loaded.", vim.log.levels.WARN)
      return
    end
    
    local installed_pkgs = mason_registry.get_installed_packages()
    local ensure_installed = require("sevilzww.configs.mason").ensure_installed
    
    local installed_lookup = {}
    for _, pkg in ipairs(installed_pkgs) do
      installed_lookup[pkg.name] = true
    end
    
    -- Check which packages are missing
    local missing_pkgs = {}
    for _, pkg_name in ipairs(ensure_installed) do
      if not installed_lookup[pkg_name] then
        table.insert(missing_pkgs, pkg_name)
      end
    end
    
    -- Display status
    local status = "Mason Status:\n"
    status = status .. "  Installed: " .. #installed_pkgs .. " packages\n"
    status = status .. "  Configured: " .. #ensure_installed .. " packages\n"
    status = status .. "  Missing: " .. #missing_pkgs .. " packages\n"
    
    if #missing_pkgs > 0 then
      status = status .. "\nMissing packages:\n"
      for _, pkg_name in ipairs(missing_pkgs) do
        status = status .. "  - " .. pkg_name .. "\n"
      end
      status = status .. "\nUse :InstallLanguageServers to install all missing packages"
    end
    
    vim.notify(status, vim.log.levels.INFO)
  end, { desc = "Show Mason package status" })

  -- Create a command to update all Mason packages
  vim.api.nvim_create_user_command("MasonUpdateAll", function()
    -- Check if mason-tool-installer is available
    local ok, _ = pcall(require, "mason-tool-installer")
    if ok then
      vim.cmd("MasonToolsUpdate")
      vim.notify("Checking for package updates...", vim.log.levels.INFO)
    else
      vim.notify("Mason Tool Installer not available. Try again after plugins are loaded.", vim.log.levels.WARN)
    end
  end, { desc = "Update all Mason packages" })
end

local function setup_plugins()
  
  return {
    {
      "williamboman/mason.nvim",
      cmd = { "Mason", "MasonInstall", "MasonUpdate" },
      lazy = false,
      opts = function()
        local opts = require "nvchad.configs.mason"
        local mason_config = require("sevilzww.configs.mason")
        
        -- Apply our custom configuration
        opts.ensure_installed = mason_config.ensure_installed
        opts.max_concurrent_installers = mason_config.max_concurrent_installers
        opts.ui = mason_config.ui
        
        return opts
      end,
      config = function(_, opts)
        require("mason").setup(opts)
        
        -- Auto-install packages if enabled
        local mason_config = require("sevilzww.configs.mason")
        if mason_config.auto_install then
          local mr = require("mason-registry")
          
          vim.notify("Mason: checking for missing packages...", vim.log.levels.INFO)
          local packages_to_install = {}
          for _, package_name in ipairs(mason_config.ensure_installed) do
            local p_available, p = pcall(mr.get_package, package_name)
            if p_available then
              if not p:is_installed() then
                table.insert(packages_to_install, package_name)
              end
            end
          end
          
          -- Install missing packages
          if #packages_to_install > 0 then
            vim.notify("Mason: installing " .. #packages_to_install .. " packages...", vim.log.levels.INFO)
            
            vim.cmd("MasonInstall " .. table.concat(packages_to_install, " "))
          else
            vim.notify("Mason: all packages are already installed", vim.log.levels.INFO)
          end
        end
      end,
    },
    
    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      lazy = false,
      dependencies = {
        "williamboman/mason.nvim",
      },
      config = function()
        local mason_config = require("sevilzww.configs.mason")
        
        require("mason-tool-installer").setup({
          ensure_installed = mason_config.ensure_installed,
          auto_update = false,
          run_on_start = true,
          start_delay = 3000,
          debounce_hours = 24,
        })
        
        local mason_registry = require("mason-registry")
        mason_registry:on("package:install:success", function(pkg)
          vim.schedule(function()
            vim.notify("Mason: Successfully installed " .. pkg.name, vim.log.levels.INFO)
          end)
        end)
        
        -- Handle package install failure
        mason_registry:on("package:install:failed", function(pkg, err)
          vim.schedule(function()
            vim.notify("Mason: Failed to install " .. pkg.name .. "\nError: " .. err, vim.log.levels.ERROR)
          end)
        end)
      end,
    },
  }
end

-- Initialize the module
local M = {}
setup_commands()

-- Expose the plugin configuration for use in init.lua
M.plugins = setup_plugins()
return M
