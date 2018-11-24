-------------------------------------------------------------------------------
-- file: test.lua
--
-- author: Lawrence Hoffman
--
-- Define the testing interface
-------------------------------------------------------------------------------

-- Logging level definition see tprint documentation for more
local LogLevel = {
    INFO    = 0;
    DEBUG   = 1;
    WARN    = 2;
    ERROR   = 3;
    FATAL   = 4;
    PASS    = 5;
    FAIL    = 6;
    SILENT  = 5;
}

-- LoggingColors sets the colors used for color output
local LogColors = {
    "",             -- Info is default
    "%{blue}",      -- Debugging in blue
    "%{yellow}",    -- Warnings are yellow
    "%{cyan}",      -- Errors are cyan
    "%{red}",       -- Fatals are red
    "%{green}",     -- Pass is green
    "%{red}",       -- Fail is red
}

-- LoggingSymbols is used for text output with symbols on (grep friendly)
local LogSymbols = {
    "[I]",         -- Info
    "[D]",         -- Debug
    "[W]",         -- Warning
    "[E]",         -- Error
    "[X]",         -- Fatal
    "[P]",         -- Pass
    "[F]"          -- Fail      
}

-- Human readable names for json
local LogNames = {
    "info",
    "debug",
    "warning",
    "error",
    "fatal",
    "pass",
    "fail"
}

-- Logging format definitions see tprint documentation for more info
local LogFmt = {
    TEXT    = 0;
    JSON    = 1;
}

-- Test configuration object
local T = {

    -- Default options
    opts = {
        log_level   = LogLevel.INFO;
        color       = false;
        symbols     = true;
        format      = LogFmt.TEXT;
    },
   
    -- Defaults to using standard output
    output      = io.stdout,
    
    C           = nil,      -- The ansicolors library 
    run         = 0,        -- Number of tests run
    tcount      = 0,        -- Test count
    suite       = "",       -- Name of the current suite
    ctest       = "",       -- Name of the current test
    scount      = 0,        -- Suite count
    pass        = 0,        -- Count of pass
    warns       = 0,        -- Count of warns
    errors      = 0,        -- Count of errors
    fail        = 0,        -- Count of fail
    tests       = {},       -- The tests to be run
    j           = nil       -- The json encoder when loaded
}

-- Given file, find and load valid tests
function T:LoadFile(path)
    local imp, fnd = string.gsub(path, ".lua", "")
    if fnd ~= 1 then
        self:Info("Filename did not have a '.lua' extension")
        return self
    end
    
    self:Info("Loading file %s", path)
    
    local tf = require(imp)
    local st = {
        -- default suite name is the name of the file
        name = path:match("^.+/(.+)$");
        tests = {};
    }

    -- look for a suite, if it's there grab the name
    if tf.suite then
        if tf.suite.name then
            st.name = tf.suite.name
        end

        -- sibling suites and tests objects (misconfiguration)
        if tf.tests then
            io.stderr:write("Sibling Suite and Test Objects.. skipping\n")
            return self
        end

        -- suite contains no tests
        if not tf.suite.tests then
            self:Warning("Suite Declared In %s With No Tests...", path)
            return self
        end

        -- set up tf to extract tests
        tf = tf.suite
    end

    -- loop over the tests in this suite, if they have both a name and a 
    -- function then pull them into the harness for execution
    for i=1, #tf.tests do
        if tf.tests[i].name and tf.tests[i].test then
            st.tests[#st.tests + 1] = tf.tests[i]
        else
            self:Warning("Malformed test found in %s", path)
        end
    end

    self.tcount = self.tcount + #st.tests
    self.tests[#self.tests + 1] = st
    return self
end

-- Run all tests currently loaded
function T:Run()
    self:Info("Running %d tests", self.tcount)
    local cs = {}
    local pf = nil;
    
    -- each thing in self.tests is a suite
    for i=1, #self.tests do
        cs = self.tests[i]
        self.suite = cs.name
        self:Info("Starting Suite: %s", cs.name)

        -- now each of these is a test with a name
        for j=1, #cs.tests do
            self:Info("Running Test: %s", cs.tests[j].name)
            self.ctest = cs.tests[j].name
            pf = cs.tests[j].test(self)
            if pf then
                self.fail = self.fail + 1
                self:Fail(cs.tests[j].name, pf)
            else
                self:Pass(cs.tests[j].name)
                self.pass = self.pass + 1
            end

            self.run = self.run + 1
        end
    end

    return self
end

-- Log that a test has passed
function T:Pass()
    local msg = ""
    if self.opts.format == LogFmt.JSON then
        local jl = {
            -- JS cannot handle 63bit ints
            timestamp   = tostring(os.time(os.date("!*t")));
            pass        = true;
            test_suite  = self.suite;
            test_name   = self.ctest;
        }
        msg = self.j(jl) .. "\n"
        self.output:write(msg)
        return
    end

    if self.opts.log_level ~= LogLevel.SILENT then
        msg = self:encode(LogLevel.PASS, "%s -> %s", self.suite, self.ctest)
        self.output:write(msg)
    end
    return
end

-- Log that a test has passed
function T:Fail(umsg)
    local msg = umsg or false
    if self.opts.format == LogFmt.JSON then
        local jl = {
            -- JS cannot handle 63bit ints
            timestamp   = tostring(os.time(os.date("!*t")));
            pass        = false;
            test_suite  = self.suite;
            test_name   = self.ctest;
        }
        
        if msg then jl.message = msg end

        msg = self.j(jl) .. "\n"
        self.output:write(msg)
        return
    end

    if self.opts.log_level ~= LogLevel.SILENT then
        msg = self:encode(LogLevel.FAIL, "%s -> %s", self.suite, self.ctest)
        self.output:write(msg)
    end
    return
end

-- Print a summary of tests pass, fail, error etc
function T:Summary()
        print("Testing Complete!")
        print(string.format("Ran %d Tests from %d Suites", self.run, self.scount))
        print(string.format("Pass: %d", self.pass))
        print(string.format("Errors: %d", self.errors))
        print(string.format("Fails: %d", self.fail))
        return
end

-- If we want to send our output someplace other than io.stdout
function T:SetOutput(path)
    local tmp = assert(io.open(path, "a+"), "Failed to open " .. path .. "\n")
    if tmp then
        self.output = tmp
    end

    return self
end

-- Close the output if it's not stdout
function T:CloseOutput()
    if self.output == io.stdout then
        return
    end

    self.output:close()
end

-- Set colored output on or off
function T:SetColor(c)
    if c and LogFmt.TEXT then
        self.C = require("ansicolors")
        self.opts.color = true;
        return self
    end

    self.opts.color = false;
    return self
end

-- Tune the logging level
function T:SetLogLevel(level)
    self.opts.log_level = level
    return self
end

-- Pass true to turn log symbols on
function T:SetLogSymbols(s)
    if s and self.opts.format == LogFmt.TEXT then
        self.opts.symbols = true;
        return self
    end

    self.opts.symbols = false;
    return self
end

-- Set format of the output
function T:SetFormat(fmt)
    if fmt == LogFmt.JSON then
        self.j = require('json').encode
        self.opts.color = false
        self.opts.symbols = false
        self.opts.format = LogFmt.JSON
        return self
    end

    self.opts.format = fmt
    return self
end

-- If JSON is set as output, encode logging to json
function T:encode(lvl, fmt, ...)
    local msg = fmt
    local arg = {...}
    if #arg > 0 then
        msg = string.format(fmt, unpack(arg))
    end
    
    if self.opts.format == LogFmt.JSON then
        local jl = {
            -- JS cannot handle 64bit ints
            timestamp   = tostring(os.time(os.date("!*t")));
            level       = LogNames[lvl];
            test_suite  = self.suite;
            test_name   = self.ctest;
            message     = msg;
        }
        msg = self.j(jl)
        return msg .. "\n" 
    end
    
    -- adjust lvl for the 1 offset
    lvl = lvl + 1

    if self.opts.symbols then
        msg = string.format("%s %s", LogSymbols[lvl], msg)
    end

    if self.opts.color then
        msg = string.format("%s %s", LogColors[lvl], msg)
        msg = msg .. "%{reset}\n"
        return self.C(msg)
    end
    
    msg = msg .. "\n"
    return msg
end 

-- Log unimportant information
function T:Info(fmt, ...)
    if self.opts.log_level > LogLevel.INFO then
        return
    end
    
    local arg = {...}
    self.output:write(self:encode(LogLevel.INFO, fmt, unpack(arg)))
end

-- Log debugging information
function T:Debug(fmt, ...)
    if self.opts.log_level > LogLevel.DEBUG then
        return
    end
    
    local arg = {...}
    self.output:write(self:encode(LogLevel.DEBUG, fmt, unpack(arg)))
end

-- Log a warning
function T:Warn(fmt, ...)
    self.warns = self.warns + 1
    if self.opts.log_level > LogLevel.WARN then
        return
    end
    
    local arg = {...}
    self.output:write(self:encode(LogLevel.WARN, fmt, unpack(arg)))
end

-- Log an error and keep going
function T:Error(fmt, ...)
    self.errors = self.errors + 1
    if self.opts.log_level > LogLevel.ERROR then
        return
    end

    local arg = {...}
    self.output:write(self:encode(LogLevel.ERROR, fmt, unpack(arg)))
end

-- Log an error and shut down the test harness completely 
function T:Fatal(fmt, ...)
    if self.opts.log_level > LogLevel.FATAL then
        return
    end

    local arg = {...}
    self.output:write(self:encode(LogLevel.FATAL, fmt, unpack(arg)))
    os.exit(1)
end

return {
    T = T,
    LogLevel = LogLevel,
    LogColors = LogColors,
    LogNames = LogNames,
    LogFmt = LogFmt,
    LogSymbols = LogSymbols
}
    
