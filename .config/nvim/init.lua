-- require("config.options")
-- require("config.keymaps")
-- require("config.lazy")

-- Load legacy Vimscript config so both configs apply.
vim.cmd("source " .. vim.fn.stdpath("config") .. "/legacy.vim")
