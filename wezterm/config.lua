-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.font = wezterm.font("SauceCodePro Nerd Font")
config.font_size = 15

-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'
config.color_scheme = "Catppuccin Mocha"

config.enable_tab_bar = false

-- config.window_decorations = "RESIZE"
-- config.window_background_opacity = 0.75
-- config.macos_window_background_blur = 10
--

config.window_padding = {
  left = 2,
  right = 2,
  top = 0,
  bottom = 0,
}

-- and finally, return the configuration to wezterm
return config
