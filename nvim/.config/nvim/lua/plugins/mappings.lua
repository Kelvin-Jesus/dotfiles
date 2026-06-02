return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      n = {
        ["<C-S>"] = { "<C-c>:update<cr>", desc = "Save File" },
      },
      i = {
        ["<C-S>"] = { "<C-c>:update<cr>", desc = "Save File" },
      },
      v = {
        ["<C-S>"] = { "<C-c>:update<cr>", desc = "Save File" },
      },
      -- Visual Mode Mappings
      x = {
        -- Move the selected text up and down with Alt+K and Alt+J
        -- ["<M-k>"] = {
          -- function() require("mini.move").move_selection_up() end,
          -- "Move Selection Up",
        -- },
        -- ["<M-j>"] = {
          -- function() require("mini.move").move_selection_down() end,
          -- "Move Selection Down",
        -- },
        -- -- Mover linha(s) selecionadas para baixo com Alt+J
        ["<M-j>"] = { ":move '>+1<CR>gv=gv", desc = "Move down one line" },
        ["<M-k>"] = { ":move '<-2<CR>gv=gv", desc = "Move up one line" },

      },
    },
  },
}
