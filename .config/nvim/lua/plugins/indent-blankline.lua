return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  ---@module "ibl"
  ---@type ibl.config
  opts = {},
  config = function()
    require("ibl").setup({
      indent = {
        -- char = "┊",

        -- char = "┋",

        -- char = "┊",

        -- char = "┆",

        -- char = "¦",

        char = "┆",

        -- char = "┇",

        -- char = "┋",
      },
      scope = {
        enabled = false,
        show_start = false,
        show_end = false,
      },
    })
  end
}
