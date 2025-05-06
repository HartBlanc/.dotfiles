-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = os.getenv('NERD_FONT') ~= nil

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
vim.opt.rtp:prepend(lazypath)

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field

-- [[ Configure and install plugins ]]
require('lazy').setup({
  {
    'marcuscaisey/please.nvim',
    dependencies = {
      'mfussenegger/nvim-dap',
    },
  },
  {
    'ray-x/lsp_signature.nvim', -- Show function signature when you type
    opts = {
      hint_enable = false,
    },
  },
  {
    'rcarriga/nvim-notify', -- fancy notification popups
    config = function()
      -- registers nvim-notify as the default notification provider
      vim.notify = require('notify')
    end,
  },
  {
    'yorickpeterse/nvim-pqf', -- pretty quickfix formatting
    opts = {},
  },
  {
    'stevearc/dressing.nvim', -- prettier ui.input and ui.select providers
    opts = {
      input = {
        insert_only = false, -- enables normal mode in ui.input
      },
    },
  },
  {
    'Wansmer/treesj', -- splitting/joining blocks of code like arrays, function calls, dictionaries, etc.
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      use_default_keymaps = false,
      max_join_length = 10000,
    },
  },
  {
    'stevearc/oil.nvim', -- file explorer that lets you edit your filesystem like a normal Neovim buffer.
  },
  {
    'chaoren/vim-wordmotion', -- CamelCase/snake_case/kebab-case word motions (a bit more robust than bkad/CamelCaseMotion)
    init = function()
      vim.g.wordmotion_prefix = '<leader>' -- e.g. di<leader>w
    end,
  },
  {
    'sindrets/diffview.nvim', -- Easily cycle through diffs for all modified files
    opts = {
      use_icons = vim.g.have_nerd_font,
    },
  },
  {
    'tpope/vim-fugitive', -- General purpose git interface
    config = function()
      vim.keymap.set('n', '<leader>gb', '<cmd>:Git blame<cr>')
    end,
  },
  {
    'lewis6991/gitsigns.nvim', -- Adds git related signs to the gutter, as well as utilities for managing changes
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
  {
    'nvim-telescope/telescope.nvim', -- Fuzzy Finder (files, LSP, etc)
    branch = 'master',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',
      },
      {
        'nvim-tree/nvim-web-devicons', -- Useful for getting pretty icons, but requires a Nerd Font.
        enabled = vim.g.have_nerd_font,
      },
    },
  },
  {
    'neovim/nvim-lspconfig', -- LSP Configuration & Plugins
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for neovim
      'williamboman/mason.nvim', -- installing LSPs and code formatters
      'williamboman/mason-lspconfig.nvim', -- provides mappings between lspconfig and mason
      'WhoIsSethDaniel/mason-tool-installer.nvim', -- ensures that LSPs and formatters are installed when opening neovim for the first time.

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim APIs
      { 'folke/neodev.nvim', opts = {} },
    },
  },
  {
    'stevearc/conform.nvim', -- Autoformaters
  },
  {
    'hrsh7th/nvim-cmp', -- Autocompletion
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'L3MON4D3/LuaSnip',
        build = 'make install_jsregexp',
      },
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-cmdline',

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      -- nvim-cmp source for neovim Lua API
      -- so that things like vim.keymap.set, etc. are autocompleted
      'hrsh7th/cmp-nvim-lua',

      -- If you want to add a bunch of pre-configured snippets,
      --    you can use this plugin to help you. It even has snippets
      --    for various frameworks/libraries/etc. but you will have to
      --    set up the ones that are useful for you.
      -- 'rafamadriz/friendly-snippets',
    },
  },

  {
    'folke/tokyonight.nvim', -- colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme('tokyonight-night')

      -- You can configure highlights by doing something like
      vim.cmd.hi('Comment gui=none')
    end,
  },
  {
    'folke/todo-comments.nvim', -- Highlight todo, notes, etc in comments
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {
      signs = false,
    },
  },
  {
    'echasnovski/mini.nvim', -- Collection of various small independent plugins/modules
  },

  {
    'nvim-treesitter/nvim-treesitter', -- Highlight, edit, and navigate code
    build = ':TSUpdate',
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'comment',
        'git_rebase',
        'gitcommit',
        'gitignore',
        'go',
        'gomod',
        'gosum',
        'gowork',
        'html',
        'java',
        'javascript',
        'json',
        'lua',
        'markdown',
        'make',
        'perl',
        'php',
        'promql',
        'proto',
        'python',
        'query',
        'regex',
        'ruby',
        'rust',
        'scheme',
        'sql',
        'ssh_config',
        'toml',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      },

      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      textobjects = {
        select = {
          enable = true,
          keymaps = {
            ['iv'] = '@literal_value.inner',
            ['av'] = '@literal_value.outer',
          },
        },
      },
    },
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)
    end,
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'nvim-treesitter/playground',
      { 'nvim-treesitter/nvim-treesitter-context', opts = {} },
    },
  },
  { 'mfussenegger/nvim-lint', ft = { 'go', 'sh' } },
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
      'TmuxNavigatorProcessList',
    },
    keys = {
      { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
      { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
      { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
      { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
      { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
    },
  },
}, {
  ui = {
    -- If you have a Nerd Font, set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
