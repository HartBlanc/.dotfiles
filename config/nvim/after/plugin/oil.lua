local oil = require('oil')
local git_root = require('util').git_root

local function get_paths_for_all_files_in_dir(dir)
  local relative_filepath = dir:gsub('^' .. git_root(), '')
  local output = vim.fn.system('fd --type=f -e=go . ' .. relative_filepath)
  local paths = {}
  for line in output:gmatch('[^\n]+') do
    table.insert(paths, line)
  end
  return paths
end

oil.setup({
  skip_confirm_for_simple_edits = false,
  keymaps = {
    -- default mappings
    ['g?'] = 'actions.show_help',
    ['<CR>'] = 'actions.select',
    ['<C-s>'] = false, -- 'actions.select_vsplit' (replaced with <c-v>)
    ['<C-h>'] = false, -- 'actions.select_split',
    ['<C-t>'] = false, -- 'actions.select_tab',
    ['<C-c>'] = 'actions.close',
    ['<C-l>'] = 'actions.refresh',
    ['-'] = 'actions.parent',
    ['`'] = false, -- 'actions.cd',
    ['~'] = false, -- 'actions.tcd',
    ['gs'] = 'actions.change_sort',
    ['gx'] = 'actions.open_external',
    ['g.'] = false, -- 'actions.toggle_hidden', (replaced with '.' below)
    ['g\\'] = false, -- 'actions.toggle_trash',

    -- replacements
    ['<C-v>'] = 'actions.select_vsplit',
    ['.'] = 'actions.toggle_hidden',

    -- additional mappings
    ['<C-p>'] = { desc = 'Move up', 'k' }, -- 'actions.preview', (actions.preview not available in float, repurposed for 'Move up')
    ['<C-n>'] = { desc = 'Move down', 'j' },
    ['_'] = { -- 'actions.open_cwd', (git root is a bit more useful than cwd)
      desc = 'Open git root',
      callback = function()
        oil.open(git_root(oil.get_current_dir()))
      end,
    },
    ['gd'] = {
      desc = 'Toggle detail view',
      callback = function()
        local config = require('oil.config')
        if #config.columns == 1 then
          oil.set_columns({ 'icon', 'permissions', 'size', 'mtime' })
        else
          oil.set_columns({ 'icon' })
        end
      end,
    },
    ['<C-g>'] = {
      desc = 'Live grep in telescope',
      callback = function()
        local dir = oil.get_current_dir()
        oil.close()
        if not dir then
          vim.notify('Cannot grep; not in a directory', vim.log.levels.WARN)
          return
        end
        require('telescope.builtin').live_grep({
          prompt_title = 'Live Grep in ' .. dir:gsub('^' .. os.getenv('HOME'), '~'),
          search_dirs = { dir },
        })
      end,
    },
    ['<C-f>'] = {
      desc = 'Find files in telescope',
      callback = function()
        local dir = oil.get_current_dir()
        oil.close()
        if not dir then
          vim.notify('Cannot find files; not in a directory', vim.log.levels.WARN)
          return
        end
        return require('telescope.builtin').find_files({
          prompt_title = 'Find Files in ' .. dir:gsub('^' .. os.getenv('HOME'), '~'),
          cwd = dir,
        })
      end,
    },
    ['<leader>pt'] = {
      desc = '[P]lease [T]est',
      callback = function()
        local dir = oil.get_current_dir()
        oil.close()

        if not dir then
          return
        end
        local relative_filepath = dir:gsub('^' .. git_root(), '')
        require('please').command('test', relative_filepath .. '...')
      end,
    },
    ['<leader>pb'] = {
      desc = '[P]lease [B]uild',
      callback = function()
        local dir = oil.get_current_dir()
        oil.close()

        if not dir then
          return
        end
        local relative_filepath = dir:gsub('^' .. git_root(), '')
        require('please').command('build', relative_filepath .. '...')
      end,
    },
    ['<leader>al'] = {
      desc = '[A]rc [L]int',
      callback = function()
        local dir = oil.get_current_dir()
        oil.close()

        if not dir then
          return {}
        end
        local paths = get_paths_for_all_files_in_dir(dir)
        require('arc-lint').arc_lint(paths)
      end,
    },
    ['<leader>zr'] = {
      desc = '[Z]ero [R]eferences',
      callback = function()
        local dir = oil.get_current_dir()
        oil.close()

        if not dir then
          return
        end
        local paths = get_paths_for_all_files_in_dir(dir)
        require('zero-references').process_paths(paths)
      end,
    },
  },
})

vim.keymap.set('n', '-', oil.open_float, { desc = 'Open oil in parent directory' })
vim.keymap.set('n', '_', function()
  oil.open_float(git_root())
end, { desc = 'Open oil in git root' })
