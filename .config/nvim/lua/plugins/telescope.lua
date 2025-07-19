return { -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',

      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  config = function()
    -- [[ Configure Telescope ]]
    require('telescope').setup {
      defaults = require('telescope.themes').get_ivy { layout_config = { height = 0.75 } },
      pickers = {
        find_files = {
          -- I often want to search in hidden dirs like .config
          -- but not in .git
          find_command = {
            'fd',
            '--type',
            'f',
            '--hidden',
            '--follow',
            '--exclude',
            '.git',
          },
        },
        live_grep = {
          additional_args = {
            '--hidden',
            '--iglob=!.git',
          },
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
    pcall(require('telescope').load_extension, 'persisted')

    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>hs', builtin.help_tags, { desc = '[H]elp [S]earch' })
    vim.keymap.set('n', '<leader>fs', builtin.live_grep, { desc = '[F]ile [S]earch' })
    vim.keymap.set('n', '<leader>ks', builtin.keymaps, { desc = '[K]eymap [S]earch' })
    vim.keymap.set('n', '<leader>fo', function()
      builtin.find_files { hidden = true }
    end, { desc = '[F]ile [O]pen' })
    vim.keymap.set('n', '<leader>bo', builtin.buffers, { desc = '[B]uffer [O]pen' })

    vim.keymap.set('n', '<leader>ns', function()
      builtin.live_grep { cwd = vim.fn.stdpath 'config' }
    end, { desc = 'Search config files' })
  end,
}
