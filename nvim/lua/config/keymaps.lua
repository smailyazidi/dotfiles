-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.keymap.set("n", "<leader>rj", function()
  require("config.java_runner").run_java()
end, { desc = "Run Java File" })
vim.keymap.set("n", "<leader>rc", function()
  require("config.c_runner").run_c()
end, { desc = "Run C File" })
