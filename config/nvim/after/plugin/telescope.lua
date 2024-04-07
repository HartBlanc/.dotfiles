local actions = require('telescope.actions')
local builtin = require('telescope.builtin')
local entry_display = require('telescope.pickers.entry_display')
local layout = require('telescope.actions.layout')
local transform_mod = require('telescope.actions.mt').transform_mod

-- [[ Configure Telescope ]]

local custom_actions = transform_mod({
  open_first_qf_item = function(_)
    vim.cmd.cfirst()
  end,
})

--- Shortens the given path by either:
--- - making it relative if it's part of the cwd
--- - replacing the home directory with ~ if not
---@param path string
---@return string
local function shorten_path(path)
  local cwd = vim.fn.getcwd()
  if path == cwd then
    return ''
  end
  -- need to escape - since its a special character in lua patterns
  cwd = cwd:gsub('%-', '%%-')
  local relative_path, replacements = path:gsub('^' .. cwd .. '/', '')
  if replacements == 1 then
    return relative_path
  end
  local path_without_home = path:gsub('^' .. os.getenv('HOME'), '~')
  return path_without_home
end

-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup({
  defaults = {
    layout_config = {
      horizontal = {
        width = 0.9,
        height = 0.9,
        preview_width = 0.5,
      },
      vertical = { width = 0.9 },
    },
    borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
    mappings = {
      i = {
        ['<c-h>'] = layout.toggle_preview,
        ['<c-q>'] = actions.smart_send_to_qflist + actions.open_qflist + custom_actions.open_first_qf_item,
      },
      n = {
        ['<c-h>'] = layout.toggle_preview,
        ['<c-c>'] = actions.close,
        ['<c-n>'] = actions.move_selection_next,
        ['<c-p>'] = actions.move_selection_previous,
        ['<c-q>'] = actions.smart_send_to_qflist + actions.open_qflist + custom_actions.open_first_qf_item,
      },
    },
    prompt_prefix = ' 🔍 ',
    selection_caret = '  ',
    multi_icon = ' 🔘 ',
  },
  pickers = {
    find_files = {
      layout_config = {
        width = 0.6,
        height = 0.9,
      },
      previewer = false,
    },
    oldfiles = {
      layout_config = {
        width = 0.6,
        height = 0.9,
      },
      previewer = false,
      cwd_only = true,
      path_display = function(_, path)
        return shorten_path(path)
      end,
    },
    live_grep = {
      layout_config = {
        preview_width = 0.4,
      },
    },
    current_buffer_fuzzy_find = {
      layout_config = {
        preview_width = 0.4,
      },
    },
    lsp_references = {
      entry_maker = function(entry)
        local displayer = entry_display.create({
          separator = ' ',
          items = {
            { remaining = true }, -- filename
            { remaining = true }, -- line:col
            { remaining = true }, -- directory
          },
        })

        local make_display = function(entry)
          return displayer({
            vim.fs.basename(entry.filename),
            { entry.lnum .. ':' .. entry.col, 'TelescopeResultsLineNr' },
            { shorten_path(vim.fs.dirname(entry.filename)), 'TelescopeResultsLineNr' },
          })
        end

        return {
          valid = true,
          value = entry,
          ordinal = entry.filename .. entry.text,
          display = make_display,
          bufnr = entry.bufnr,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          text = entry.text,
          start = entry.start,
          finish = entry.finish,
        }
      end,
    },
    lsp_implementations = {
      entry_maker = function(entry)
        local displayer = entry_display.create({
          separator = ' ',
          items = {
            { remaining = true }, -- filename
            { remaining = true }, -- line:col
            { remaining = true }, -- directory
          },
        })

        local make_display = function(entry)
          return displayer({
            vim.fs.basename(entry.filename),
            { entry.lnum .. ':' .. entry.col, 'TelescopeResultsLineNr' },
            { shorten_path(vim.fs.dirname(entry.filename)), 'TelescopeResultsLineNr' },
          })
        end

        return {
          valid = true,
          value = entry,
          ordinal = entry.filename .. entry.text,
          display = make_display,
          bufnr = entry.bufnr,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          text = entry.text,
          start = entry.start,
          finish = entry.finish,
        }
      end,
    },
    lsp_definitions = {
      entry_maker = function(entry)
        local displayer = entry_display.create({
          separator = ' ',
          items = {
            { remaining = true }, -- filename
            { remaining = true }, -- directory
          },
        })

        local make_display = function(entry)
          local head = vim.fs.dirname(entry.filename)
          local tail = vim.fs.basename(entry.filename)
          head = shorten_path(head)
          return displayer({
            tail,
            { head, 'TelescopeResultsLineNr' },
          })
        end

        return {
          valid = true,
          value = entry,
          ordinal = entry.filename .. entry.text,
          display = make_display,
          bufnr = entry.bufnr,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          text = entry.text,
          start = entry.start,
          finish = entry.finish,
        }
      end,
    },
  },
})

-- Enable telescope extensions, if they are installed
pcall(require('telescope').load_extension, 'fzf')

-- keymaps for pickers (note that lsp keymaps are defined in plugin/lsp.lua)
vim.keymap.set('n', '<c-f>', builtin.find_files, { desc = 'Find [F]iles' })
vim.keymap.set('n', '<c-g>', builtin.live_grep, { desc = 'Find by [G]rep' })
vim.keymap.set('n', 'fo', builtin.oldfiles, { desc = '[F]ind [O]ldfiles' })
vim.keymap.set('n', 'ff', builtin.current_buffer_fuzzy_find, { desc = '[F]uzzy [F]ind in current buffer' })
vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
vim.keymap.set('n', '<leader>ht', builtin.help_tags, { desc = 'Find [H]elp [T]ags' })
vim.keymap.set('n', '<leader>f.', function()
  builtin.live_grep({ cwd = vim.fn.stdpath('config') .. '/../..' })
end, { desc = '[F]ind by grep in [.]files' })

local actions = require('telescope.actions')
local builtin = require('telescope.builtin')
local entry_display = require('telescope.pickers.entry_display')
local layout = require('telescope.actions.layout')
local transform_mod = require('telescope.actions.mt').transform_mod

-- [[ Configure Telescope ]]

local custom_actions = transform_mod({
  open_first_qf_item = function(_)
    vim.cmd.cfirst()
  end,
})

--- Shortens the given path by either:
--- - making it relative if it's part of the cwd
--- - replacing the home directory with ~ if not
---@param path string
---@return string
local function shorten_path(path)
  local cwd = vim.fn.getcwd()
  if path == cwd then
    return ''
  end
  -- need to escape - since its a special character in lua patterns
  cwd = cwd:gsub('%-', '%%-')
  local relative_path, replacements = path:gsub('^' .. cwd .. '/', '')
  if replacements == 1 then
    return relative_path
  end
  local path_without_home = path:gsub('^' .. os.getenv('HOME'), '~')
  return path_without_home
end

-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup({
  defaults = {
    layout_config = {
      horizontal = {
        width = 0.9,
        height = 0.9,
        preview_width = 0.5,
      },
      vertical = { width = 0.9 },
    },
    borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
    mappings = {
      i = {
        ['<c-h>'] = layout.toggle_preview,
        ['<c-q>'] = actions.smart_send_to_qflist + actions.open_qflist + custom_actions.open_first_qf_item,
      },
      n = {
        ['<c-h>'] = layout.toggle_preview,
        ['<c-c>'] = actions.close,
        ['<c-n>'] = actions.move_selection_next,
        ['<c-p>'] = actions.move_selection_previous,
        ['<c-q>'] = actions.smart_send_to_qflist + actions.open_qflist + custom_actions.open_first_qf_item,
      },
    },
    prompt_prefix = ' 🔍 ',
    selection_caret = '  ',
    multi_icon = ' 🔘 ',
  },
  pickers = {
    find_files = {
      layout_config = {
        width = 0.6,
        height = 0.9,
      },
      previewer = false,
    },
    oldfiles = {
      layout_config = {
        width = 0.6,
        height = 0.9,
      },
      previewer = false,
      cwd_only = true,
      path_display = function(_, path)
        return shorten_path(path)
      end,
    },
    live_grep = {
      layout_config = {
        preview_width = 0.4,
      },
    },
    current_buffer_fuzzy_find = {
      layout_config = {
        preview_width = 0.4,
      },
    },
    lsp_references = {
      entry_maker = function(entry)
        local displayer = entry_display.create({
          separator = ' ',
          items = {
            { remaining = true }, -- filename
            { remaining = true }, -- line:col
            { remaining = true }, -- directory
          },
        })

        local make_display = function(entry)
          return displayer({
            vim.fs.basename(entry.filename),
            { entry.lnum .. ':' .. entry.col, 'TelescopeResultsLineNr' },
            { shorten_path(vim.fs.dirname(entry.filename)), 'TelescopeResultsLineNr' },
          })
        end

        return {
          valid = true,
          value = entry,
          ordinal = entry.filename .. entry.text,
          display = make_display,
          bufnr = entry.bufnr,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          text = entry.text,
          start = entry.start,
          finish = entry.finish,
        }
      end,
    },
    lsp_implementations = {
      entry_maker = function(entry)
        local displayer = entry_display.create({
          separator = ' ',
          items = {
            { remaining = true }, -- filename
            { remaining = true }, -- line:col
            { remaining = true }, -- directory
          },
        })

        local make_display = function(entry)
          return displayer({
            vim.fs.basename(entry.filename),
            { entry.lnum .. ':' .. entry.col, 'TelescopeResultsLineNr' },
            { shorten_path(vim.fs.dirname(entry.filename)), 'TelescopeResultsLineNr' },
          })
        end

        return {
          valid = true,
          value = entry,
          ordinal = entry.filename .. entry.text,
          display = make_display,
          bufnr = entry.bufnr,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          text = entry.text,
          start = entry.start,
          finish = entry.finish,
        }
      end,
    },
    lsp_definitions = {
      entry_maker = function(entry)
        local displayer = entry_display.create({
          separator = ' ',
          items = {
            { remaining = true }, -- filename
            { remaining = true }, -- directory
          },
        })

        local make_display = function(entry)
          local head = vim.fs.dirname(entry.filename)
          local tail = vim.fs.basename(entry.filename)
          head = shorten_path(head)
          return displayer({
            tail,
            { head, 'TelescopeResultsLineNr' },
          })
        end

        return {
          valid = true,
          value = entry,
          ordinal = entry.filename .. entry.text,
          display = make_display,
          bufnr = entry.bufnr,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          text = entry.text,
          start = entry.start,
          finish = entry.finish,
        }
      end,
    },
  },
})

-- Enable telescope extensions, if they are installed
pcall(require('telescope').load_extension, 'fzf')

-- keymaps for pickers (note that lsp keymaps are defined in plugin/lsp.lua)
vim.keymap.set('n', '<c-f>', builtin.find_files, { desc = 'Find [F]iles' })
vim.keymap.set('n', '<c-g>', builtin.live_grep, { desc = 'Find by [G]rep' })
vim.keymap.set('n', 'fo', builtin.oldfiles, { desc = '[F]ind [O]ldfiles' })
vim.keymap.set('n', 'ff', builtin.current_buffer_fuzzy_find, { desc = '[F]uzzy [F]ind in current buffer' })
vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
vim.keymap.set('n', '<leader>ht', builtin.help_tags, { desc = 'Find [H]elp [T]ags' })
vim.keymap.set('n', '<leader>f.', function()
  builtin.live_grep({ cwd = vim.fn.stdpath('config') .. '/../..' })
end, { desc = '[F]ind by grep in [.]files' })

local actions = require('telescope.actions')
local builtin = require('telescope.builtin')
local entry_display = require('telescope.pickers.entry_display')
local layout = require('telescope.actions.layout')
local transform_mod = require('telescope.actions.mt').transform_mod

-- [[ Configure Telescope ]]

local custom_actions = transform_mod({
  open_first_qf_item = function(_)
    vim.cmd.cfirst()
  end,
})

--- Shortens the given path by either:
--- - making it relative if it's part of the cwd
--- - replacing the home directory with ~ if not
---@param path string
---@return string
local function shorten_path(path)
  local cwd = vim.fn.getcwd()
  if path == cwd then
    return ''
  end
  -- need to escape - since its a special character in lua patterns
  cwd = cwd:gsub('%-', '%%-')
  local relative_path, replacements = path:gsub('^' .. cwd .. '/', '')
  if replacements == 1 then
    return relative_path
  end
  local path_without_home = path:gsub('^' .. os.getenv('HOME'), '~')
  return path_without_home
end

-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup({
  defaults = {
    layout_config = {
      horizontal = {
        width = 0.9,
        height = 0.9,
        preview_width = 0.5,
      },
      vertical = { width = 0.9 },
    },
    borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
    mappings = {
      i = {
        ['<c-h>'] = layout.toggle_preview,
        ['<c-q>'] = actions.smart_send_to_qflist + actions.open_qflist + custom_actions.open_first_qf_item,
      },
      n = {
        ['<c-h>'] = layout.toggle_preview,
        ['<c-c>'] = actions.close,
        ['<c-n>'] = actions.move_selection_next,
        ['<c-p>'] = actions.move_selection_previous,
        ['<c-q>'] = actions.smart_send_to_qflist + actions.open_qflist + custom_actions.open_first_qf_item,
      },
    },
    prompt_prefix = ' 🔍 ',
    selection_caret = '  ',
    multi_icon = ' 🔘 ',
  },
  pickers = {
    find_files = {
      layout_config = {
        width = 0.6,
        height = 0.9,
      },
      previewer = false,
    },
    oldfiles = {
      layout_config = {
        width = 0.6,
        height = 0.9,
      },
      previewer = false,
      cwd_only = true,
      path_display = function(_, path)
        return shorten_path(path)
      end,
    },
    live_grep = {
      layout_config = {
        preview_width = 0.4,
      },
    },
    current_buffer_fuzzy_find = {
      layout_config = {
        preview_width = 0.4,
      },
    },
    lsp_references = {
      entry_maker = function(entry)
        local displayer = entry_display.create({
          separator = ' ',
          items = {
            { remaining = true }, -- filename
            { remaining = true }, -- line:col
            { remaining = true }, -- directory
          },
        })

        local make_display = function(entry)
          return displayer({
            vim.fs.basename(entry.filename),
            { entry.lnum .. ':' .. entry.col, 'TelescopeResultsLineNr' },
            { shorten_path(vim.fs.dirname(entry.filename)), 'TelescopeResultsLineNr' },
          })
        end

        return {
          valid = true,
          value = entry,
          ordinal = entry.filename .. entry.text,
          display = make_display,
          bufnr = entry.bufnr,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          text = entry.text,
          start = entry.start,
          finish = entry.finish,
        }
      end,
    },
    lsp_implementations = {
      entry_maker = function(entry)
        local displayer = entry_display.create({
          separator = ' ',
          items = {
            { remaining = true }, -- filename
            { remaining = true }, -- line:col
            { remaining = true }, -- directory
          },
        })

        local make_display = function(entry)
          return displayer({
            vim.fs.basename(entry.filename),
            { entry.lnum .. ':' .. entry.col, 'TelescopeResultsLineNr' },
            { shorten_path(vim.fs.dirname(entry.filename)), 'TelescopeResultsLineNr' },
          })
        end

        return {
          valid = true,
          value = entry,
          ordinal = entry.filename .. entry.text,
          display = make_display,
          bufnr = entry.bufnr,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          text = entry.text,
          start = entry.start,
          finish = entry.finish,
        }
      end,
    },
    lsp_definitions = {
      entry_maker = function(entry)
        local displayer = entry_display.create({
          separator = ' ',
          items = {
            { remaining = true }, -- filename
            { remaining = true }, -- directory
          },
        })

        local make_display = function(entry)
          local head = vim.fs.dirname(entry.filename)
          local tail = vim.fs.basename(entry.filename)
          head = shorten_path(head)
          return displayer({
            tail,
            { head, 'TelescopeResultsLineNr' },
          })
        end

        return {
          valid = true,
          value = entry,
          ordinal = entry.filename .. entry.text,
          display = make_display,
          bufnr = entry.bufnr,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          text = entry.text,
          start = entry.start,
          finish = entry.finish,
        }
      end,
    },
  },
})

-- Enable telescope extensions, if they are installed
pcall(require('telescope').load_extension, 'fzf')

-- keymaps for pickers (note that lsp keymaps are defined in plugin/lsp.lua)
vim.keymap.set('n', '<c-f>', builtin.find_files, { desc = 'Find [F]iles' })
vim.keymap.set('n', '<c-g>', builtin.live_grep, { desc = 'Find by [G]rep' })
vim.keymap.set('n', 'fo', builtin.oldfiles, { desc = '[F]ind [O]ldfiles' })
vim.keymap.set('n', 'ff', builtin.current_buffer_fuzzy_find, { desc = '[F]uzzy [F]ind in current buffer' })
vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
vim.keymap.set('n', '<leader>ht', builtin.help_tags, { desc = 'Find [H]elp [T]ags' })
vim.keymap.set('n', '<leader>f.', function()
  builtin.live_grep({ cwd = vim.fn.stdpath('config') .. '/../..' })
end, { desc = '[F]ind by grep in [.]files' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    -- A function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Jump to the definition of the word under your cursor.
    --  This is where a variable was first declared, or where a function is defined, etc.
    --  To jump back, press <C-t>.
    map('gd', function()
      require('telescope.builtin').lsp_definitions({
        jump_type = 'never', -- nice to have a preview before jumping
      })
    end, '[G]oto [D]efinition')

    -- Find references for the word under your cursor.
    map('gr', function()
      require('telescope.builtin').lsp_references({ jump_type = 'never' })
    end, '[G]oto [R]eferences')

    -- Jump to the implementation of the word under your cursor.
    --  Useful when your language has ways of declaring types without an actual implementation.
    map('gI', function()
      require('telescope.builtin').lsp_implementations({ jump_type = 'never' })
    end, '[G]oto [I]mplementation')

    -- Jump to the type of the word under your cursor.
    --  Useful when you're not sure what type a variable is and you want to see
    --  the definition of its *type*, not where it was *defined*.
    map('gt', function()
      require('telescope.builtin').lsp_type_definitions({ jump_type = 'never' })
    end, '[G]oto [T]ype definition')

    -- Fuzzy find all the symbols in your current document.
    --  Symbols are things like variables, functions, types, etc.
    map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  end,
})
