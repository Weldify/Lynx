if game:GetService("RunService"):IsServer() then
    return require(script.Server)
else
    return require(script.Client)
end