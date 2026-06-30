local map = vim.keymap.set

map({ "n", "i", "v" }, "<C-s>", "<Esc><Cmd>update<CR>", {
  desc = "Save file",
  silent = true,
})

map("x", "<M-j>", ":move '>+1<CR>gv=gv", {
  desc = "Move selection down",
  silent = true,
})

map("x", "<M-k>", ":move '<-2<CR>gv=gv", {
  desc = "Move selection up",
  silent = true,
})
