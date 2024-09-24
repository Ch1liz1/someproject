local HttpService = game:GetService("HttpService")
local savedPositions = {}

local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local SaveButton = Instance.new("TextButton")
local LoadButton = Instance.new("TextButton")
local TextBox = Instance.new("TextBox")

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "UnitPlacementUI"

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0.3, 0, 0.3, 0)
Frame.Position = UDim2.new(0.35, 0, 0.35, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 255, 0)

Title.Parent = Frame
Title.Text = "Vai lon tre em"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true

TextBox.Parent = Frame
TextBox.PlaceholderText = "Enter unit position or data"
TextBox.Size = UDim2.new(0.9, 0, 0.4, 0)
TextBox.Position = UDim2.new(0.05, 0, 0.3, 0)
TextBox.Text = ""
TextBox.TextScaled = true

SaveButton.Parent = Frame
SaveButton.Text = "Save Position"
SaveButton.Size = UDim2.new(0.4, 0, 0.2, 0)
SaveButton.Position = UDim2.new(0.05, 0, 0.75, 0)
SaveButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveButton.TextScaled = true

LoadButton.Parent = Frame
LoadButton.Text = "Load Position"
LoadButton.Size = UDim2.new(0.4, 0, 0.2, 0)
LoadButton.Position = UDim2.new(0.55, 0, 0.75, 0)
LoadButton.BackgroundColor3 = Color3.fromRGB(0, 0, 170)
LoadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadButton.TextScaled = true

local function saveUnitPosition(position)
    table.insert(savedPositions, position)
    local jsonData = HttpService:JSONEncode(savedPositions)
    local dataValue = workspace:FindFirstChild("SavedUnitPositions")
    if not dataValue then
        dataValue = Instance.new("StringValue", workspace)
        dataValue.Name = "SavedUnitPositions"
    end
    dataValue.Value = jsonData
end

local function loadUnitPositions()
    local dataValue = workspace:FindFirstChild("SavedUnitPositions")
    if dataValue then
        local jsonData = dataValue.Value
        local loadedPositions = HttpService:JSONDecode(jsonData)
        for _, pos in pairs(loadedPositions) do
            local unit = Instance.new("Part")
            unit.Position = Vector3.new(pos.x, pos.y, pos.z)
            unit.Parent = workspace
        end
    end
end

SaveButton.MouseButton1Click:Connect(function()
    local currentPos = humanoidRootPart.Position
    saveUnitPosition({x = currentPos.X, y = currentPos.Y, z = currentPos.Z})
    TextBox.Text = "Position saved!"
end)

LoadButton.MouseButton1Click:Connect(function()
    loadUnitPositions()
    TextBox.Text = "Units placed!"
end)
