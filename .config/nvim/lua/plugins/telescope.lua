return {
  'nvim-telescope/telescope.nvim',
  -- tag = '0.1.8',
  branch = '0.1.x',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    vim.api.nvim_set_hl(0, 'TelescopeSelection', { bg = '#45403d', fg = '#D8A657' })
    vim.api.nvim_set_hl(0, 'TelescopePromptPrefix', { fg = '#EA6962' })
    -- vim.api.nvim_set_hl(0, "TelescopeSelection", { link = "SnacksPickerSelection" })
    -- vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { link = "SnacksInputPrompt" })
  end
}
