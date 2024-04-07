-- Gitsigns
vim.keymap.set('n', ']h', '<cmd>:Gitsigns next_hunk<cr>')
vim.keymap.set('n', '[h', '<cmd>:Gitsigns prev_hunk<cr>')

vim.keymap.set('n', '<leader>hq', '<cmd>:Gitsigns setqflist<cr>')
vim.keymap.set('n', '<leader>hp', '<cmd>:Gitsigns preview_hunk<cr>')
vim.keymap.set('n', '<leader>hr', '<cmd>:Gitsigns reset_hunk<cr>')
vim.keymap.set('n', '<leader>hu', '<cmd>:Gitsigns undo_stage_hunk<cr>')
vim.keymap.set('n', '<leader>hs', '<cmd>:Gitsigns stage_hunk<cr>')
vim.keymap.set('v', '<leader>hs', function()
  require('gitsigns')['stage_hunk']({ vim.fn.line('.'), vim.fn.line('v') })
end)
