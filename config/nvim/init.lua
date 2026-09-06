-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")


require('lspconfig').lua_ls.setup {
    settings = {
      Lua = {
        diagnostics = {
          -- This tells the language server to recognize the `vim` global
          globals = { 'vim' },
        },
      },
    },
  }