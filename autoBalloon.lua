getgenv().autoBalloon = true

getgenv().autoBalloonConfig = {
    SERVER_MINIMUM_TIME = 35, -- minimum time to wait before server hopping
    START_DELAY = 2.5, -- delay before starting
    SERVER_HOP_AFTER_NOT_FIND = false, -- if the balloon isn't found, instead of checking through the rest of the balloons, it will just server hop
    SERVER_HOP_DELAY = 0, -- delay before server hopping
    BALLOON_DELAY = 0.5, -- delay before popping next balloon (if there are multiple balloons in the server)
    GET_BALLOON_DELAY = 0, -- delay before getting balloons again if none are detected
    GIFT_BOX_BREAK_FAILSAFE = 1, -- seconds to wait before skipping gift boxes if they don't function properly
}

repeat
    task.wait(0.1)
until game:IsLoaded() and game.PlaceId ~= nil and
    game:GetService("Players").LocalPlayer and
    game:GetService("Players").LocalPlayer.Character and
    game:GetService("Players").LocalPlayer.Character.HumanoidRootPart and
    (
        (game.PlaceId == 8737899170 and #game:GetService("Workspace").Map:GetChildren() == 100) or
        (game.PlaceId == 16498369169 and #game:GetService("Workspace").Map2:GetChildren() == 51) or
        (game.PlaceId ~= 8737899170 and game.PlaceId ~= 16498369169)
    ) and
    game:GetService("Workspace").__THINGS and game:GetService("Workspace").__DEBRIS

print("[CLIENT] Loaded Game")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local breakables = game:GetService("Workspace"):WaitForChild("__THINGS"):WaitForChild("Breakables")
local Client = ReplicatedStorage:WaitForChild("Library"):WaitForChild("Client")

pcall(function()
    LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false

    if getconnections then
        for _, v in pairs(getconnections(LocalPlayer.Idled)) do
            v:Disable()
        end
    else
        LocalPlayer.Idled:Connect(function()
            game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
    end
end)

local startTimestamp = os.time()
task.wait(getgenv().autoBalloonConfig.START_DELAY)
local balloonGifts = {}

require(Client.PlayerPet).CalculateSpeedMultiplier = function()
    return 200
end

for _, lootbag in pairs(game:GetService("Workspace").__THINGS:FindFirstChild("Lootbags"):GetChildren()) do
    if lootbag then
        game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Lootbags_Claim"):FireServer(unpack( { [1] = { [1] = lootbag.Name, }, } ))
        lootbag:Destroy()
        task.wait()
    end
end

game:GetService("Workspace").__THINGS:FindFirstChild("Lootbags").ChildAdded:Connect(function(lootbag)
    task.wait()
    if lootbag then
        game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Lootbags_Claim"):FireServer(unpack( { [1] = { [1] = lootbag.Name, }, } ))
        lootbag:Destroy()
    end
end)

game:GetService("Workspace").__THINGS:FindFirstChild("Orbs").ChildAdded:Connect(function(orb)
    task.wait()
    if orb then
        game:GetService("ReplicatedStorage"):WaitForChild("Network"):FindFirstChild("Orbs: Collect"):FireServer(unpack( { [1] = { [1] = tonumber(orb.Name), }, } ))
        orb:Destroy()
    end
end)

breakables.ChildAdded:Connect(function(child)
    pcall(function()
        if string.find(child:GetAttribute("BreakableID"), "Balloon Gift") and child:GetAttribute("OwnerUsername") == LocalPlayer.Name then
            table.insert(balloonGifts, child)
        end
    end)
end)

breakables.ChildRemoved:Connect(function(child)
    pcall(function()
        if string.find(child:GetAttribute("BreakableID"), "Balloon Gift") and child:GetAttribute("OwnerUsername") == LocalPlayer.Name then
            table.remove(balloonGifts, table.find(balloonGifts, child))
        end
    end)
end)

ReplicatedStorage.Network.Slingshot_Toggle:InvokeServer()
while getgenv().autoBalloon do
    local balloonIds = {}

    local getActiveBalloons = ReplicatedStorage.Network.BalloonGifts_GetActiveBalloons:InvokeServer()

    local allPopped = true
    for i, v in pairs(getActiveBalloons) do
        if not v.Popped then
            allPopped = false
            balloonIds[i] = v
        end
    end

    local notContinuing = true
    if allPopped then
        print("No balloons detected, waiting " .. tostring(getgenv().autoBalloonConfig.GET_BALLOON_DELAY) .. " seconds")
        task.wait(getgenv().autoBalloonConfig.GET_BALLOON_DELAY)
        notContinuing = false
    end

    if notContinuing then
        if not getgenv().autoBalloon then
            break
        end

        local originalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
        LocalPlayer.Character.HumanoidRootPart.Anchored = true
        for balloonId, balloonData in pairs(balloonIds) do
            local balloonPosition = balloonData.Position
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(balloonPosition.X, balloonPosition.Y + 30, balloonPosition.Z)
            task.wait()
            ReplicatedStorage.Network.Slingshot_FireProjectile:InvokeServer(Vector3.new(balloonPosition.X, balloonPosition.Y + 25, balloonPosition.Z), 0.5794160315249014, -0.8331117721691044, 200)
            task.wait()
            ReplicatedStorage.Network.BalloonGifts_BalloonHit:FireServer(balloonId)
            task.wait()

            -- BREAK BREAKABLES
            print("Breaking balloon boxes")

            local balloonLandPos = balloonData.LandPosition

            local loadBreaks
            local foundBreaks = false

            loadBreaks = breakables.ChildAdded:Connect(function(child)
                if string.find(child:GetAttribute("BreakableID"), "Balloon Gift") and child:GetAttribute("OwnerUsername") == LocalPlayer.Name then
                    foundBreaks = true
                end
            end)

            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(balloonLandPos.X, balloonLandPos.Y+5, balloonLandPos.Z)
            LocalPlayer.Character.HumanoidRootPart.Anchored = false

            print("Waiting for balloon drop")
            local counter = 0

            local exiting = false
            while not foundBreaks do
                counter = counter + 1
                if counter > (getgenv().autoBalloonConfig.GIFT_BOX_BREAK_FAILSAFE * 20) then
                    print("Balloon drop not found")
                    counter = 0
                    exiting = true
                    if getgenv().autoBalloonConfig.SERVER_HOP_AFTER_NOT_FIND then
                        local timeElapsed = os.time() - startTimestamp
                        if timeElapsed < getgenv().autoBalloonConfig.SERVER_MINIMUM_TIME then
                            task.wait(getgenv().autoBalloonConfig.SERVER_MINIMUM_TIME - timeElapsed)
                        end
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/Mustwey/pet-simulator-99/main/presonal/ServerHopV4.lua"))()
                    end
                    break
                end
                task.wait(0.05)
            end

            if not exiting then
                loadBreaks:Disconnect()
                task.wait()

                for _, v in pairs(balloonGifts) do
                    local brokeBox = false
                    task.spawn(function()
                        while breakables:FindFirstChild(v.Name) do
                            game:GetService("ReplicatedStorage").Network.Breakables_PlayerDealDamage:FireServer(v.Name)
                            task.wait()
                        end
                        brokeBox = true
                    end)

                    local counter = 0
                    while counter < (getgenv().autoBalloonConfig.GIFT_BOX_BREAK_FAILSAFE * 20) do
                        if brokeBox then
                            break
                        end
                        counter = counter + 1
                        task.wait(0.05)
                    end

                    print("Broke balloon box")
                end
                LocalPlayer.Character.HumanoidRootPart.Anchored = true
            end
            print("After exting")

            print("Popped balloon")
            task.wait(getgenv().autoBalloonConfig.BALLOON_DELAY)
        end

        if getgenv().autoBalloonConfig.SERVER_HOP then
            local timeElapsed = os.time() - startTimestamp
            if timeElapsed < getgenv().autoBalloonConfig.SERVER_MINIMUM_TIME then
                task.wait(getgenv().autoBalloonConfig.SERVER_MINIMUM_TIME - timeElapsed)
            end
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Mustwey/pet-simulator-99/main/presonal/ServerHopV4.lua"))()
        end

        task.wait()
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
        LocalPlayer.Character.HumanoidRootPart.CFrame = originalPosition
    end

    if (os.time() - startTimestamp) > getgenv().autoBalloonConfig.SERVER_MINIMUM_TIME then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Mustwey/pet-simulator-99/main/presonal/ServerHopV4.lua"))()
    end
end
