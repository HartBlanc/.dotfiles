local function truthy(v)
  if type(v) == 'number' then
    return v ~= 0
  elseif type(v) == 'boolean' then
    return v
  end

  return false
end

local function splitlines(str)
  local result = {}
  for line in str:gmatch('[^\n]+') do
    table.insert(result, line)
  end
  return result
end

local function arc_lint()
  local output = vim.fn.system('PATH=$HOME/.shims:$PATH arc lint --never-apply-patches --output json')
  local lines = splitlines(output)
  if #lines < 1 then
    return {}
  end

  local quickfix_items = {}
  for _, line in ipairs(lines) do
    local decoded = vim.json.decode(line)
    for filepath, diag_list in pairs(decoded or {}) do
      for _, item in ipairs(diag_list or {}) do
        if item.severity ~= 'autofix' then
          local char = truthy(item.char) and item.char or 0
          local lnum = truthy(item.line) and item.char or 0
          table.insert(quickfix_items, {
            filename = filepath,
            lnum = lnum - 1, -- line number
            col = char - 1, -- column number
            text = '[' .. item.name .. '] ' .. item.description,
          })
        end
      end
    end
  end

  vim.fn.setqflist(quickfix_items)
  vim.cmd('copen')
end

local function setup_arc()
  local severities = {
    info = vim.lsp.protocol.DiagnosticSeverity.Info,
    advice = vim.lsp.protocol.DiagnosticSeverity.Info,
    hint = vim.lsp.protocol.DiagnosticSeverity.Hint,
    error = vim.lsp.protocol.DiagnosticSeverity.Error,
    warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
  }

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
      -- Output is jsonl so we split on newlines
      local lines = splitlines(output)
      if #lines < 1 then
        return {}
      end

      local buf_filepath = vim.api.nvim_buf_get_name(bufNo)
      local diagnostics = {}

      for _, line in ipairs(lines) do
        local decoded = vim.json.decode(line)
        for filepath, diag_list in pairs(decoded or {}) do
          if string.find(buf_filepath, filepath) then
            for _, item in ipairs(diag_list or {}) do
              if item.severity ~= 'autofix' then
                local char = truthy(item.char) and item.char or 0
                table.insert(diagnostics, {
                  lnum = item.line - 1,
                  col = char - 1,
                  end_lnum = item.line - 1,
                  end_col = char - 1,
                  code = item.code,
                  source = 'arc-lint',
                  user_data = {
                    lsp = {
                      code = item.code,
                    },
                  },
                  severity = severities[item.severity],
                  message = '[' .. item.name .. '] ' .. item.description,
                })
              end
            end
            return diagnostics
          end
        end
      end
      return diagnostics
    end,
  }
end

local function errcheck()
  require('lint').linters.errcheck = {
    name = 'errcheck',
    cmd = 'errcheck',
    stdin = false,
    append_fname = false,
    args = {
      '-ignoretests',
      '-abspath',
      function()
        return vim.fn.expand('%:h')
      end,
    },
    stream = 'stdout',
    ignore_exitcode = true,
    parser = function(output, bufNo)
      local diagnostics = {}

      if output == '' then
        return {}
      end

      local buf_filepath = vim.api.nvim_buf_get_name(bufNo)
      local lines = splitlines(output)

      for _, line in ipairs(lines or {}) do
        local i, _, filepath, row, end_col, indent, tail = string.find(line, '(.+):(%d+):(%d+):(%s*)(.*)')
        if i ~= nil and filepath == buf_filepath then
          table.insert(diagnostics, {
            lnum = row - 1,
            col = 0,
            end_lnum = row - 1,
            end_col = 0,
            source = 'errcheck',
            message = '[errcheck] error return is ignored',
            severity = vim.lsp.protocol.DiagnosticSeverity.Warning,
          })
        end
      end

      return diagnostics
    end,
  }
end

local function augroup(group, events, pattern, command)
  if group ~= nil then
    vim.api.nvim_create_augroup(group, { clear = false })
    vim.api.nvim_clear_autocmds({ group = group, pattern = pattern })
  end

  local opts = {
    pattern = pattern,
    group = group,
  }

  if type(command) == 'function' then
    opts.callback = command
  else
    opts.command = command
  end

  vim.api.nvim_create_autocmd(events, opts)
end

local linters = {
  sh = { 'shellcheck' },
  go = {},
}

-- Allows shellcheck to follow source
local shellcheck_args = {
  '-x',
  '-P',
  function()
    return vim.fn.expand('%:h')
  end,
}
for _, arg in ipairs(shellcheck_args) do
  table.insert(require('lint').linters.shellcheck.args, arg)
end

if vim.fn.executable('errcheck') == 1 then
  errcheck()
  table.insert(linters.go, 'errcheck')
end

if vim.fn.executable('arc') == 1 then
  setup_arc()
  table.insert(linters.go, 'arc_lint')
end

require('lint').linters_by_ft = linters

augroup('shellcheck-lint-filetype', 'Filetype', 'sh', function()
  augroup('shellcheck-lint-on-change', { 'TextChanged', 'InsertLeave' }, '<buffer>', function()
    require('lint').try_lint()
  end)
end)

augroup(nil, { 'BufRead', 'BufWritePost' }, '*', function()
  require('lint').try_lint()
end)

vim.keymap.set('n', '<leader>al', arc_lint, { desc = 'Open [A]rc [L]int results to quick fix' })
