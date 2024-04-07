local virtual_text_float_config = {
  source = true,
  ---@param diagnostic Diagnostic
  ---@return string
  format = function(diagnostic)
    local source_prefix = string.format('%s: ', diagnostic.source)
    local message = diagnostic.message:gsub('^' .. source_prefix, '')
    return message
  end,
}
vim.diagnostic.config({
  float = virtual_text_float_config,
  virtual_text = virtual_text_float_config,
  source = true,
  severity_sort = true,
})

vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticWarn' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticInfo' })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', 'dK', vim.diagnostic.open_float)
