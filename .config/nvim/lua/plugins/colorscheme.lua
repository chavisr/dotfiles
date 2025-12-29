local function enable_transparency()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  -- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  -- vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
  -- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  -- vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
end

return {
  'sainnhe/gruvbox-material',
  lazy = false,
  priority = 1000,
  config = function()
    vim.g.gruvbox_material_enable_italic = true
    vim.g.gruvbox_material_better_performance = false
    vim.g.gruvbox_material_foreground = "material" -- material/mix/original
    vim.g.gruvbox_material_background = "hard" -- hard/soft/medium
    vim.g.gruvbox_material_float_style = "blend" -- dim/bright/blend
    vim.g.gruvbox_material_ui_contrast = "low" -- low/high

    vim.cmd.colorscheme('gruvbox-material')
    enable_transparency()
  end
}
