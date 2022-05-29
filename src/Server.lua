local HttpService = game:GetService("HttpService")

local systemsFolder = Instance.new("Folder")
systemsFolder.Name = "Systems"
systemsFolder.Parent = script.Parent

systemsFolder:SetAttribute("RepNum", 0)

local remote = Instance.new("RemoteEvent")
remote.Name = "Remote"
remote.Parent = script.Parent

local repTypes = {
    Request = 1;
    Command = 2;
}

local sysTables = {}
local systems = {}

local requestMeta = {}

local function Punish(plr, reason)
    print("punish "..plr.." because "..reason)
end

remote.OnServerEvent:Connect(function(plr, sysName, reqName, ...)
    local isNameStr = typeof(sysName) == "string"
    local folder = if isNameStr then systemsFolder:FindFirstChild(sysName) else nil

    local isReqStr = typeof(reqName) == "string"
    local reqJSON = if folder and isReqStr then folder:GetAttribute(reqName) else nil
    local reqData = if reqJSON then HttpService:JSONDecode(reqJSON) else nil

    local reason
    if not isNameStr then
        reason = ("Provided %s instead of system name"):format(typeof(sysName))
    elseif not folder then
        reason = ("System %s doesn't exist / isn't replicated"):format(sysName)
    elseif not isReqStr then
        reason = ("Provided %s instead of request name"):format(typeof(reqName))
    elseif not reqJSON or reqData[1] ~= repTypes.Request then
        reason = ("Request %s doesn't exist in system %s"):format(reqName, sysName)
    else
        local args = reqData[2]
        local vargs = {...}

        if #args ~= #vargs then
            reason = ("%s -> %s, argument count mismatch, expected %i, given %i"):format(sysName, reqName, #args, #vargs)
        else
            for i, v in vargs do
                local argv = args[i]
                if argv == nil then
                    reason = ("%s -> %s, argument %i out of range"):format(sysName, reqName, i)
                    break
                elseif typeof(v) ~= typeof(argv) then
                    reason = ("%s -> %s, argument %i type mismatch, expected %s, got %s"):format(sysName, reqName, i, typeof(argv), typeof(v))
                    break
                end
            end
        end
    end

    if reason then
        Punish(plr, reason)
        return
    end
    
    local sys = systems[sysName]

    local req = sys[reqName]
    if req ~= nil then
        req(sys, plr, ...)
    end
end)

local function Request(...)
    return setmetatable({
        Args = {...}
    }, requestMeta)
end

local function GetReservedTable(name)
    local sysTable = sysTables[name]
    if sysTable then return sysTable end

    sysTable = {
        Name = name;
    }

    sysTables[name] = sysTable

    return sysTable
end

local function Create(data)
    assert(data.Name ~= nil, "System must have a name")
    assert(typeof(data.Name) == "string", "System name must be a string")
    assert(systems[data.Name] == nil, ("System %s already exists"):format(data.Name))

    local system = GetReservedTable(data.Name)
    
    for k, v in data do
        system[k] = v
    end

    local repAttributes = {}
    local replicated = false
    for k, v in system do
        if typeof(v) ~= "table" then continue end
        
        local meta = getmetatable(v)
        if meta == requestMeta then
            replicated = true
            
            repAttributes[k] = {repTypes.Request, v.Args}
        end
    end

    if replicated then
        systemsFolder:SetAttribute("RepNum", systemsFolder:GetAttribute("RepNum") + 1)

        local folder = Instance.new("Folder")
        folder.Name = data.Name

        for k, v in repAttributes do
            folder:SetAttribute(k, HttpService:JSONEncode(v))
        end

        folder.Parent = systemsFolder
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
    Number = 0;
    String = "";
    Boolean = true;

    Create = Create;
    Get = Get;

    Request = Request;

    AddFolder = AddFolder;

    Run = Run;
}