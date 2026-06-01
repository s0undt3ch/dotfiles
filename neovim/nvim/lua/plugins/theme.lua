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
  -- Install gruvbox-material
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    init = function()
      vim.opt.background = "dark"
      vim.g.gruvbox_material_background = "hard" -- soft | medium | hard
      vim.g.gruvbox_material_foreground = "material" -- material | mix | original
      vim.g.gruvbox_material_enable_italic = true
      vim.g.gruvbox_material_better_performance = 1
    end,
  },
  -- Configure LazyVim to load the theme we want
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox-material",
    },
  },
}
