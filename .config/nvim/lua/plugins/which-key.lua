return { -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',
  event = 'VimEnter', -- Sets the loading event to 'VimEnter'
  opts = {
    delay = 0,
    icons = {
      mappings = vim.g.have_nerd_font,
      keys = {},
    },

    -- Document existing key chains
    spec = {
      { '<leader>f', group = '[F]ile' },
      { '<leader>c', group = '[C]onfig' },
      { '<leader>d', group = '[D]ebug' },
    },
  },
}
