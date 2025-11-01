-- return {
-- 	'nvim-lualine/lualine.nvim',
-- 	dependencies = {
-- 		"nvim-tree/nvim-web-devicons",
-- 	},
-- 	opts = {
-- 		theme = 'gruvbox-material',
-- 	},
--   tabline = {
--     lualine_a = { 'buffers' }
--   }
-- }

return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('lualine').setup {
      options = {
        -- theme = 'gruvbox-material',
        disabled_filetypes = {
          statusline = { 'directory' }, -- this won't work alone, we need a trick below
        },
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = {
          {
            'buffers',
            show_filename_only = true,       -- Shows shortened relative path when set to false.
            hide_filename_extension = false, -- Hide filename extension when set to true.
            show_modified_status = true,     -- Shows indicator when the buffer is modified.

            mode = 0,                        -- 0: Shows buffer name
            -- 1: Shows buffer index
            -- 2: Shows buffer name + buffer index
            -- 3: Shows buffer number
            -- 4: Shows buffer name + buffer number

            max_length = vim.o.columns * 2 / 3, -- Maximum width of buffers component,
            -- it can also be a function that returns
            -- the value of `max_length` dynamically.
            buffers_color = {
              -- Same values as the general color option can be used here.
              active = { bg = '#D8A657', fg = '#282828' },
              -- inactive = 'lualine_{section}_inactive', -- Color for inactive buffer.
            },
          }
        },
        lualine_c = { 'branch', 'diff', 'diagnostics' },
        lualine_x = { 'lsp_status', 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { require("opencode").statusline },
      },
      -- inactive_sections = {
      --   lualine_a = {},
      --   lualine_b = {},
      --   lualine_c = { 'filename' },
      --   lualine_x = { 'location' },
      --   lualine_y = {},
      --   lualine_z = {}
      -- },
      tabline = {},
      -- tabline = {
      --   lualine_a = { 'hostname' },
      --   lualine_b = { 'lsp_status' },
      --   lualine_c = { 'filename' },
      --   lualine_x = {},
      --   lualine_y = {},
      --   lualine_z = {}
      -- },
      winbar = {},
      inactive_winbar = {},
      extensions = {}
    }
  end,
}
