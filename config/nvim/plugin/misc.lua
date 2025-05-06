-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

local augroup = vim.api.nvim_create_augroup('misc', { clear = true })

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = augroup,
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    local file_extension = vim.fn.expand('%:e')
    if file_extension ~= 'diff' then
      vim.cmd('%s/\\s\\+$//e')
    end
  end,
  group = augroup,
  desc = 'Trim trailing whitespace',
})

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = augroup,
  pattern = '*',
  desc = 'Sort quickfix list items',
  callback = function()
    local qflist = vim.fn.getqflist()
    table.sort(qflist, function(a, b)
      local a_name = vim.api.nvim_buf_get_name(a.bufnr)
      local b_name = vim.api.nvim_buf_get_name(b.bufnr)
      if a_name ~= b_name then
        return a_name < b_name
      end
      if a.lnum ~= b.lnum then
        return a.lnum < b.lnum
      end
      return a.col < b.col
    end)
    vim.fn.setqflist(qflist, 'r')
  end,
})
