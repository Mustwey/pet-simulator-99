repeat 
    task.wait(0.1) 
until game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild("PlayerGui") and not game.Players.LocalPlayer.PlayerGui:FindFirstChild("__INTRO") and game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Character
--UI Lib
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/' --das ist das ui
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = PlayersService.LocalPlayer

--Webhook Stuff
local YourWebhook = "https://discord.com/api/webhooks/1232716551606632529/nNGM2QIu1wZlHgmEL-dlJeI-HTKRlGhmrofILo-rmUtJbOPCiBCbUYG6mAaknaMgohZN"
local webhookBuilder = loadstring(game:HttpGet("https://raw.githubusercontent.com/lilyscripts/webhook-builder/main/webhookBuilder.lua"))()

wait(0.5)
queue_on_teleport(game:HttpGet("https://raw.githubusercontent.com/Mustwey/pet-simulator-99/main/presonal/emulator.lua"))

local function UseTerminal()
    for i, v in getgenv().Config.ItemsToBuy do
        local args = {
            [1] = v.Class,
            [2] = "{\"id\":\"" .. v.ItemID .."\"}",
            [4] = false
        }
    
        local TerminalRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("TradingTerminal_Search"):InvokeServer(unpack(args))
        
        if TerminalRemote then
            local success, result = pcall(function()
                return game:GetService("TeleportService"):TeleportToPlaceInstance(TerminalRemote["place_id"], TerminalRemote["job_id"], game.Players.LocalPlayer)
            end)

            if success then
                break
            else
                print("Teleport failed, trying again: " .. tostring(result))
            end
        else
            print("No TerminalRemote found, trying again.")
        end
    end

    task.wait(1)
    UseTerminal() 
end



getgenv().Config = {
    ItemsToBuy = {
        {ItemID = "Gift Bag", PriceToBuyAt = 3300, Class = "Misc"},
        {ItemID = "Large Gift Bag", PriceToBuyAt = 11500, Class = "Misc"},
    }
}


for _, player in PlayersService:GetPlayers() do
    local Booths = getsenv(localPlayer.PlayerScripts.Scripts.Game["Trading Plaza"]["Booths Frontend"]).getByOwnerId
    for _, player in PlayersService:GetPlayers() do
        local playerListings = Booths(player.UserId)
        if playerListings then
            for listingID, listing in pairs(playerListings.Listings) do
                local itemData = listing.Item._data
                if not itemData._am then
                    print("Skipping listing: "..itemData.id .." as amount is nil. (Often because they traded the item)")
                else
                    for _, configItem in pairs(getgenv().Config.ItemsToBuy) do
                        if itemData.id == configItem.ItemID and listing.DiamondCost <= configItem.PriceToBuyAt then
                            local diamondsAvailable = localPlayer.leaderstats["💎 Diamonds"].Value
                            local amountToBuy = math.min(itemData._am, math.floor(diamondsAvailable / listing.DiamondCost))

                            if amountToBuy >= 1 then
                                local args = {
                                    player.UserId,
                                    {[tostring(listingID)] = amountToBuy}
                                }
                                ReplicatedStorage:WaitForChild("Network"):WaitForChild("Booths_RequestPurchase"):InvokeServer(unpack(args))
                                
                                local webhook = webhookBuilder(YourWebhook)
                                webhook:setUsername("PS99 Booth Sniper")

                                local embed = webhook:createEmbed()
                                embed:setTitle("Sniped something")
                                embed:setDescription("Item: " .. itemData.id .. "\nCost: " .. listing.DiamondCost .. "\nAmount: " .. itemData._am)
                                embed:setColor(0xFFFFFF)
                                webhook:send()

                                break
                            else
                                print("Could not afford one amount of the item: " .. configItem.ItemID)
                                break
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.001)
    end
    wait(0.5)
    UseTerminal()
end
