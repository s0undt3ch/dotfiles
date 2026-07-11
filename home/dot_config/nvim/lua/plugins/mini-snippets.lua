return {
  {
    "nvim-mini/mini.snippets",
    opts = function(_, opts)
    -- By default, for opts.snippets, the extra for mini.snippets only adds gen_loader.from_lang()
    -- This provides a sensible quickstart, integrating with friendly-snippets
    -- and your own language-specific snippets
    --
    -- In order to change opts.snippets, replace the entire table inside your own opts

    local snippets, config_path = require("mini.snippets"), vim.fn.stdpath("config")

    opts.snippets = { -- override opts.snippets provided by extra...
      -- Load custom file with global snippets first (order matters)
      snippets.gen_loader.from_file(config_path .. "/snippets/global.lua"),

      -- Load snippets based on current language by reading files from
      -- "snippets/" subdirectories from 'runtimepath' directories.
      snippets.gen_loader.from_lang(), -- this is the default in the extra...
    }
    end,
  },
}
