local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- Function to shuffle the servers array to simulate random selection
local function shuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

-- Alternate request method preserved for backup.
local function alternateServersRequest()
local response = request({Url = 'https://games.roblox.com/v1/games/' .. tostring(game.PlaceId) .. '/servers/Public?sortOrder=Asc&limit=250', Method = "GET", Headers = { ["Content-Type"] = "application/json" },})

    if response.Success then
        return response.Body -- Directly return the response body.
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

    -- Ensure there are servers to choose from and shuffle to simulate random selection.
    if #servers > 0 then
        shuffleTable(servers) -- Shuffle the list of servers.
        table.sort(servers, function(a, b) return a.playing < b.playing end) -- Sort the first 10 for the least populated.
        local server = servers[1] -- Select the least populated server.
        return server
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

-- Continuous attempt loop, with a wait to prevent rapid requests.
while true do
    task.wait(5) -- Adjusted to a reasonable interval to avoid excessive teleportation attempts.
    attemptTeleport()
end
