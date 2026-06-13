vim.g.mapleader = " "

-- Lazy.nvim
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")

require("lazy").setup({
  ---------------------------------------------------------------------------
  -- Which-key
  ---------------------------------------------------------------------------
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  ---------------------------------------------------------------------------
  -- Markdown
  ---------------------------------------------------------------------------
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown" },
  },

  ---------------------------------------------------------------------------
  -- Telescope
  ---------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Oil
  ---------------------------------------------------------------------------
  {
    "stevearc/oil.nvim",
    dependencies = {
      { "nvim-mini/mini.icons", opts = {} },
    },
    opts = {},
    lazy = false,
  },

  ---------------------------------------------------------------------------
  -- Indent guides
  ---------------------------------------------------------------------------
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },

  ---------------------------------------------------------------------------
  -- Autopairs
  ---------------------------------------------------------------------------
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },

  ---------------------------------------------------------------------------
  -- Mason
  ---------------------------------------------------------------------------
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  ---------------------------------------------------------------------------
  -- Completion
  ---------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }),
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- Mason + LSP
  ---------------------------------------------------------------------------
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright",
          "jdtls",
          "marksman",
        },
        handlers = {
          function(server_name)
            lspconfig[server_name].setup({
              capabilities = capabilities,
            })
          end,
        },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- LSP Config
  ---------------------------------------------------------------------------
  { "neovim/nvim-lspconfig" },
})

-------------------------------------------------------------------------------
-- Keymaps
-------------------------------------------------------------------------------

-- Oil
vim.keymap.set("n", "-", "<CMD>Oil<CR>", {
  desc = "Open parent directory",
})

-- Telescope
local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", builtin.find_files, {
  desc = "Find files",
})

vim.keymap.set("n", "<leader>fg", builtin.live_grep, {
  desc = "Live grep",
})

vim.keymap.set("n", "<leader>fb", builtin.buffers, {
  desc = "Buffers",
})

vim.keymap.set("n", "<leader>fh", builtin.help_tags, {
  desc = "Help tags",
})

-- Clipboard
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p')

-------------------------------------------------------------------------------
-- LSP Keymaps
-------------------------------------------------------------------------------

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
})

-------------------------------------------------------------------------------
-- General Settings
-------------------------------------------------------------------------------

vim.opt.autoread = true
vim.opt.number = true

vim.api.nvim_create_user_command("Q", "q!", {})
