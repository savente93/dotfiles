return {
  'savente93/zola.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    vim.keymap.set('n', '<leader>zbd', function()
      require('zola').build { drafts = true }
    end, { desc = 'Build version of site including drafts' })

    vim.keymap.set('n', '<leader>zbp', function()
      require('zola').build {}
    end, { desc = 'Build release version of site' })

    vim.keymap.set('n', '<leader>zc', function()
      require('zola').check {}
    end, { desc = 'Check the site' })

    vim.keymap.set('n', '<leader>zsp', function()
      require('zola').serve { drafts = true }
    end, { desc = 'Serve the release version of the site' })

    vim.keymap.set('n', '<leader>zsd', function()
      require('zola').serve { drafts = true }
    end, { desc = 'Serve the site with drafts' })
    vim.keymap.set('n', '<leader>zns', function()
      vim.ui.input({ prompt = 'Enter section slug: ' }, function(result)
        require('zola').create_section {
          slug = 'blog/' .. result,
          draft = true,
          open = true,
        }
      end)
    end, { desc = 'Create a new blog section' })

    vim.keymap.set('n', '<leader>znp', function()
      vim.ui.input({ prompt = 'Enter page slug: ' }, function(result)
        require('zola').create_page {
          slug = 'blog/' .. result,
          page_is_dir = true,
          draft = true,
          open = true,
        }
      end)
    end, { desc = 'Create a new blog post' })
  end,
}
