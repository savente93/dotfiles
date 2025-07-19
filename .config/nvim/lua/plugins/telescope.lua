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
    -- Two important keymaps to use while in Telescope are:
    --  - Insert mode: <c-/>
    --  - Normal mode: ?
    --
    -- This opens a window that shows you all of the keymaps for the current
    -- Telescope picker. This is really useful to discover what Telescope can
    -- do as well as how to actually do it!

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
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>st', builtin.live_grep, { desc = '[S]earch [T]ext' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymap' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>of', function()
      builtin.find_files { hidden = true }
    end, { desc = '[O]pen [F]iles' })
    vim.keymap.set('n', '<leader>ob', builtin.buffers, { desc = '[O]pen [B]uffer' })

    vim.keymap.set('n', '<leader>sc', function()
      builtin.live_grep { cwd = vim.fn.stdpath 'config' }
    end, { desc = 'Search config files' })
  end,
}
