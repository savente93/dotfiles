return {
  'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically
  'nvim-telescope/telescope-ui-select.nvim',
  'nvim-tree/nvim-web-devicons',
  'nvim-neotest/neotest-python',
  {
    'navarasu/onedark.nvim',
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('onedark').setup {
        style = 'dark',
      }
      -- Enable theme
      require('onedark').load()
    end,
  },
}
