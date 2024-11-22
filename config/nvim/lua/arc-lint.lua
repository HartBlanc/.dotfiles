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

local M = {}

M.parse_arc_output = function(output)
  local severities = {
    info = vim.lsp.protocol.DiagnosticSeverity.Info,
    advice = vim.lsp.protocol.DiagnosticSeverity.Info,
    hint = vim.lsp.protocol.DiagnosticSeverity.Hint,
    error = vim.lsp.protocol.DiagnosticSeverity.Error,
    warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
  }

  local diagnostics = {}
  local lines = splitlines(output)
  if #lines < 1 then
    return {}
  end
  for _, line in ipairs(lines) do
    local ok, decoded = pcall(vim.json.decode, line)
    if not ok then
      vim.notify('Failed to parse line from arc lint expected json: ' .. line, vim.log.levels.WARN)
      goto continue
    end

    for filepath, diag_list in pairs(decoded or {}) do
      for _, item in ipairs(diag_list or {}) do
        if item.severity ~= 'autofix' then
          local lnum = truthy(item.line) and item.line or 0
          local char = truthy(item.char) and item.char or 0
          table.insert(diagnostics, {
            filepath = filepath,
            lnum = lnum,
            col = char - 1,
            end_lnum = lnum - 1,
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
    end
    ::continue::
  end
  return diagnostics
end

M.arc_lint = function(paths)
  local command
  command = { 'arc', 'lint', '--never-apply-patches', '--output', 'json' }
  if paths then
    for _, path in ipairs(paths) do
      table.insert(command, path)
    end
  end

  vim.system(
    command,
    { text = true, env = { PATH = os.getenv('HOME') .. '/.shims:' .. os.getenv('PATH') } },
    function(obj)
      local items = M.parse_arc_output(obj.stdout)
      local quickfix_items = {}
      for _, item in ipairs(items) do
        table.insert(quickfix_items, {
          filename = item.filepath,
          lnum = item.lnum,
          col = item.col,
          text = item.message,
        })
      end

      vim.schedule(function()
        vim.fn.setqflist(quickfix_items)
        vim.cmd.copen()
      end)
    end
  )
end

return M
