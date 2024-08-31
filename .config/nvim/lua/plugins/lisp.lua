return {
  {
    "monkoose/nvlime",
    config = function()
      vim.g.nvlime_config = {
        cmp = {
          enabled = true,
        },
      }
    end,
  },
  { "monkoose/parsley" },
  { "kovisoft/paredit" },
}
