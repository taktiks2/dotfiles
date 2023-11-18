local status, name = pcall(require, "say-my-name")
if (not status) then return end

name.setup({})
