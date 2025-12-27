local function enable_transparency()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  -- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  -- vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
  -- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  -- vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
end

return {
  "navarasu/onedark.nvim",
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require('onedark').setup {
      style = 'dark'
    }
    require('onedark').load()
  end
}
