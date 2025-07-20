return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup {
      globalstatus = true,
      component_separators = { left = '', right = '' },
      section_separators = { left = '', right = '' },
      sections = {
        lualine_a = {},
        lualine_b = { 'branch', 'diagnostics' },
        lualine_c = {},
        lualine_x = { 'lsp_status' },
        lualine_y = {},
        lualine_z = { 'location', 'searchcount' },
      },
      tabline = {

        lualine_b = {
          {
            'buffers',
            symbols = {
              alternate_file = '',
              directory = '',
            },
          },
        },
      },
    }
  end,
}
