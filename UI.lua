local HttpService = game:GetService("HttpService")
local savedPositions = {}
local isRecording = false
local recordingStartTime = 0

local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local RecordButton = Instance.new("TextButton")
local StopButton = Instance.new("TextButton")
local TextBox = Instance.new("TextBox")

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "MacroUI"

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
TextBox.PlaceholderText = ""
TextBox.Size = UDim2.new(0.9, 0, 0.4, 0)
TextBox.Position = UDim2.new(0.05, 0, 0.3, 0)
TextBox.Text = "Macro Console"
TextBox.TextScaled = true
TextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.TextEditable = false -- Make the TextBox uneditable like a console

RecordButton.Parent = Frame
RecordButton.Text = "Record Macro"
RecordButton.Size = UDim2.new(0.4, 0, 0.2, 0)
RecordButton.Position = UDim2.new(0.05, 0, 0.75, 0)
RecordButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
RecordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordButton.TextScaled = true

StopButton.Parent = Frame
StopButton.Text = "Stop Recording"
StopButton.Size = UDim2.new(0.4, 0, 0.2, 0)
StopButton.Position = UDim2.new(0.55, 0, 0.75, 0)
StopButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StopButton.TextScaled = true

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

local function startRecording()
    isRecording = true
    recordingStartTime = tick()
    TextBox.Text = "Recording macro..."
    savedPositions = {}
end

local function stopRecording()
    isRecording = false
    TextBox.Text = "Recording stopped! Macro saved."
    saveUnitPosition({time = recordingStartTime, positions = savedPositions})
end

RecordButton.MouseButton1Click:Connect(function()
    if not isRecording then
        startRecording()
    end
end)

StopButton.MouseButton1Click:Connect(function()
    if isRecording then
        stopRecording()
    end
end)

game:GetService("RunService").Stepped:Connect(function()
    if isRecording then
        local currentPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
        table.insert(savedPositions, {x = currentPos.X, y = currentPos.Y, z = currentPos.Z, time = tick() - recordingStartTime})
    end
end)
