local vim = vim
local Plug = vim.fn["plug#"]

vim.call("plug#begin")

Plug("nvim-treesitter/nvim-treesitter")
Plug("nvim-tree/nvim-tree.lua")
Plug("numToStr/Comment.nvim")
Plug("windwp/nvim-autopairs")
Plug("sainnhe/gruvbox-material")

vim.call("plug#end")

require("config")
require("plugins.nvim-tree")
require("plugins.treesitter")
require("plugins.comment")
require("plugins.autopairs")
require("plugins.gruvbox-material")
