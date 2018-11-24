-------------------------------------------------------------------------------
-- bgtest.lua
--
-- author: Lawrence Hoffman
--
-- bgtest - a testing framework for lua apps
-------------------------------------------------------------------------------
local testing   = require("T")
local argparse  = require("argparse")
local S         = require("S")

local T = testing.T

-- Clean up the arg vec if we were called from luvit
local function clean_args(cliargs)
    if cliargs[0] ~= "bgtest" then
        local newv = {}
        for i=1, #cliargs do
            newv[i-1] = cliargs[i]
        end
        return newv 
    end
    return cliargs
end


-- Grab all lua files from a directory
local function get_files(dirpath)
    local p = io.popen('find "'..dirpath..'" -type f -name "*.lua"')
    local t = {}

    for file in p:lines() do
        t[#t+1] = file:sub(3, -5):gsub("/", ".")
    end

    return t
end

-- main entry point of the program
local function main()
    -- set the testing global
    _G.__TESTING = S
    
    args = clean_args(args)

    local parser = argparse("bgtest", "A Simpler Test Suite")
    
    parser:option("-f --file", "file to discover tests in", nil):count("*")
    parser:option("-d --directory", "directory to discover tests in", nil):count("*")
    parser:option("-o --output", "output to a file", nil):count("0-1")
    parser:flag("--color", "turn on colored output", false)
    parser:flag("-j --json", "output json", false)

    parser:mutex(
        parser:flag("--debug", "Output debug and above", false),
        parser:flag("--warn", "Output warnings and above", false),
        parser:flag("--errors", "Output errors and above", false),
        parser:flag("--fatal", "Output fatal and above", false),
        parser:flag("--results", "Report pass / fail only", false),
        parser:flag("--fail", "Report failures and nothing else", false),
        parser:flag("--silent", "completely silent", false)
    )


    local opts = parser:parse(args)

    -- Configures the harness --
    if opts.color then 
        T:SetColor(true) 
    end
    
    if opts.debug then
        T:SetLogLevel(testing.LogLevel.DEBUG)
    end

    if opts.warn then
        T:SetLogLevel(testing.LogLevel.WARN)
    end

    if opts.errors then
        T:SetLogLevel(testing.LogLevel.ERROR)
    end

    if opts.fatal then
        T:SetLogLevel(testing.LogLevel.FATAL)
    end

    if opts.results then
        T:SetLogLevel(testing.LogLevel.PASS)
    end

    if opts.fail then
        T:SetLogLevel(testing.LogLevel.FAIL)
    end

    if opts.silent then 
        T:SetLogLevel(testing.LogLevel.SILENT)
        T:SetColor(false)
    end
    
    if opts.output then
        T:SetOutput(opts.output)
        T:SetColor(false)
    end

    if opts.json then
        T:SetFormat(testing.LogFmt.JSON)
        T:SetColor(false)
    end
    
    if opts.file then
        for i=1, #opts.file do
            T:LoadFile(opts.file[i])
        end
    end

    if opts.directory then
        local cdl = {}
        for i=1, #opts.directory do
            cdl = get_files(opts.directory[i])
            for j=1, #cdl do
                T:LoadFile(cdl[j])
            end
        end
    end
            
    T:Run()

    -- Only print the summary if silent mode is off
    if not opts.silent and not opts.json then
        T:Summary()
    end

end

main()
