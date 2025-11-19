local vim = vim

-- keymaps
vim.g.mapleader = " "
-- vim.g.maplocalleader = " "
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("i", "jk", "<Esc>")
-- vim.keymap.set("i", "<C-Space>", "<C-x><C-o>")
vim.keymap.set("n", "<leader>e", ":Oil<CR>")
-- vim.keymap.set("n", "<leader>e", vim.cmd.Ex)
vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "<leader>q", ":bdelete<CR>")
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>")
vim.keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>")
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>fw", ":Telescope grep_string<CR>")
-- vim.keymap.set("n", "<leader>tn", ":tabnew<CR>")
-- vim.keymap.set("n", "<leader>tx", ":tabclose<CR>")
vim.keymap.set('n', '<Tab>', ':bnext<CR>')
vim.keymap.set('n', '<S-Tab>', ':bprev<CR>')
vim.keymap.set("n", "<leader><Tab>", ":e#<CR>")
vim.keymap.set("n", "<leader>u", ":e!<CR>")
vim.keymap.set("n", "y", '"+y')
vim.keymap.set("v", "y", '"+y')
vim.keymap.set("n", "Y", '"+Y')
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-/>", "gcc", { remap = true })
vim.keymap.set("v", "<C-/>", "gc", { remap = true })
-- vim.keymap.set("n", "q", "<Nop>")
vim.keymap.set("n", "<M-j>", ":cnext<CR>")
vim.keymap.set("n", "<M-k>", ":cprev<CR>")
vim.keymap.set("n", "Q", "<nop>")

-- options
vim.opt.relativenumber = true
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
vim.opt.colorcolumn = "100"
vim.opt.termguicolors = true
vim.opt.background = "dark"
-- vim.opt.winborder = "rounded"
-- vim.opt.clipboard = "unnamedplus"
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")
vim.opt.undofile = true
-- vim.opt.updatetime = 50
-- vim.opt.showtabline = 1
vim.opt.tabline = ''
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
vim.opt.iskeyword:append({ "-" }) -- ({ "-", "." })

-- cmds
-- vim.cmd("set completeopt+=noselect")

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- vim.api.nvim_create_autocmd('LspAttach', {
-- 	group = vim.api.nvim_create_augroup('my.lsp', {}),
-- 	callback = function(args)
-- 		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
-- 		if client:supports_method('textDocument/completion') then
-- 			-- Optional: trigger autocompletion on EVERY keypress. May be slow!
-- 			local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
-- 			client.server_capabilities.completionProvider.triggerCharacters = chars
-- 			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
-- 		end
-- 	end,
-- })

-- vim.api.nvim_create_autocmd("ColorScheme", {
--   callback = function()
--     -- vim.api.nvim_set_hl(0, 'TelescopeSelection', { bg = '#45403d', fg = '#D8A657' })
--     -- vim.api.nvim_set_hl(0, 'TelescopePromptPrefix', { fg = '#EA6962' })
--     vim.api.nvim_set_hl(0, 'SnacksPickerSelection', { bg = '#45403d', fg = '#D8A657', })
--     vim.api.nvim_set_hl(0, 'SnacksPromptPrefix', { fg = '#EA6962', })
--     -- Override Snacks highlight groups
--     vim.api.nvim_set_hl(0, "SnacksAccent", { fg = "#A9B665" })     -- green
--     vim.api.nvim_set_hl(0, "SnacksPickerMatch", { fg = "#A9B665" }) -- highlight matching text
--     vim.api.nvim_set_hl(0, "SnacksInputPrompt", { fg = "#A9B665" }) -- input prompts
--     vim.api.nvim_set_hl(0, "SnacksTerminalBorder", { fg = "#A9B665" }) -- terminal borders
--     vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#A9B665" })
--     vim.api.nvim_set_hl(0, "SnacksPickerTitle", { fg = "#A9B665" })
--     vim.api.nvim_set_hl(0, "SnacksPickerSelection", { fg = "#A9B665", bg = "#32302f" })
--   end
-- })

-- lazy package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  change_detection = { notify = false },
})
