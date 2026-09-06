return {
    {
      "neovim/nvim-lspconfig",
      opts = {
        servers = {
          bacon_ls = {
            enabled = true,
          },
          rust_analyzer = { enabled = true, cargo = { allFeatures = true } },
        },
      },
    },
  }