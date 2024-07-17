return {
  "cappyzawa/trim.nvim",
  init = function()
    require("trim").setup({
      trim_first_line = false
    })
  end,
}
