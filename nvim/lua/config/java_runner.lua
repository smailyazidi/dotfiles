local M = {}

-- حافظ على رقم الـ buffer الخاص بالترمنال
local term_buf = nil
local term_win = nil

function M.run_java()
  local file = vim.fn.expand("%:p")
  local class = vim.fn.expand("%:t:r")

  -- Compile و Run
  local compile_cmd = "javac " .. file
  local run_cmd = "java " .. class
  local full_cmd = compile_cmd .. " && " .. run_cmd .. "\n"

  -- إذا ما فيه ترمنال مفتوح، افتح واحد جديد
  if term_buf == nil or not vim.api.nvim_buf_is_valid(term_buf) then
    vim.cmd("botright split | resize 15")
    vim.cmd("terminal")
    term_buf = vim.api.nvim_get_current_buf()
    term_win = vim.api.nvim_get_current_win()
  else
    -- إذا موجود، نرجع له
    vim.api.nvim_set_current_win(term_win)
    vim.cmd("startinsert")
  end

  -- أرسل الأمر إلى الترمنال
  vim.fn.chansend(vim.b.terminal_job_id, full_cmd)
end

return M
