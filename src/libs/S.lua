-------------------------------------------------------------------------------
-- S.lua
--
-- author: Lawrence Hoffman
--
-- Create test suites more cleanly
-------------------------------------------------------------------------------

local S = {}

-- Create a test suite
function S:New(sname)
    -- Init the suite 
    S.suite = {}
    S.suite.name = nil
    S.suite.tests = {}

    -- Make sure the name is a string
    assert(type(sname) == "string", "S:New expected string name")
    self.suite.name = name
    return self
end

-- Add a test to the suite
function S:Test(tname, tfn)
    assert(type(tname) == "string", "S:Test expected string name")
    assert(type(tfn) == "function", "S:Test expected function as second arg")
    local t = { name = tname, test = tfn }
    self.suite.tests[#self.suite.tests + 1] = t
    return self
end

-- Return the test suite
function S:Done()
    return { suite = self.suite }
end

return S
