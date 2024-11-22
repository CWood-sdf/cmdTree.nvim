-- a test file that serves as a template for other tests

local M = require("cmdTree")
--- this is here for testing purposes only
---@type CmdTree.CmdTree
local testTree = {
    Test = {
        idk = {
            asdf = {
                _callback = function(args)
                    print(vim.inspect(args.params))
                end,

            },
            _callback = function(args)
                print(vim.inspect(args.params))
            end,
            M.positionalParam("name", true),
            M.positionalParam("asdf", false),
            M.positionalParam("asdf2", false),
            M.optionalParams(function()
                return { "a", 'b', 'c' }
            end),
            M.flagParam({ '-f', '-v', '-a', '-b' }),
        },
        thing = {
            _callback = function(args)
                print("yeet " .. #args.params)
            end,

            M.requiredParams(function()
                return { "yeet", "yote", "huh" }
            end),
            M.requiredParams(function(args)
                if args.params[1][1] == "yeet" then
                    return { "req_yeet" }
                elseif args.params[1][1] == "yote" then
                    return { "req_yote" }
                end
                return { "huh" }
            end),
            M.repeatParams(function(args)
                if args.params[1][1] == "yeet" then
                    return { "sdf" }
                elseif args.params[1][1] == "yote" then
                    return { "yotesdf" }
                end
                return nil
            end, 2),
            M.optionalParams(function(args)
                if args.params[2][1] == "yeet" then
                    return { "yeet" }
                end
                return { "optional" }
            end),

        },
        br = {
            qq = {
                _callback = function(args)
                    print("br qq " .. #args.params)
                end,
                M.requiredParams(function()
                    return { "br", "qq" }
                end),
            },
            _callback = function(args)
                print("br " .. #args.fargs)
            end,
            M.repeatParams(function()
                return nil
            end),
            M.requiredParams(function()
                return { "required" }
            end),
            -- M.repeatParams(function(args)
            --     return nil
            -- end),
            M.optionalParams(function()
                return { "optional" }
            end),
        },
        opt = {
            _callback = function(args)
                print("opt " .. #args.fargs)
            end,
            M.optionalParams(function()
                return { "sdfsd" }
            end),
        },
        _callback = function(args)
            print("main " ..
                -- #args.fargs ..
                -- " " ..
                -- args.count ..
                -- " " ..
                -- (args.bang and "true" or "false") ..
                " " ..
                args.reg .. " " .. vim.inspect(args.fargs))
        end,
        M.requiredParams(function()
            return { "required" }
        end),
    }
}
M.createCmd(testTree)

---@param str string
---@param arr2 string[]
local function isGood(str, arr2)
    local arr1 = vim.fn.getcompletion(str, "cmdline")
    if #arr1 ~= #arr2 then
        error("The two arrays did not match sizes: " .. vim.inspect(arr1) .. " :: " .. vim.inspect(arr2))
    end
    for _, v in ipairs(arr1) do
        local found = false
        for _, x in ipairs(arr2) do
            if x == v then
                found = true
                break
            end
        end
        if not found then
            error("Could not find '" .. v .. "' in arr2: " .. vim.inspect(arr1) .. " :: " .. vim.inspect(arr2))
        end
    end
end

describe("template test", function()
    it("subtrees and other args", function()
        isGood("Test ", { "required", "idk", "thing", "br", "opt" })
    end)
    it("done", function()
        isGood("Test required ", {})
    end)
    it("match filter", function()
        isGood("Test r", { "required" })
    end)
end)
describe("positional test", function()
    it("idk", function()
        isGood("Test idk ", { "asdf", "[name]", "-f", '-v', '-a', '-b' })
    end)
end)
