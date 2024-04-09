local util = require('lspconfig.util')

-- Enable the following language servers
--  Add any additional override configuration in the following tables. Available keys are:
--  - cmd (table): Override the default command used to start the server
--  - filetypes (table): Override the default list of associated filetypes for the server
--  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
--  - settings (table): Override the default settings passed when initializing the server.
--        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
--

local servers = {
  yamlls = {},
  vimls = {},
  bashls = {},
  intelephense = {},
  gopls = {
    settings = {
      gopls = {
        directoryFilters = { '-plz-out' },
        linksInHover = false,
        usePlaceholders = false,
        semanticTokens = true,
        codelenses = {
          gc_details = true,
        },
      },
    },
    root_dir = function(fname)
      local gowork_or_gomod_dir = util.root_pattern('go.work', 'go.mod')(fname)
      if gowork_or_gomod_dir then
        return gowork_or_gomod_dir
      end

      local plzconfig_dir = util.root_pattern('.plzconfig')(fname)
      if plzconfig_dir and vim.fs.basename(plzconfig_dir) == 'src' then
        vim.env.GOPATH = string.format('%s:%s/plz-out/go', vim.fs.dirname(plzconfig_dir), plzconfig_dir)
        vim.env.GO111MODULE = 'off'
        return plzconfig_dir .. '/vault' -- hack to work around slow monorepo
      end

      return vim.fn.getcwd()
    end,
  },
  pyright = {
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = 'workspace',
          useLibraryCodeForTypes = true,
          typeCheckingMode = 'off',
          extraPaths = {
            '/home/callum/core3/src',
            '/home/callum/core3/src/plz-out/gen',
          },
        },
      },
    },
    root_dir = function()
      return vim.fn.getcwd()
    end,
  },
  lua_ls = {
    -- cmd = {...},
    -- filetypes { ...},
    -- capabilities = {},
    settings = {
      Lua = {
        completion = {
          callSnippet = 'Replace',
        },
        -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
        -- diagnostics = { disable = { 'missing-fields' } },
      },
    },
  },
}

-- Ensure the servers and tools above are installed
--  To check the current status of installed tools and/or manually install
--  other tools, you can run
--    :Mason
--
--  You can press `g?` for help in this menu
require('mason').setup()

-- You can add other tools here that you want Mason to install
-- for you, so that they are available from within Neovim.
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  'stylua', -- Used to format lua code
  'black',
  'goimports',
  'prettier',
})
require('mason-tool-installer').setup({ ensure_installed = ensure_installed })

-- LSP servers and clients are able to communicate to each other what features they support.
--  By default, Neovim doesn't support everything that is in the LSP Specification.
--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

require('mason-lspconfig').setup({
  handlers = {
    function(server_name)
      local server = servers[server_name] or {}
      -- This handles overriding only values explicitly passed
      -- by the server configuration above. Useful when disabling
      -- certain features of an LSP (for example, turning off formatting for tsserver)
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      require('lspconfig')[server_name].setup(server)
    end,
  },
})

-- Defines and sets up the the please language server (this is the only one that is not inlcuded in lspconfig.configs by
-- default, and is also not included in mason)
require('lspconfig.configs').please = {
  default_config = {
    cmd = { 'plz', 'tool', 'lps' },
    filetypes = { 'please' },
    root_dir = util.root_pattern('.plzconfig'),
  },
}
require('lspconfig').please.setup({})
