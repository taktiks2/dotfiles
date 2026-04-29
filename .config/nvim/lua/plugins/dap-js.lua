return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      dap.adapters["pwa-chrome"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
            "${port}",
          },
        },
      }

      local chrome_config = {
        {
          type = "pwa-chrome",
          request = "launch",
          name = "Launch Chrome (localhost:3000)",
          url = "http://localhost:3000",
          webRoot = "${workspaceFolder}/src",
          sourceMaps = true,
          sourceMapPathOverrides = {
            ["webpack:///src/*"] = "${webRoot}/*",
            ["webpack:///./*"] = "${workspaceFolder}/*",
          },
        },
        {
          type = "pwa-chrome",
          request = "attach",
          name = "Attach to Chrome (port 9222)",
          port = 9222,
          webRoot = "${workspaceFolder}/src",
          sourceMaps = true,
          sourceMapPathOverrides = {
            ["webpack:///src/*"] = "${webRoot}/*",
            ["webpack:///./*"] = "${workspaceFolder}/*",
          },
        },
      }

      dap.configurations.javascript = chrome_config
      dap.configurations.javascriptreact = chrome_config
      dap.configurations.typescriptreact = chrome_config
      dap.configurations.typescript = chrome_config
    end,
  },
}
