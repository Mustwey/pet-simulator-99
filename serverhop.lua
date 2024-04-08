local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- Alternate request method preserved for backup.
local function alternateServersRequest()
    local response = HttpService:RequestAsync({
        Url = 'https://games.roblox.com/v1/games/' .. tostring(game.PlaceId) .. '/servers/Public?sortOrder=Asc&limit=100',
        Method = "GET",
        Headers = { ["Content-Type"] = "application/json" },
    })

    if response.Success then
        return response.Body -- Directly return the response body for consistency with your original approach.
    else
        return nil
    end
end

-- Main function to get a list of servers and select one randomly.
local function getServer()
    local servers
    local success, response = pcall(function()
        -- Attempt to fetch servers using the primary method.
        servers = HttpService:JSONDecode(HttpService:GetAsync('https://games.roblox.com/v1/games/' .. tostring(game.PlaceId) .. '/servers/Public?sortOrder=Asc&limit=100')).data
    end)

    -- If the primary method fails, revert to the alternate method.
    if not success or not servers then
        print("Error getting servers, using backup method")
        servers = HttpService:JSONDecode(alternateServersRequest()).data
    end

    -- Ensure there are servers to choose from.
    if #servers > 0 then
        local randomIndex = Random.new():NextInteger(5, math.min(100, #servers)) -- Ensures selection within available range.
        local server = servers[randomIndex]
        if server then
            return server
        else
            return getServer() -- Recursive call to handle edge cases.
        end
    else
        warn("No servers available.")
        return nil
    end
end

-- Attempt to teleport to a randomly selected server.
local function attemptTeleport()
    local server = getServer()
    if server then
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Players.LocalPlayer)
        end)
    else
        warn("Failed to find a suitable server.")
    end
end

-- Initial teleport attempt.
attemptTeleport()

while true do
    task.wait(5) -- Adjusted to a reasonable interval to avoid excessive teleportation attempts.
    attemptTeleport()

end
