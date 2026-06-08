-- Setup the plugin
require("claudecode").setup({
  -- focus_after_send = false,
  terminal_cmd = "claude",
  terminal = {
    provider = "external",
    -- auto_close = true,
    provider_opts = {
      external_terminal_cmd = "alacritty -e %s"
    }
  }
})

-- Keymaps
vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume Claude" })
vim.keymap.set("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
vim.keymap.set("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Claude model" })
vim.keymap.set("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Add current buffer" })
vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send to Claude" })

-- Diff management
vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })

-- File tree keymap (filetype-specific)
vim.api.nvim_create_autocmd("FileType", {
  -- pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
  pattern = { "oil", "netrw" },
  callback = function(ev)
    vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",
      { desc = "Add file", buffer = ev.buf })
  end,
})
