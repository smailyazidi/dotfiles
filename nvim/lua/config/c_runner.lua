local M = {}

-- Keep track of the terminal buffer and window
local term_buf = nil
local term_win = nil

function M.run_c()
  local file = vim.fn.expand("%:p") -- full path to file
  local exe = vim.fn.expand("%:t:r") -- filename without extension
  local compile_cmd = "gcc " .. file .. " -o " .. exe
  local run_cmd = "./" .. exe
  local full_cmd = compile_cmd .. " && " .. run_cmd .. "\n"

  -- Open terminal if not already open
  if term_buf == nil or not vim.api.nvim_buf_is_valid(term_buf) then
    vim.cmd("botright split | resize 15")
    vim.cmd("terminal")
    term_buf = vim.api.nvim_get_current_buf()
    term_win = vim.api.nvim_get_current_win()
  else
    vim.api.nvim_set_current_win(term_win)
    vim.cmd("startinsert")
  end

  -- Send command to terminal
  vim.fn.chansend(vim.b.terminal_job_id, full_cmd)
end

return M
