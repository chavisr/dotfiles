local function enable_transparency()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
end

return {
  'sainnhe/gruvbox-material',
  lazy = false,
  priority = 1000,
  config = function()
    vim.g.gruvbox_material_enable_italic = 1 -- 0/1
    -- vim.g.gruvbox_material_enable_bold = 1   -- 0/1
    vim.g.gruvbox_material_transparent_background = 1 -- 0/1/2
    -- vim.g.gruvbox_material_better_performance = 0 -- 0/1
    vim.g.gruvbox_material_foreground = "material" -- material/mix/original
    vim.g.gruvbox_material_background = "hard"     -- hard/soft/medium
    vim.g.gruvbox_material_float_style = "bright"  -- dim/bright/blend
    -- vim.g.gruvbox_material_ui_contrast = "low"       -- low/high
    -- vim.g.gruvbox_material_menu_selection_background = "red"
    -- vim.g.gruvbox_material_diagnostic_text_highlight = 0 -- 0/1
    -- vim.g.gruvbox_material_diagnostic_line_highlight = 1 -- 0/1
    -- vim.g.gruvbox_material_diagnostic_virtual_text = 'highlighted' -- grey/colored/highlighted
    -- vim.g.gruvbox_material_dim_inactive_windows = 1 -- 0/1
    -- vim.g.gruvbox_material_spell_fore_ground = 'none' -- none/colored
    -- vim.g.gruvbox_material_show_eob = 0 -- 0/1
    -- vim.g.gruvbox_material_current_word = 'grey background' -- grey background/high contrast background/bold/underline/italic
    -- vim.g.gruvbox_material_inlay_hints_background = 'dimmed' -- none/dimmed
    vim.g.gruvbox_material_colors_override = {
      -- bg0 = { "#141617", "234" }, -- bg color
      -- bg1 = { "#282828", "235" }, -- cursor line bg color
      -- bg2 = { "#FFFFFF", "235" },
      bg3 = { "#2e2e2e", "237" }, -- menu bg color
      -- bg4 = { "#FFFFFF", "237" },
      -- fg0 = { "#000000", "223" }, -- text color
      -- fg1 = { "#1d2021", "223" }, -- menu text color
    }
    vim.g.gruvbox_material_statusline_style = "custom" -- default/mix/original/custom
    vim.cmd.colorscheme('gruvbox-material')
    -- enable_transparency()
  end
}
