return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        blade = { "blade-formatter" },
        php = { { "pint", "php_cs_fixer" } },
      },
      formatters = {
        ["blade-formatter"] = {
          command = "blade-formatter",
          args = { "--stdin" },
          stdin = true,
        },
      },
    },
  },
}
