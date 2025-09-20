local function enable_transparency()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    -- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    -- vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
end

return {
    'sainnhe/gruvbox-material',
    lazy = false,
    priority = 1000,
    config = function()
	vim.g.gruvbox_material_enable_italic = true
	vim.g.gruvbox_material_better_performance = false
	-- vim.g.gruvbox_material_foreground = "mix"
	vim.g.gruvbox_material_background = 'medium'
	-- vim.g.gruvbox_material_ui_contrast = "high"
	-- vim.g.gruvbox_material_float_style = "bright"
	-- vim.g.gruvbox_material_statusline_style = "material"
	-- vim.g.gruvbox_material_cursor = "auto"
	vim.cmd.colorscheme('gruvbox-material')
	enable_transparency()
    end
}
