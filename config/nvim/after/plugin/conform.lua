local disable_autoformat = false

vim.keymap.set('n', '<leader>ft', function()
  disable_autoformat = not disable_autoformat
end, { desc = '[F]ormat on save [T]oggle' })

local puku_enabled = (vim.fn.executable('puku') == 1)

vim.keymap.set('n', '<leader>ftp', function()
  if puku_enabled then
    vim.notify('Disabled puku auto-formatting', vim.log.levels.INFO)
  else
    vim.notify('Enabled puku auto-formatting', vim.log.levels.INFO)
  end
end, { desc = '[F]ormat on save [T]oggle ([P]uku)' })

require('conform').setup({
  formatters = {
    puku = {
      command = 'puku fmt',
    },
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'black' },
    go = { 'gofmt' },
    javascript = { 'prettier' },
    html = { 'prettier' },
    --
    -- You can use a sub-list to tell conform to run *until* a formatter
    -- is found.
    -- javascript = { { "prettierd", "prettier" } },
  },
  format_on_save = function(bufnr)
    if disable_autoformat then
      return
    end

    local formatters = nil
    if vim.bo.filetype == 'go' then
      if
        not puku_enabled
        or #vim.fs.find('.plzconfig', { upward = true, path = vim.api.nvim_buf_get_name(bufnr) }) < 1
      then
        formatters = { 'goimports' }
      else
        formatters = { 'goimports', 'puku' }
      end
    end

    return { timeout_ms = 500, lsp_fallback = true, formatters = formatters }
  end,
})
