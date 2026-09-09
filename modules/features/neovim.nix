{
  self,
  ...
}:
{
  flake.modules.nixos.neovim =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      lazyvimIcon = "${self}/assets/lazyvim.svg";

      initLua = pkgs.writeText "nvim-init.lua" ''
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
      '';

      styluaToml = pkgs.writeText "nvim-stylua.toml" ''
        indent_type = "Spaces"
        indent_width = 2
        column_width = 120
      '';

      lazyLua = pkgs.writeText "nvim-lazy.lua" ''
        local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
        if not (vim.uv or vim.loop).fs_stat(lazypath) then
          local lazyrepo = "https://github.com/folke/lazy.nvim.git"
          local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
          if vim.v.shell_error ~= 0 then
            vim.api.nvim_echo({
              { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
              { out, "WarningMsg" },
              { "\nPress any key to exit..." },
            }, true, {})
            vim.fn.getchar()
            os.exit(1)
          end
        end
        vim.opt.rtp:prepend(lazypath)

        require("lazy").setup({
          spec = {
            -- add LazyVim and import its plugins
            { "LazyVim/LazyVim", import = "lazyvim.plugins" },
            -- import/override with your plugins
            { import = "plugins" },
          },
          defaults = {
            -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
            -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
            lazy = false,
            -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
            -- have outdated releases, which may break your Neovim install.
            version = false, -- always use the latest git commit
            -- version = "*", -- try installing the latest stable version for plugins that support semver
          },
          install = { colorscheme = { "tokyonight", "habamax" } },
          checker = {
            enabled = true, -- check for plugin updates periodically
            notify = false, -- notify on update
          }, -- automatically check for plugin updates
          performance = {
            rtp = {
              -- disable some rtp plugins
              disabled_plugins = {
                "gzip",
                -- "matchit",
                -- "matchparen",
                -- "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
              },
            },
          },
        })
      '';

      lspLua = pkgs.writeText "nvim-lsp.lua" ''
        return {
            {
              "neovim/nvim-lspconfig",
              opts = {
                servers = {
                  bacon_ls = {
                    enabled = true,
                  },
                  rust_analyzer = { enabled = true, cargo = { allFeatures = true } },
                  nil_ls = {
                    enabled = true,
                    settings = {
                      ["nil"] = {
                        formatting = { command = { "nixfmt" } },
                        nix = { flake = { autoArchive = true, autoEvalInputs = true } },
                      },
                    },
                  },
                },
              },
            },
          }
      '';

      noiceLua = pkgs.writeText "nvim-noice.lua" ''
        return {
          { "folke/noice.nvim", enabled = false },
        }
      '';

      nvimLua = pkgs.runCommand "nvim-lua" { } ''
        mkdir -p $out/config $out/plugins
        ln -s ${lazyLua} $out/config/lazy.lua
        ln -s ${lspLua} $out/plugins/lsp.lua
        ln -s ${noiceLua} $out/plugins/noice.lua
      '';

      lazyvimDesktop = pkgs.makeDesktopItem {
        name = "lazynvim";
        desktopName = "LazyVim";
        genericName = "Text Editor";
        comment = "Neovim configured with LazyVim";
        exec = "nvim %F";
        terminal = true;
        icon = "lazyvim-app";
        type = "Application";
        categories = [
          "Utility"
          "TextEditor"
          "Development"
        ];
        mimeTypes = [
          "text/plain"
          "text/x-makefile"
          "text/x-c"
          "text/x-c++"
          "application/x-shellscript"
        ];
      };

      lazyvimIconTheme = pkgs.runCommand "lazyvim-icon-theme" { } ''
        mkdir -p $out/share/icons/hicolor/scalable/apps
        cp ${lazyvimIcon} $out/share/icons/hicolor/scalable/apps/lazyvim-app.svg
      '';

      normalHomes = lib.pipe config.users.users [
        lib.attrValues
        (lib.filter (u: u.isNormalUser))
        (map (u: u.home))
      ];
    in
    {
      environment.sessionVariables.EDITOR = "nvim";
      environment.sessionVariables.VISUAL = "nvim";

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };

      system.activationScripts.lazyvimConfig = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.config/nvim"
          ln -sfn ${initLua} "$home/.config/nvim/init.lua"
          ln -sfn ${styluaToml} "$home/.config/nvim/stylua.toml"
          rm -rf "$home/.config/nvim/lua"
          ln -sfn ${nvimLua} "$home/.config/nvim/lua"
        done
      '';

      system.activationScripts.lazyvimDesktop = lib.stringAfter [ "users" ] ''
        for home in ${lib.escapeShellArgs normalHomes}; do
          mkdir -p "$home/.local/share/applications"
          ln -sfn ${lazyvimDesktop}/share/applications/lazynvim.desktop "$home/.local/share/applications/nvim.desktop"
        done
      '';

      environment.systemPackages = with pkgs; [
        lazyvimIconTheme
        gcc
        unzip
        wget
        curl
        tree-sitter
      ];
    };
}
