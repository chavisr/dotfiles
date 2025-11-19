return {
  "mason-org/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      -- "lua_ls",
      -- "yamlls",
      -- "jsonls",
      -- "pyright",
      -- "bash_ls",
    },
  },

  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "neovim/nvim-lspconfig",
  },
}
