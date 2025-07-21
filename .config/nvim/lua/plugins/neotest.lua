return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      {
        'mrcjkb/rustaceanvim',
        version = '^6', -- Recommended
      },
      'nvim-neotest/neotest-python',
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-python',
          require 'rustaceanvim.neotest',
        },

        vim.keymap.set('n', '<leader>nl', function()
          require('neotest').run.run_last()
        end),

        vim.keymap.set('n', '<leader>nt', function()
          require('neotest').run.run()
        end),
      }
    end,
  },
}
