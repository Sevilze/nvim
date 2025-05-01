local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>gg", function()
    local ok, lazygit = pcall(require, "lazygit")
    if ok then
      if type(lazygit.lazygit) == "function" then
        lazygit.lazygit()
      else
        vim.cmd("LazyGit")
      end
    else
      vim.cmd("LazyGit")
    end
  end, { desc = "LazyGit" })

  vim.keymap.set("n", "<leader>gf", function()
    local ok, lazygit = pcall(require, "lazygit")
    if ok then
      if type(lazygit.lazygit_filter) == "function" then
        lazygit.lazygit_filter()
      else
        vim.cmd("LazyGitFilter")
      end
    else
      vim.cmd("LazyGitFilter")
    end
  end, { desc = "LazyGit Filter" })

  vim.keymap.set("n", "<leader>gc", function()
    local ok, lazygit = pcall(require, "lazygit")
    if ok then
      if type(lazygit.lazygit_current_file) == "function" then
        lazygit.lazygit_current_file()
      else
        vim.cmd("LazyGitCurrentFile")
      end
    else
      vim.cmd("LazyGitCurrentFile")
    end
  end, { desc = "LazyGit Current File" })

  vim.keymap.set("n", "<leader>gr", function()
    local chadrc = require("sevilzww.chadrc")
    local theme_name = chadrc.base46.theme or "tokyodark"

    local ok, _ = pcall(require, "lazygit")
    if not ok then
      vim.notify("LazyGit plugin not loaded", vim.log.levels.ERROR)
    end
  end, { desc = "Reload LazyGit Config" })
end

return M
