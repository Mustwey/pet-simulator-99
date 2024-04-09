local function alternateServersRequest()
    local response = request({Url = 'https://games.roblox.com/v1/games/' .. tostring(game.PlaceId) .. '/servers/Public?sortOrder=Desc&limit=100', Method = "GET", Headers = { ["Content-Type"] = "application/json" },})

    if response.Success then
        return response.Body
    else
        return nil
    end
end

local function getServer(retryLimit)
    local servers
    local retryCount = 0

    -- Using pcall for safe HTTP request
    local success, result = pcall(function()
        servers = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. tostring(game.PlaceId) .. '/servers/Public?sortOrder=Desc&limit=100')).data
    end)

    if not success or not servers then
        print("Error getting servers, using backup method")
        servers = game.HttpService:JSONDecode(alternateServersRequest()).data
    end

    -- Ensure servers is not nil and has items
    if servers and #servers > 0 then
        while retryCount < retryLimit do
            local randomIndex = Random.new(tick()):NextInteger(1, #servers) -- Use tick() as seed for more randomness
            local server = servers[randomIndex]
            if server then
                return server
            else
                retryCount = retryCount + 1
            end
        end
    end

    if retryCount >= retryLimit then
        warn("Retry limit reached, no server found.")
        return nil -- Avoid infinite recursion
    end
end

while true do
    local server = getServer(5) -- Attempt to get a server 5 times
    if server and server.id then
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, game.Players.LocalPlayer)
        end)
    end
    task.wait(5)
end
