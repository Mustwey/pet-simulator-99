local function alternateServersRequest()
    local response = request({
        Url = 'https://games.roblox.com/v1/games/' .. tostring(game.PlaceId) .. '/servers/Public?sortOrder=Desc&limit=100',
        Method = "GET",
        Headers = { ["Content-Type"] = "application/json" },
    })

    if response.Success then
        return response.Body
    else
        return nil
    end
end

local function getServer()
    local servers

    local success, _ = pcall(function()
        servers = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. tostring(game.PlaceId) .. '/servers/Public?sortOrder=Desc&limit=100')).data
    end)

    if not success then
        print("Error getting servers, using backup method")
        servers = game.HttpService:JSONDecode(alternateServersRequest()).data
    end

    if servers and #servers > 0 then
        local server = servers[Random.new():NextInteger(80, #servers)]
        return server
    else
        warn("Failed to retrieve servers or no servers available.")
        return nil
    end
end

local function tryTeleport()
    local server = getServer()
    if server then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, game.Players.LocalPlayer)
    else
        print("Retrying to get a server.")
        tryTeleport() -- Recursive call to retry getting a server and teleporting
    end
end

local function onTeleportInitFailed(player, teleportResult, errorMessage)
    print("Teleport failed: ", errorMessage)
    tryTeleport() -- Attempt to teleport again using a different server
end

-- Connecting the TeleportInitFailed event
game:GetService("TeleportService").TeleportInitFailed:Connect(onTeleportInitFailed)

-- Initial teleport attempt
tryTeleport()
