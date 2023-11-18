local status, mason = pcall(require, "mason")
if (not status) then return end
local status2, lspconfig = pcall(require, "mason-lspconfig")
if (not status2) then return end

mason.setup({})

lspconfig.setup({
  ensure_installed = {
    "astro",
    "prismals",
    "rust_analyzer",
    "marksman",
    "tsserver",
    "lua_ls",
    "bashls",
    "clangd",
    "eslint",
    "graphql",
    "jdtls",
  }
})
