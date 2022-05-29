local HttpService = game:GetService("HttpService")
local remote = script.Parent:WaitForChild("Remote")
local systemsFolder = script.Parent:WaitForChild("Systems")

local repTypes = {
    Request = 1;
    Command = 2;
}

while systemsFolder:GetAttribute("RepNum") ~= #systemsFolder:GetChildren() do
	task.wait()
end

local sysTables = {}
local systems = {}

local function BuildServerSystem(folder: Folder)
    local sys = {
        Name = folder.Name
    }

    for k, v in folder:GetAttributes() do
        local data = HttpService:JSONDecode(v)
        local args = data[2]

        if data[1] == repTypes.Request then
            sys[k] = function(_, ...)
                local vargs = {...}
                
                if #args ~= #vargs then
                    warn(("[CLIENT VALIDATOR] %s -> %s, argument count mismatch, expected %i, given %i"):format(sys.Name, k, #args, #vargs))
                    return
                end

                for i, v in vargs do
                    local argv = args[i]
                    if argv == nil then
                        warn(("[CLIENT VALIDATOR] %s -> %s, argument %i out of range"):format(sys.Name, k, i))
                        return
                    elseif typeof(v) ~= typeof(argv) then
                        warn(("[CLIENT VALIDATOR] %s -> %s, argument %i type mismatch, expected %s, got %s"):format(sys.Name, k, i, typeof(argv), typeof(v)))
                        return
                    end
                end

                remote:FireServer(folder.Name, k, ...)
            end
        end
    end

    return sys
end

local function GetReservedTable(name)
    local sysTable = sysTables[name]
    if sysTable then return sysTable end

    local repSys = systemsFolder:FindFirstChild(name)
    if repSys then return BuildServerSystem(repSys) end

    sysTable = {
        Name = name;
    }

    sysTables[name] = sysTable

    return sysTable
end

local function Create(data)
    assert(data.Name ~= nil, "System must have a name")
    assert(typeof(data.Name) == "string", "System name must be a string")
    assert(systems[data.Name] == nil and systemsFolder:FindFirstChild(data.Name) == nil, ("System %s already exists"):format(data.Name))

    local system = GetReservedTable(data.Name)
  
    for k, v in data do
        system[k] = v
    end

    systems[system.Name] = system

    return system
end

local function Get(name)
    local sys = systems[name]
    if sys then return sys end

    return GetReservedTable(name)
end

local function AddFolder(folder)
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