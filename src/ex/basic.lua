-------------------------------------------------------------------------------
-- modt.lua
--
-- author: Lawrence Hoffman
--
-- an example of how to write unit tests with bgtest
-------------------------------------------------------------------------------

local function add(a, b)
    return a+b
end


-- Tests have a specific signature, the take a test object, and return either
-- nil or a string. Returning nil indicates success, returning a string means
-- that the test failed, the string is shown as a message to the user.
local function t_add(t)
    
    t:Info("I'm an informative but oververly verbose message")
    
    if add(2, 2) == 4 then
        return
    end

    return "That doesn't add up"
end

local function t_bad(t)

    t:Warn("I'm going fail on purpose")
    return "OOPS!"
end

-- Check if we've been loaded by a test harness
if __TESTING then
    local Suite = __TESTING

    return Suite:New("example_basic")
        :Test("Good add", t_add)
        :Test("Bad add", t_bad)
        :Done()
end

-- Our totally normal return here
return {
    add = add
}
