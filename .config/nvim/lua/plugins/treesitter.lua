return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
	local configs = require("nvim-treesitter.configs")
	configs.setup({
	    highlight = {
		enable = true,
	    },
	    -- enable indentation
	    indent = { enable = true },
	    -- enable autotagging (w/ nvim-ts-autotag plugin)
	    -- autotag = { enable = true },
	    -- ensure these language parsers are installed
	    ensure_installed = {
		"json",
		"python",
		"javascript",
		"query",
		"yaml",
		"html",
		"css",
		"markdown",
		"markdown_inline",
		"bash",
		"lua",
		"vim",
		"vimdoc",
		"c",
		"dockerfile",
		"gitignore",
	    },
	    -- auto install above language parsers
	    auto_install = true,
	})
    end
}
