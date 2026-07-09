local o = vim.opt
vim.g.mapleader = ' '          -- space is the leader key
o.tabstop = 2                  -- a tab displays as 2 columns
o.shiftwidth = 2               -- indent/unindent by 2 columns
o.softtabstop = 2              -- tab key inserts 2 columns
o.expandtab = false            -- use real tab characters, not spaces
o.number = true                -- absolute number on the cursor line, relative elsewhere
o.relativenumber = true        -- relative line numbers for fast jumps
o.ignorecase = true            -- search is case-insensitive by default
o.smartcase = true             -- case-sensitive only if i type a capital
o.clipboard = 'unnamedplus'    -- share the system clipboard
o.scrolloff = 16               -- keep cursor away from the screen edge
o.undofile = true              -- persistent undo across sessions

