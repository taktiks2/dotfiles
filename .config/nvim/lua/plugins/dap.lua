return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      dap.adapters.php = {
        type = "executable",
        command = "node",
        args = { require("mason-registry").get_package("php-debug-adapter"):get_install_path() .. "/extension/out/phpDebug.js" },
      }

      dap.configurations.php = {
        {
          type = "php",
          request = "launch",
          name = "Listen for Xdebug",
          port = 9003,
          pathMappings = {
            -- Docker使用時はここでマッピングを設定
            -- ["/var/www/html"] = "${workspaceFolder}",
          },
        },
        {
          type = "php",
          request = "launch",
          name = "Listen for Xdebug (Laravel Sail)",
          port = 9003,
          pathMappings = {
            ["/var/www/html"] = "${workspaceFolder}",
          },
        },
      }
    end,
  },
}
