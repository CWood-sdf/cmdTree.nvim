# cmdTree.nvim

A simple library that allows you to create your commands in a declarative way that represents how the command is structured. It also provides autocompletion support for your commands.

## Installation

CmdTree can either be added as a dependency to your project, or you can copy the init.lua file to your project.

## Setup

Just create a tree (as described in numerous ways below), and call `require('cmdTree').createCmd(tree)`

The `.setup()` function is really only for testing purposes

## Usage

CmdTree allows basic command/subcommand structuring

### Basic Command Structuring example

The most basic way of using cmdTree is to have a command that has subcommands. This is done by creating a table that represents the command tree, and then calling `cmdTree.createCmd` with the tree and the options.

```lua

local tree = {
    Cmd = {
        subcommand = {
            _callback = function(args)
                print("subcommand was called")
            end,
        },
        other = {
            subcommand = {
                _callback = function(args)
                    print("other.subcommand was called")
                end,
            },
            _callback = function(args)
                print("other was called")
            end,
        },
        _callback = function(args)
            print("Cmd was called")
        end,
    },
}

local cmdTree = require("cmdTree")
cmdTree.createCmd(tree, {})

```

This command can be called in the following ways:

```
:Cmd
:Cmd subcommand
:Cmd other
:Cmd other subcommand
```

However, if one of the levels did not have a \_callback property, cmdTree will not allow it to be executed:

```lua
local tree = {
    Cmd = {
        subcommand = {
            _callback = function(args)
                print("subcommand was called")
            end,
        },
        other = {
            _callback = function(args)
                print("other.subcommand was called")
            end,
        },
    },
}

cmdTree.createCmd(tree, {})
```

This will throw an error if you try to call `:Cmd` because `:Cmd` does not have a \_callback property.

## Parameters

CmdTree also allows each subcommand to have parameters.

There are five kinds of parameters that commands can have:

1. Required parameters: These are parameters that are required for the command to work. If they are not provided, the command will not be executed and throw an error.
2. Repeated parameters: These are parameters that can be repeated. This may sound not useful, but for each repeat, the parameters allowed are regenerated. This is useful if you have a command that is traversing a tree or something similar.
3. Optional parameters: These parameters are not required for the command to run, however there can only be one, and it must be the last parameter.
4. Positional parameters: These are parameters that must be at a specific index in the parameter list and can take any value
5. Flags: these are parameters that are optional and can be repeated as many times as needed

### Required parameters example

Say we want a command that can say hello world in multiple different ways. We can use required parameters to force the user to type in the greeting and the world.

```lua
local greetings = {
    "hello",
    "hi",
    "hey",
}
local world = {
    "world",
    "earth",
    "planet",
}

local cmdTree = require("cmdTree")
local tree = {
    Cmd = {
        _callback = function(args)
            print(args.params[1][1] .. " " .. args.params[2][1])
        end,
        cmdTree.requiredParams(function()
            return greetings
        end),
        cmdTree.requiredParams(function()
            return world
        end),
    },
}

cmdTree.createCmd(tree, {})

```

This creates a command that can be called like this:

```
:Cmd hello world
```

or like this:

```
:Cmd hi planet
```

but will error if one of the parameters is left out or spelled wrong.

### Repeat parameters example

Say you have a command that traverses an object tree, but you do not want to have a parameter of all the possible objects shown at once in the autocomplete as that's overwhelming, so you have a space between each property. You can use the following code to achieve this:

```lua
local objectTree = {
    topLevel1 = {
        subLevel1 = {
            subSubLevel1 = {
            }
        }
    },
    topLevel2 = {
    },
    topLevel3 = {
        subLevel3 = {
        }
    }
}

local cmdTree = require("cmdTree")

local tree = {
    Traverse = {
        cmdTree.repeatParams(function(args)
            local currentObject = objectTree
            --- args.params[1] will be nil on the first call because there have been no parameters
            for _, arg in ipairs(args.params[1] or {}) do
                if currentObject[arg] then
                    currentObject = currentObject[arg]
                else
                    ---Returning nil tells cmdTree that the "loop" that repeatParams is in
                    ---should be "break"ed out of
                    return nil
                end
            end
            local ret = {}
            for k, _ in pairs(currentObject) do
                table.insert(ret, k)
            end
            return ret
        end),
        _callback = function(args)
            -- Do something with the args
        end,
    },
}
cmdTree.createCmd(tree, {})
```

This will create a command that can be called like this:

```
:Traverse topLevel1 subLevel1 subSubLevel1
```

And there will be autocompletion all the way down the tree, with almost no effort on your part.

#### Repeat parameters example (2)

Since the above example isnt particularly easy to follow, here's another example:

```lua

local cmdTree = require("cmdTree")

local tree = {
    Traverse = {
        cmdTree.repeatParams(function(args)
            if args.params[1] == nil then
                return { "1" }
            end
            local num = tonumber(args.params[1][#args.params[1]])
            if num > 5 then
                return nil
            end
            return { (num + 1) .."" }
        end),
        _callback = function(args)
            -- Do something with the args
        end,
    },
}
cmdTree.createCmd(tree, {})
```

This will create a command that can be called like this:

```
:Traverse 1 2 3 4 5 6
```

### Optional parameters example

Say you have a command that can take a flag, but it's not required. You can use the following code to achieve this:

```lua
local cmdTree = require("cmdTree")

local tree = {
    Cmd = {
        cmdTree.optionalParams(function()
            return {"-f"}
        end),
        _callback = function(args)
            if args.params[1][1] == "-f" then
                print("Flag was provided")
            else
                print("Flag was not provided")
            end
        end,
    },
}

cmdTree.createCmd(tree, {})
```

This will create a command that can be called like this:

```
:Cmd -f
```

or like this:

```
:Cmd
```

In autocompletion, the user will be presented with either the choice of inserting the flag or a space.

### Positional Parameters example

Positional parameters are parameters that must be at some specific index and can take any value

For example, the shell command `rm` has a positional paramter of a filename

Positional parameters, since they can take any value, only suggest `[name]` as their autocompletion, where the value of `name` is the parameter to the positionalParam function

```lua
local cmdTree = require("cmdTree")

local tree = {
    Cmd = {
        cmdTree.positionalParam("word", true),
        _callback = function(args)
            print("The passed word is " .. args.params[1][1])
        end,
    },
}

cmdTree.createCmd(tree, {})
```

That creates a command that can be called like:

```
:Cmd hello
```

Positional parameters can also be optional, this can be done by setting the second argument to `positionalParam` to `false`. Optional positional parameters are not allowed to preceded required positional parameters, repeated parameters, or required parameters:

```lua
local cmdTree = require("cmdTree")

local tree = {
    Cmd = {
        cmdTree.positionalParam("word", false),
        _callback = function(args)
            print("The passed word is " .. (args.params[1] or {"no param"})[1])
        end,
    },
}

cmdTree.createCmd(tree, {})
```

That creates a command that can be called like:

```
:Cmd hello
```

or

```
:Cmd
```

### Flag examples

You can also allow flags to be passed to the declared command. Flags _MUST_ be the last declared parameters to a subtree, however they can be put in the command in any order.

```lua
local cmdTree = require("cmdTree")

local tree = {
    Cmd = {
        cmdTree.positionalParam("word", true),
        cmdTree.flagParam({ '-f', '-r', '-a', '-b' }),
        _callback = function(args)
            print("The passed word is " .. args.params[1][1])
            -- all flags, no matter placement in argument list will end up in the proper params index
            print("The passed flags are: " .. vim.inspect(args.params[2]))
        end,
    },
}

cmdTree.createCmd(tree, {})
```

This creates a command that can be called like:

```
:Cmd -f -r asdf
```

or

```
:Cmd asdf -f -r -a
```

or

```
:Cmd -b asdf -a
```

## Api

### cmdTree.createCmd

This function creates a command from a tree. It takes two arguments, the tree and the options. The options are the same as the options for [`vim.api.nvim_create_user_command`](<https://neovim.io/doc/user/api.html#nvim_create_user_command()>) except for the buffer property, which can be a boolean or a number. If it is a number, it will create the command in that buffer, if it is a boolean, it will create the command in the current buffer.

### tree.\_callback

This is the callback that is called when the command is executed. It takes one argument, which is the same table that is passed to the callback of [`vim.api.nvim_create_user_command`](<https://neovim.io/doc/user/api.html#nvim_create_user_command()>), except for the `params` property.

The `params` property is an array of string arrays. The params property holds the parameters that were passed to the command. Each index of the params array is an array of the values given for that parameter. If the parameter is a repeat parameter, the array will have multiple values, if it is a required parameter, it will have one value, and if it is an optional parameter, it will have one value if the parameter was given, and nil or empty if it was not.

### cmdTree.requiredParams

This function takes a function that returns an array of strings. The function is called when the command is executed, and the array of strings is used for autocompletion. The function is given the same argument as the callback.

### cmdTree.repeatParams

This function takes a function that returns an array of strings. The function is called when the command is executed, and the array of strings is used for autocompletion. The function is given the same argument as the callback. If the function returns nil, the "loop" will be exited early. RepeatParams can also be given a second argument that is the maximum number of times the parameter can be repeated.

### cmdTree.optionalParams

This function takes a function that returns an array of strings. The function is called when the command is executed, and the array of strings is used for autocompletion. The function is given the same argument as the callback.
