return {
  'echasnovski/mini.nvim',
  config = function()
    require('mini.surround').setup()
    require('mini.splitjoin').setup()
    require('mini.bracketed').setup()
    require('mini.comment').setup()
    require('mini.pairs').setup()
    require('mini.jump').setup()
    require('mini.icons').setup()
  end,
}
