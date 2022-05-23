--!strict

type Sys = {
    Name: string;
    [any]: any;
}

type Lynx = {
    Create: (name: string) -> Sys;
    Get: (name: string) -> Sys;
    Run: () -> ();
}

local sysTables: {[string]: Sys} = {}
local systems: {[string]: Sys} = {}

local function GetReservedTable(name: string): Sys
    local sysTable: Sys = sysTables[name]
    if sysTable then return sysTable end

    sysTable = {
        Name = name;
    }

    sysTables[name] = sysTable

    return sysTable
end

local function Create(name: string): Sys
    assert(name ~= nil, "System must have a name")
    assert(typeof(name) == "string", "System name must be a string")
    assert(systems[name] == nil, ("System %s already exists"):format(name))

    local system: Sys = GetReservedTable(name) :: Sys
    
    systems[system.Name] = system

    return system
end

local function Get(name: string): Sys
    local sys = systems[name]
    if sys then return sys end

    return GetReservedTable(name) :: Sys
end

local function AddFolder(folder: Instance)
    for _, v in folder:GetChildren() do
        require(v)
    end
end

local function Run()
    for i in sysTables do
        assert(systems[i] ~= nil, ("System %s is never defined"):format(i))
    end

    for _, v in systems do
        if v.Init then
            v:Init()
        end
    end

    for _, v in systems do
        if v.Start then
            v:Start()
        end
    end
end

return {
    Create = Create;
    Get = Get;

    AddFolder = AddFolder;

    Run = Run;
}