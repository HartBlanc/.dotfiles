local treesj = require('treesj')

vim.keymap.set('n', '<leader>j', treesj.toggle, { desc = 'Toggle [J]oin/Split for current treesitter node' })

vim.keymap.set('n', '<leader>J', function()
  treesj.toggle({ split = { recursive = true } })
end, { desc = 'Toggle [J]oin/Split for current treesitter node (recursive)' })
