return {
  "klen/nvim-config-local",
  init = function()
    require("config-local").setup({
      -- Default configuration (optional)
      config_files = { ".vimrc.lua", ".vimrc", ".lvimrc" }, -- Config file patterns to load (lua supported)
      hashfile = vim.fn.stdpath("data") .. "/config-local", -- Where the plugin keeps files data
      autocommands_create = true, -- Create autocommands (VimEnter, DirectoryChanged)
      commands_create = true, -- Create commands (ConfigSource, ConfigEdit, ConfigTrust, ConfigIgnore)
      silent = false, -- Disable plugin messages (Config loaded/ignored)
    })
  end,
}
