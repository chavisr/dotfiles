return {
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate",
    config = function()
	local configs = require("nvim-treesitter.configs")
	configs.setup({
	    highlight = {
		enable = true,
	    },
	    indent = { enable = true },
	    autotage = { enable = true },
	    ensure_installed = {
		"lua",
		"markdown",
		"markdown_inline",
		"bash",
		"json",
		"regex",
		"yaml",
		"vim",
		"vimdoc",
		"python",
		"html"
	    },
	    auto_install = true,
	})
    end
}
