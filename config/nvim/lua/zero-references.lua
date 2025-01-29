local M = {}

local function find_symbols_with_zero_references(requester, uri, handler)
  requester('textDocument/documentSymbol', { textDocument = { uri = uri } }, function(err, symbols, _, _)
    if err then
      vim.api.nvim_err_writeln('Error when finding document symbols: ' .. err.message)
      handler({})
      return
    end

    if not symbols or vim.tbl_isempty(symbols) then
      vim.notify('No results from textDocument/documentSymbol', vim.log.levels.INFO)
      handler({})
      return
    end

    local results = {}
    local items = vim.lsp.util.symbols_to_items(symbols, 0)
    for _, item in pairs(items) do
      item.filename = vim.uri_to_fname(uri)
    end
    local remaining = #items
    local function check_item_for_references(item_num)
      local item = items[item_num]
      requester('textDocument/references', {
        position = {
          line = item.lnum - 1,
          character = item.col - 1,
        },
        textDocument = { uri = uri },
        context = { includeDeclaration = false },
      }, function(inner_err, locations, _, _)
        remaining = remaining - 1
        if inner_err then
          vim.notify(
            'Error when finding references: ' .. inner_err.message .. vim.inspect(item),
            vim.log.levels.WARNING
          )
        else
          results[item_num] = { no_refs = not locations or vim.tbl_isempty(locations), item = item }
        end

        if remaining == 0 then
          local quickfix_items = {}
          for _, result in pairs(results) do
            if result.no_refs then
              table.insert(quickfix_items, result.item)
            end
          end
          handler(quickfix_items)
          return
        end
      end)
    end
    for i = 1, #items do
      check_item_for_references(i)
    end
  end)
end

-- Function to process all files in a directory
M.process_paths = function(paths)
  local quickfix_items = {}
  local remaining = #paths

  local clients_by_name = {}
  local function process_file(pathnum)
    print(pathnum .. '/' .. #paths)
    local path = paths[pathnum]
    local abspath = vim.fn.fnamemodify(path, ':p')

    -- get existing buffer with name, or just create a temporary one
    local client
    local ft, _ = vim.filetype.match({ filename = path })
    if not ft then
      remaining = remaining - 1
      if remaining == 0 then
        vim.fn.setqflist(quickfix_items)
        vim.cmd.copen()
      end
      return
    end

    for name, config in pairs(require('lspconfig.configs')) do
      if not config.filetypes then
        goto continue
      end
      for _, supported_filetype in ipairs(config.filetypes) do
        if ft == supported_filetype then
          client = clients_by_name[name]
          if client then
            break
          end

          local clients = vim.lsp.get_clients({ name = name })
          if not vim.tbl_isempty(clients) then
            client = clients[1]
            clients_by_name[name] = client
            break
          end

          local root_dir = config.manager.config.root_dir
          if type(config.manager.config.root_dir) ~= 'string' then
            root_dir = root_dir(abspath)
          end
          local client_id, err = vim.lsp.start_client({
            name = name,
            cmd = config.manager.config.cmd,
            root_dir = root_dir,
          })
          if err or not client_id then
            vim.notify(err, vim.log.levels.WARN)
            return nil
          end
          client = vim.lsp.get_client_by_id(client_id)
          clients_by_name[name] = client
          break
        end
      end
      ::continue::
    end

    if client == nil then
      remaining = remaining - 1
      if remaining == 0 then
        vim.fn.setqflist(quickfix_items)
        vim.cmd.copen()
      end
      return
    end

    vim.defer_fn(function()
      find_symbols_with_zero_references(client.request, vim.uri_from_fname(abspath), function(file_items)
        for i = 1, #file_items do
          table.insert(quickfix_items, file_items[i])
        end

        remaining = remaining - 1
        if remaining == 0 then
          vim.fn.setqflist(quickfix_items)
          vim.cmd.copen()
        end
      end)
    end, 1000)
  end

  for i = 1, #paths do
    process_file(i)
  end
end

M.process_buffer = function(bufnr, handler)
  find_symbols_with_zero_references(
    function(m, p, h)
      vim.lsp.buf_request(bufnr, m, p, h)
    end,
    vim.uri_from_bufnr(bufnr),
    function(items)
      handler(items)
    end
  )
end

return M
