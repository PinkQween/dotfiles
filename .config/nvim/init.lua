vim.opt.shortmess:append("I")

-- ========================================================================== --
-- 1. PLUGIN DECLARATION (using built-in vim.pack)
-- ========================================================================== --
vim.pack.add({
  'https://github.com/L3MON4D3/LuaSnip',
  { src = 'https://github.com/saghen/blink.cmp', version = '1.0.0 - 2.0.0' },
  'https://github.com/creativenull/efmls-configs-nvim',
  'https://www.github.com/ibhagwan/fzf-lua',
  'https://github.com/mason-org/mason.nvim',
  'https://www.github.com/echasnovski/mini.nvim',
  'https://www.github.com/neovim/nvim-lspconfig',
  'https://www.github.com/nvim-tree/nvim-tree.lua',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/obsidian-nvim/obsidian.nvim',
  'https://github.com/mrcjkb/rustaceanvim',
  'https://github.com/christoomey/vim-tmux-navigator',
})

-- Prepend Mason bin path to PATH
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Initialize Mason
require('mason').setup()

-- Initialize Blink.cmp autocomplete
require('blink.cmp').setup({
  keymap = { preset = 'default' },
  completion = {
    list = {
      selection = {
        preselect = false,
        auto_insert = true,
      },
    },
  },
})

local logo = {
  "  ░██ ░██░██                      ░██                 ",
  "  ░██    ░██                                          ",
  "  ░██ ░██░██ ░██    ░██░██    ░██ ░██░█████████████   ",
  "  ░██ ░██░██ ░██    ░██░██    ░██ ░██░██   ░██   ░██  ",
  "  ░██ ░██░██ ░██    ░██ ░██  ░██  ░██░██   ░██   ░██  ",
  "  ░██ ░██░██ ░██   ░███  ░██░██   ░██░██   ░██   ░██  ",
  "  ░██ ░██░██  ░█████░██   ░███    ░██░██   ░██   ░██  ",
  "                    ░██                               ",
  "               ░███████                               ",
}

local menu = {
  "		[ N ]						󰎔  Make New",
  "		[ Ctrl+F, Alt+F ]			  Find File",
  "		[ Q ]						  Quit",
}

local function center_line(text, screen_width)
  local display_width = vim.fn.strdisplaywidth(text)
  local left_padding = math.floor((screen_width - display_width) / 2)
  if left_padding < 0 then left_padding = 0 end
  return string.rep(" ", left_padding) .. text
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() > 0 or vim.bo.modified or vim.fn.line2byte("$") ~= -1 then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "vanilladash"

    local footer_text = ""

    if status then
      local loaded, failed, time = pacman.stats()
      footer_text = string.format("Packages loaded: %d ⬩ Failed: %d ⬩ Loaded in %.2fs", loaded, failed, time)
    end

    local screen_width = vim.api.nvim_get_option_value("columns", {})
    local screen_height = vim.api.nvim_get_option_value("lines", {})
    
    local total_content_height = #logo + #menu + (footer_text ~= "" and 1 or 0) + 4
    local top_padding = math.floor((screen_height - total_content_height) / 2) - 2

    local lines = {}
    local line_trackers = { logo = {}, menu = {}, footer = nil }

    for _ = 1, math.max(1, top_padding) do 
      table.insert(lines, "") 
    end
    
    for _, l in ipairs(logo) do 
      table.insert(lines, center_line(l, screen_width))
      table.insert(line_trackers.logo, #lines)
    end
    
    table.insert(lines, "") 
    table.insert(lines, "") 

    for _, b in ipairs(menu) do 
      table.insert(lines, center_line(b, screen_width))
      table.insert(line_trackers.menu, #lines)
    end
    
    table.insert(lines, "") 
    table.insert(lines, "") 

    if footer_text ~= "" then 
      table.insert(lines, center_line(footer_text, screen_width))
      line_trackers.footer = #lines
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false

    local ns_id = vim.api.nvim_create_namespace("vanilla_dash_colors")
    
    for _, line_num in ipairs(line_trackers.logo) do
      vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Special", line_num - 1, 0, -1)
    end
    
    for _, line_num in ipairs(line_trackers.menu) do
      vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Directory", line_num - 1, 0, -1)
    end
    
    if line_trackers.footer then
      vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Comment", line_trackers.footer - 1, 0, -1)
    end

    local opts = { silent = true, buffer = bufnr }
    vim.keymap.set("n", "N", ":ene <CR>", opts)
    vim.keymap.set("n", "<C-f>", ":Ex<CR>", opts) 
    vim.keymap.set("n", "<A-f>", ":Ex<CR>", opts) 
    vim.keymap.set("n", "Q", ":qa<CR>", opts)

    vim.api.nvim_create_autocmd("InsertEnter", {
      buffer = bufnr,
      once = true,
      callback = function()
        vim.bo[bufnr].modifiable = true
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
        vim.bo[bufnr].buftype = ""
        vim.bo[bufnr].filetype = ""
        vim.bo[bufnr].swapfile = true
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
      end
    })
  end,
})

vim.opt.termguicolors = true
vim.cmd.colorscheme("xcodedark")

vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.cursorline = true
vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.smartindent = true
vim.opt.autoindent = true

vim.g.mapleader = ","

vim.keymap.set({'n', 'v'}, '<C-c>', '"+y')
vim.keymap.set({'n', 'v'}, '<C-v>', '"+p')

vim.keymap.set('n', '<leader>l', function()
	local current_buf = vim.api.nvim_get_current_buf()

	vim.cmd('bnext')

	if vim.api.nvim_get_current_buf() == current_buf then
		vim.cmd('enew')
	end
end, { silent = true })

vim.keymap.set('n', '<leader>k', ':bprevious<CR>', { silent = true })

vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- ========================================================================== --
-- 2. LSP CORE CONFIGURATION (Neovim 0.11+ Style)
-- ========================================================================== --

-- Global Diagnostic Customization
vim.diagnostic.config({
  virtual_text = true,         -- Show inline diagnostic text
  signs = true,                -- Show signs in the gutter
  underline = true,            -- Underline text with errors
  update_in_insert = false,    -- Don't clutter while typing
  severity_sort = true,        -- Sort diagnostics by severity
})

-- Handle events when an LSP successfully connects to a buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable built-in omnifunc completion (triggered via Ctrl-X Ctrl-O)
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer-local keymaps for the active LSP
    local opts = { buffer = ev.buf, silent = true }
    
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)      -- Go to definition
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)     -- Go to declaration
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)  -- Go to implementation
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)      -- Find references
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)            -- Hover documentation
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)    -- Rename symbol
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, opts)-- Code actions
    
    -- Diagnostic navigation maps
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)    -- Next warning/error
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)    -- Prev warning/error
    vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts) -- Show line error float
  end,
})

-- ========================================================================== --
-- 3. SPECIFY & ENABLE LANGUAGE SERVERS (Modern Neovim 0.11+ Style)
-- ========================================================================== --

-- Configure settings for pyright
vim.lsp.config('pyright', {
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true
      }
    }
  }
})

local servers = {
  'pyright',
  'ts_ls',
  'lua_ls',
  'prismals',
}

-- Activate the servers
vim.lsp.enable(servers)

-- ========================================================================== --
-- MODERN TREE-SITTER CONFIGURATION (NO CONFIGS MODULE)
-- ========================================================================== --

-- 1. Explicitly turn on standard Vim regex syntax highlighting (Treesitter overrides this buffer-locally)
vim.cmd("syntax on")

-- 2. Modern initialization
require('nvim-treesitter').setup({})

-- 3. Automatically trigger Tree-sitter highlighting & indentation on FileType
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(ev)
    local bufnr = ev.buf
    local lang = vim.bo[bufnr].filetype
    local ok, _ = pcall(vim.treesitter.start, bufnr, lang)
    if ok then
      vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.filetype.add({
	extension = {
		prisma = "prisma",
	},
})
