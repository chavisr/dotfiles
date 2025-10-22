return {
  "nvimtools/none-ls.nvim",
  opts = {},
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.black,
      },
    })
  end
}
