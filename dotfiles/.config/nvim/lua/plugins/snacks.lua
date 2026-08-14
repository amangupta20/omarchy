return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      -- By default, snacks.nvim hides dotfiles and gitignored files.
      -- This setting tells it to show them.
      ignored = true, -- Setting this to false shows everything
      hidden = true,
    },
  },
}
