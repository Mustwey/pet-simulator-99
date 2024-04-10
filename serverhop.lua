local function alternateServersRequest()
    local response = request({Url = 'https://games.roblox.com/v1/games/' .. tostring(game.PlaceId) .. '/servers/Public?sortOrder=Desc&limit=100', Method = "GET", Headers = { ["Content-Type"] = "application/json" },})

    if response.Success then
        return response.Body
    else
        warn("Failed to fetch servers: " .. response.StatusCode .. " " .. response.StatusMessage)
        return nil
    end
end

local function getServer(retryLimit)
    local servers
    local retryCount = 0
    local success, result = pcall(function()
        servers = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. tostring(game.PlaceId) .. '/servers/Public?sortOrder=Desc&limit=100')).data
    end)

    if not success or not servers then
        print("Error getting servers, using backup method")
        local backupResult = alternateServersRequest()
        servers = backupResult and game.HttpService:JSONDecode(alternateServersRequest()).data or nil
    end

    -- Ensure servers is not nil and has items
    if servers and #servers > 0 then
        while retryCount < retryLimit do
            local randomIndex = math.random(1, #servers)
            local server = servers[randomIndex]
            if server and server.playing < server.maxPlayers then
                return server
            else
                retryCount = retryCount + 1
            end
        end
    end

    if retryCount >= retryLimit then
        warn("Retry limit reached, no suitable server found.")
        return nil
    end
end

-- Continuous attempt to join a suitable server
while true do
    local server = getServer(10) -- Attempt to get a suitable server 10 times
    if server and server.id then
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Players.LocalPlayer)
        end)
    else
        warn("Unable to find a suitable server. Waiting before retrying...")
    end
    task.wait(5) -- Use task.wait() if available, for better performance and reliability
end
