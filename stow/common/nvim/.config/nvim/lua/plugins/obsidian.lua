return {
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        resolve = function(path, src)
          local ok, api = pcall(require, "obsidian.api")
          if ok and api.path_is_note(path) then
            return api.resolve_attachment_path(src)
          end
        end,
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- obsidian.nvim provides link, tag, reference, and completion support.
        marksman = { enabled = false },
      },
    },
  },

  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    cmd = "Obsidian",
    ft = "markdown",
    init = function()
      -- Keep Obsidian-specific behavior from replacing existing normal-mode keys.
      vim.g.obsidian_default_keymap = false
    end,
    keys = {
      { "<leader>o", "", desc = "+obsidian" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
      { "<leader>of", "<cmd>Obsidian quick_switch<cr>", desc = "Find note" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search notes" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Paste image" },
    },
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "personal",
          path = "~/Documents/obsidian-vault",
        },
      },
      picker = {
        name = "snacks.picker",
      },
      ui = {
        enable = false,
      },
      attachments = {
        folder = "attachments",
      },
      frontmatter = {
        enabled = false,
      },
      note_id_func = function(title, dir)
        return require("obsidian.builtin").title_id(title, dir)
      end,
      callbacks = {
        enter_note = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.breakindent = true
          vim.keymap.set("n", "gf", "<cmd>Obsidian follow_link<cr>", {
            buffer = true,
            desc = "Follow Obsidian link",
          })
        end,
      },
    },
  },
}
