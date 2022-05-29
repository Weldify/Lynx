if game:GetService("RunService"):IsServer() then
    return require(script.Server)
else
    if script:FindFirstChild("Server") then
        script.Server:Destroy()
    end
    return require(script.Client)
end