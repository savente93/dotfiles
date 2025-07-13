return {
  {
    dir = '~/projects/lua/zola.nvim',
    config = function()
      require 'zola'

      vim.keymap.set('n', '<leader>zh', function()
        require 'zola'
        vim.cmd [[checkhealth zola]]
      end)
    end,
  },
}
