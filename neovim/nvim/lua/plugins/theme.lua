return {
  -- Install catppuccin
  {
    "catppuccin/nvim",
    -- lazy = false,
    -- priority = 1000,
  },
  -- Install dracula
  {
    "Mofiqul/dracula.nvim",
    -- lazy = false,
    -- priority = 1000,
  },
  -- Install onedark
  {
    "olimorris/onedarkpro.nvim",
    name = "onedarkpro",
    -- lazy = false,
    -- priority = 1000,
  },
  -- Configure LazyVim to load the theme we want
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
    },
  },
}
