-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

vim.keymap.set(
  'n',
  '<c-d>',
  '<c-d>zz',
  { desc = 'Scroll down half a page, then redraw the current line at the center of the window' }
)
vim.keymap.set(
  'n',
  '<c-u>',
  '<c-u>zz',
  { desc = 'Scroll up half a page, then redraw the current line at the center of the window' }
)
vim.keymap.set(
  'n',
  'n',
  'nzz',
  { desc = 'Repeat the latest "/" or "?", then redraw the current line at center of the window' }
)
vim.keymap.set(
  'n',
  'N',
  'Nzz',
  { desc = 'Repeat the latest "/" or "?" in opposite direction, then redraw the current line at center of the window' }
)
vim.keymap.set('n', '*', '*zz', {
  desc = 'Go to the next occurance of the word under the cursor, then redraw the current line at center of the window',
})
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Remove highlights from last search term' })

vim.keymap.set('n', '<leader>m', '<cmd>messages<cr>', { desc = 'Show all messages' })

vim.keymap.set(
  'n',
  '/',
  '/\\V',
  { desc = 'Use verynomagic mode in all searches. i.e. all regexp special characters must be escaped.' }
)
vim.keymap.set(
  'c',
  's/',
  's/\\V',
  { desc = 'Use verynomagic mode in all substitutions. all regexp special characters must be escaped.' }
)

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Quickfix navigation
vim.keymap.set('n', ']q', vim.cmd.cnext, { desc = 'Jump to the next item in the [Q]uickfix list' })
vim.keymap.set('n', ']Q', vim.cmd.cnfile, { desc = 'Jump to the next file in the [Q]uickfix list' })
vim.keymap.set('n', '[q', vim.cmd.cprev, { desc = 'Jump to the previous item in the [Q]uickfix list' })
vim.keymap.set('n', '[Q', vim.cmd.cpfile, { desc = 'Jump to the previous file in the [Q]uickfix list' })
vim.keymap.set('n', '<leader>q', function()
  local qf_window_id = vim.fn.getqflist({ winid = 0 }).winid
  local qf_open = qf_window_id > 0
  if qf_open then
    vim.cmd.cclose()
  else
    vim.cmd.copen()
  end
end, { desc = 'Toggle quickfix window' })

vim.keymap.set('n', '<leader>cb', function()
  -- filter buffers for changed property since bufmodified = 1 doesn't seem to filter out all unchanged buffers
  local changed_buffers = vim.tbl_filter(function(b)
    return b.changed == 1
  end, vim.fn.getbufinfo({ bufmodified = 1 }) or {})
  if #changed_buffers == 0 then
    print('No unsaved buffers')
    return
  end
  vim.fn.setqflist(changed_buffers)
  vim.cmd.copen()
  vim.cmd.cfirst()
end, { desc = 'Populate the quickfix list with any unsaved buffers' })

-- Mappings for yanking the path of the current buffer to the clipboard

local git_root = require('util').git_root

vim.keymap.set('n', '<leader>y', function()
  local filepath = vim.api.nvim_buf_get_name(0)
  local relative_filepath = filepath:gsub('^' .. git_root(), '')
  vim.fn.setreg('"', relative_filepath)
  vim.fn.setreg('*', relative_filepath)
  vim.notify('Yanked path of current buffer relative to git root: ' .. relative_filepath, vim.log.levels.INFO)
end, { desc = 'Yank the path of the current buffer relative to the git root' })

vim.keymap.set('n', '<leader>Y', function()
  local filepath = vim.api.nvim_buf_get_name(0)
  vim.fn.setreg('"', filepath)
  vim.fn.setreg('*', filepath)

  vim.notify('Yanked absolute path of current buffer: ' .. filepath, vim.log.levels.INFO)
end, { desc = 'Yank the absolute path of the current buffer' })

vim.keymap.set('n', '<leader>ys', function()
  local filepath = vim.api.nvim_buf_get_name(0)
  local relative_filepath = filepath:gsub('^' .. git_root(), '')
  local line = unpack(vim.api.nvim_win_get_cursor(0))
  local base_url = vim.env.SOURCEGRAPH_BASE_URL
  if not base_url then
    vim.notify('Unable to yank sourcegraph URL: SOURCEGRAPH_BASE_URL env var not set', vim.log.levels.ERROR)
    return
  end
  local url = string.format('%s/-/blob/%s?L%d', base_url, relative_filepath, line)
  vim.fn.setreg('"', url)
  vim.fn.setreg('*', url)

  vim.notify('Yanked sourcegraph URL: ' .. url, vim.log.levels.INFO)
end, { desc = 'Yank the sourcegraph URL to the current position in the buffer' })
