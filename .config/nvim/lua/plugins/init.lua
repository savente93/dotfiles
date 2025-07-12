return {
  'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically
  {
    'navarasu/onedark.nvim',
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      local theme = require 'onedark'
      theme.setup {
        style = 'dark',
      }
      -- Enable theme
      theme.load()
    end,
  },
}
