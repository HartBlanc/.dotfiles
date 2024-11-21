local function setup_arc()
  require('lint').linters.arc_lint = {
    name = 'arc_lint',
    cmd = '/usr/bin/env',
    stdin = false,
    append_fname = true,
    args = {
      'sh',
      '-c',
      function()
        local shims = 'PATH=$HOME/.shims:$PATH ' -- Shims will skip linters I don't care for
        local command = 'arc lint --never-apply-patches --output json'
        local filepath = "'" .. vim.fn.expand('%') .. "'"
        local job = '& pid=$! && wait $pid'
        return table.concat({ shims, command, filepath, job }, ' ')
      end,
    },
    stream = 'stdout',
    ignore_exitcode = true,
    parser = function(output, bufNo)
      local items = require('arc-lint').parse_arc_output(output)
      local buf_filepath = vim.api.nvim_buf_get_name(bufNo)
      local diagnostics = {}

      for _, item in ipairs(items) do
        if string.find(buf_filepath, item.filepath) then
          table.insert(diagnostics, {
            lnum = item.lnum,
            col = item.col,
            end_lnum = item.end_lnum,
            end_col = item.end_col,
            code = item.code,
            source = item.source,
            user_data = item.user_data,
            severity = item.severity,
            message = item.message,
          })
        end
      end
      return diagnostics
    end,
  }
end

local linters = {
  go = {},
}
if vim.fn.executable('arc') == 1 then
  setup_arc()
  table.insert(linters.go, 'arc_lint')
end

require('lint').linters_by_ft = linters

vim.api.nvim_create_autocmd({ 'BufRead', 'BufWritePost' }, {
  callback = function()
    require('lint').try_lint('arc_lint')
  end,
  pattern = '*',
  desc = 'Run arc lint after reading or writing a buffer',
})

vim.keymap.set('n', '<leader>al', require('arc-lint').arc_lint, { desc = 'Open [A]rc [L]int results to quick fix' })
