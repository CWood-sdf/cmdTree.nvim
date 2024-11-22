--- from folke/noice.nvim
local M = {}


function M.root(root)
    local f = debug.getinfo(1, "S").source:sub(2)
    return vim.fn.fnamemodify(f, ":p:h:h") .. "/" .. (root or "")
end

---@param plugin string
function M.load(plugin)
    local name = plugin:match(".*/(.*)")
    local package_root = M.root(".tests/site/pack/deps/start/")
    if not vim.loop.fs_stat(package_root .. name) then
        print("Installing " .. plugin)
        vim.fn.mkdir(package_root, "p")
        -- local isDone = false
        vim.cmd(
            "!git clone --depth=1 https://github.com/" ..
            plugin ..
            ".git " ..
            package_root ..
            name --, {
        --     on_exit = function()
        --         print("DOne")
        --         isDone = true
        --     end,
        -- }
        )
        -- while not isDone do
        --     vim.uv.sleep(1000)
        -- end
    end
end

function M.setup()
    vim.cmd([[set runtimepath=$VIMRUNTIME]])
    vim.opt.runtimepath:append(M.root())
    vim.opt.packpath = { M.root(".tests/site") }

    M.load("nvim-lua/plenary.nvim")
    -- M.load("nvim-treesitter/nvim-treesitter")

    vim.env.XDG_CONFIG_HOME = M.root(".tests/config")
    vim.env.XDG_DATA_HOME = M.root(".tests/data")
    vim.env.XDG_STATE_HOME = M.root(".tests/state")
    vim.env.XDG_CACHE_HOME = M.root(".tests/cache")
end

M.setup()
