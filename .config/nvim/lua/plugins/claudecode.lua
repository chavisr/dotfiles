return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal_cmd = "/usr/bin/claude", -- Point to local installation
    terminal = {
      provider = "external",
      provider_opts = {
        external_terminal_cmd = "alacritty -e %s", -- %s is replaced with claude command
        -- Or with working directory: "alacritty --working-directory %s -e %s" (first %s = cwd, second %s = command)
      },
    },
  },
  config = true,
  keys = {
    { "<leader>a",  nil,                              desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
    -- { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v",                  desc = "Send to Claude" },
    { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",     desc = "Add file",           ft = { "oil", "netrw" }, },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "Deny diff" },
  },
}
