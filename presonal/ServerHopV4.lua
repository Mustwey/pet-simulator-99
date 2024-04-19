-- Importing Services and Initializing Variables
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local BlockUtils = {}
local IsFriendWith = LocalPlayer.IsFriendsWith

-- Custom API for account management
local Account = {}
local WebserverSettings = {
    Port = '7963',
    Password = ''
}

function WebserverSettings:SetPort(Port) self.Port = Port end
function WebserverSettings:SetPassword(Password) self.Password = Password end

local function HTTPRequest(Method, URL)
    local Response = syn.request({
        Method = Method,
        Url = URL
    })
    return Response.StatusCode == 200 and Response.Body or false
end

function Account.new(Username)
    local self = setmetatable({}, Account)
    self.Username = Username
    return self
end

function Account:BlockUser(UserId)
    local URL = 'http://localhost:' .. WebserverSettings.Port .. '/BlockUser?Account=' .. self.Username .. '&UserId=' .. UserId .. (WebserverSettings.Password and '&Password=' .. WebserverSettings.Password or '')
    return HTTPRequest('GET', URL)
end

function Account:UnblockEveryone()
    local URL = 'http://localhost:' .. WebserverSettings.Port .. '/UnblockEveryone?Account=' .. self.Username .. (WebserverSettings.Password and '&Password=' .. WebserverSettings.Password or '')
    return HTTPRequest('GET', URL)
end

local apiAccount = Account.new(LocalPlayer.Name)

-- Utility Functions
local function isFriendWith(userId)
    local success, data = pcall(IsFriendWith, LocalPlayer, userId)
    return success and data or true
end

function BlockUtils:BlockUser(userId)
    return apiAccount:BlockUser(userId)
end

function BlockUtils:UnblockUser()
    return apiAccount:UnblockEveryone()
end

function BlockUtils:BlockRandomUser()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isFriendWith(player.UserId) then
            self:BlockUser(player.UserId)
            break
        end
    end
end

-- Queue a script to run upon teleport
queue_on_teleport(game:HttpGet("https://raw.githubusercontent.com/Mustwey/pet-simulator-99/main/autoBalloon.lua"))
task.wait(1)

-- Check if the player arrived from a teleport
local hasArrivedFromTeleport = TeleportService:GetLocalPlayerTeleportData() ~= nil
print("Arrived from teleport:", hasArrivedFromTeleport)

-- Decision based on teleport arrival
if hasArrivedFromTeleport then
    BlockUtils:UnblockUser()
    wait(5)
else
    BlockUtils:BlockRandomUser()
    wait(5)
end

-- Constantly attempt to teleport to a random place
while true do
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
    task.wait()
end
