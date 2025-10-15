return {
	'neovim/nvim-lspconfig',
	config = function()
		vim.lsp.enable({
			"bashls",
			"lua_ls",
			"zls",
			"pyright",
      "yamlls",
		})
		vim.diagnostic.config({
			-- virtual_lines = true,
			virtual_text = true,
			underline = true,
			-- update_in_insert = false,
			severity_sort = true,
			float = {
				-- style = 'minimal',
				border = "rounded",
				-- source = true,
			},
		})
	end
}
