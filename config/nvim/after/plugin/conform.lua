local format_on_save = false

vim.keymap.set('n', '<leader>ft', function()
  format_on_save = not format_on_save
  if format_on_save then
    vim.notify('Disabled format on save', vim.log.levels.INFO)
  else
    vim.notify('Enabled format on save', vim.log.levels.INFO)
  end
end, { desc = '[F]ormat on save [T]oggle' })

local go_formatters = { 'goimports' }
if vim.fn.executable('golangci-lint') == 1 then
  go_formatters = { 'goimports', 'golangcillint' }
end

require('conform').setup({
  formatters = {
    golangcilint = {
      stdin = false,
      tmpfile_format = 'conform-nvim-tmp-$RANDOM-$FILENAME', -- golangci-lint can not find the file if it is a hidden file
      command = 'golangci-lint',
      args = {
        'run',
        '--fix',
        '--fast',
        '--internal-cmd-test', -- hack to disable typecheck
        '--enable-only',
        'gci',
        '$FILENAME',
      },
    },
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'black' },
    go = go_formatters,
    javascript = { 'prettier' },
    html = { 'prettier' },
  },
  format_on_save = {
    timeout_ms = 2000,
  },
})
