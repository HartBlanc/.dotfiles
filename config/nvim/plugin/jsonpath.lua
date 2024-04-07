local ts_utils = require('nvim-treesitter.ts_utils')
local treesitter = require('vim.treesitter')

-- A small plugin for getting the jsonpath of the node under the cursor in JSON and YAML buffers

local jsonpath = function(array_node_type)
  local current_node = ts_utils.get_node_at_cursor()
  local path = ''
  while current_node do
    if current_node:type():sub(-#'pair') == 'pair' then
      local key_node = current_node:field('key')[1]:named_child(0)
      local key = treesitter.get_node_text(key_node, 0)
      path = string.format('.%s%s', key, path)
    elseif current_node:parent() and current_node:parent():type():sub(-#array_node_type) == array_node_type then
      local count = 0
      local previous_sibling = ts_utils.get_previous_node(current_node)
      while previous_sibling do
        count = count + 1
        previous_sibling = ts_utils.get_previous_node(previous_sibling)
      end
      path = string.format('[%d]%s', count, path)
    end
    current_node = current_node:parent()
  end
  return path
end

vim.keymap.set('n', '<leader>jp', function()
  local array_node_type
  if vim.bo.filetype == 'json' then
    array_node_type = 'array'
  elseif vim.bo.filetype == 'yaml' then
    array_node_type = 'sequence'
  else
    vim.notify('unsupported filetype for jsonpath: ' .. vim.bo.filetype, vim.log.levels.ERROR)
    return
  end

  vim.notify(jsonpath(array_node_type), vim.log.levels.INFO)
end, { desc = 'Print [J]SON[P]ath of the node under the cursor' })
