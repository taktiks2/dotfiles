local status, nvim_lsp = pcall(require, "lspconfig")
if (not status) then return end

local protocol = require('vim.lsp.protocol')


local on_attach = function(client, bufnr)
  -- format on save
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("Format", { clear = true }),
      buffer = bufnr,
      callback = function() vim.lsp.buf.formatting_seq_sync() end,
    })
  end
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    underline = true,
    virtual_text = false,
    signs = true,
    update_in_insert = false,
  }
)

-- TypeScript
nvim_lsp.tsserver.setup {
  on_attach = on_attach,
  filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
  cmd = { "typescript-language-server", "--stdio" },
  capabilities = capabilities,
}

-- Lua
nvim_lsp.lua_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- Bash
nvim_lsp.bashls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- C
nvim_lsp.clangd.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- ESLint
nvim_lsp.eslint.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- GraphQL
nvim_lsp.graphql.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- Java
nvim_lsp.jdtls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- Astro
nvim_lsp.astro.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- Prisma
nvim_lsp.prismals.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- Markdown
nvim_lsp.marksman.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- Rust
nvim_lsp.rust_analyzer.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
