local vim = vim

-- core ui2
require('vim._core.ui2').enable({
  enable = true,
})

-- nvchad ui
vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46_cache/"

-- keymaps
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("n", "vv", "^vg_")
vim.keymap.set("n", "<leader>e", ":Oil<CR>")
vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "<leader>q", ":bdelete<CR>")
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>")
vim.keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>")
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>fG", ":lua require('telescope.builtin').live_grep{additional_args={'-s'}}<CR>")
vim.keymap.set("n", "<leader>fw", ":Telescope grep_string<CR>")
vim.keymap.set('n', '<Tab>', ':bnext<CR>')
vim.keymap.set('n', '<S-Tab>', ':bprev<CR>')
vim.keymap.set("n", "<leader><Tab>", ":e#<CR>")
vim.keymap.set("n", "<leader>u", ":e!<CR>")
vim.keymap.set("n", "y", '"+y')
vim.keymap.set("v", "y", '"+y')
vim.keymap.set("n", "Y", '"+y$')
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-/>", "gcc", { remap = true })
vim.keymap.set("v", "<C-/>", "gc", { remap = true })
vim.keymap.set("n", "<C-_>", "gcc", { remap = true })
vim.keymap.set("v", "<C-_>", "gc", { remap = true })
vim.keymap.set("n", "<M-j>", ":cnext<CR>")
vim.keymap.set("n", "<M-k>", ":cprev<CR>")
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>vi", ":edit $MYVIMRC<CR>")
vim.keymap.set("n", "<leader>td", ":edit $HOME/todo.md<CR>")

-- options
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.cursorcolumn = false
-- vim.opt.colorcolumn = "100"
vim.opt.termguicolors = true
-- vim.opt.background = "dark"
vim.opt.winborder = "single"
-- vim.opt.clipboard = "unnamedplus"
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")
vim.opt.undofile = true
-- vim.opt.updatetime = 50
vim.opt.showtabline = 0
vim.opt.hlsearch = true
vim.opt.incsearch = true
-- vim.opt.completeopt = "menuone,noinsert,noselect"
-- vim.opt.wildmenu = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.wrap = false
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 8
-- vim.opt.laststatus = 2
vim.opt.showmode = false
vim.opt.iskeyword:append({ "-" })
-- vim.opt.iskeyword:append({ "-", "." })

-- autocmds
vim.api.nvim_create_user_command('PackUpdate', function() vim.pack.update() end, {})

-- highlight yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- restore cursor to file position in previous editing session
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
      -- defer centering slightly so it's applied after render
      vim.schedule(function()
        vim.cmd("normal! zz")
      end)
    end
  end,
})

-- open help in vertical split
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  command = "wincmd L",
})

-- no auto continue comments on new line
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("no_auto_comment", {}),
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- vim.pack build hook
-- read https://neovim.io/doc/user/pack/#vim.pack-examples
-- read https://www.reddit.com/r/neovim/comments/1ssl8qf/extending_vimpack_with_data_build_hooks_and_lazy/
local function run_build(spec, path)
  local build = spec.data and spec.data.build
  if not build then return end

  vim.system({ "sh", "-c", build }, {
    cwd = path,
    text = true,
  })
end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.kind == "install" or ev.data.kind == "update" then
      run_build(ev.data.spec, ev.data.path)
    end
  end,
})

-- vim.pack lazy load
for _, plug in ipairs(vim.pack.get()) do
  local spec = plug.spec

  if spec.data and spec.data.event then
    vim.api.nvim_create_autocmd(spec.data.event, {
      once = true,
      callback = function()
        vim.cmd("packadd " .. spec.name)
      end,
    })
  end
end

-- vim.pack
vim.pack.add({
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/echasnovski/mini.icons" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvchad/ui" },
  { src = "https://github.com/nvchad/base46" },
  { src = "https://github.com/nvchad/volt" },
  {
    src = "https://github.com/saghen/blink.cmp",
    version = "v1",
    data = {
      event = "InsertEnter"
    }
  },
  { src = "https://github.com/rafamadriz/friendly-snippets", },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/stevearc/quicker.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/kylechui/nvim-surround" },
  { src = "https://github.com/folke/lazy.nvim" },
  { src = "https://github.com/coder/claudecode.nvim" },
  {
    src = "https://github.com/windwp/nvim-autopairs",
    data = {
      event = "InsertEnter"
    }
  },
  {
    src = "https://github.com/iamcco/markdown-preview.nvim",
    data = {
      build = "cd app && ./install.sh",
    },
  },
})

require("plugins.oil")
require("plugins.nvim-lspconfig")
require("plugins.nvchad-ui")
require("plugins.blink")
require("plugins.mason")
require("plugins.mason-lspconfig")
require("plugins.gitsigns")
require("plugins.quicker")
require("plugins.telescope")
require("plugins.nvim-surround")
require("plugins.nvim-autopairs")
require("plugins.claudecode")

-- nvchad ui
for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
  dofile(vim.g.base46_cache .. v)
end

-- extend lsp
vim.filetype.add({
  extension = {
    jsonl = "json",
  },
})
