local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local savedUnitsData = {}
local isRecording = false
local recordingStartTime = 0

-- UI Components
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local RecordButton = Instance.new("TextButton")
local StopButton = Instance.new("TextButton")
local TextBox = Instance.new("TextBox")
local CloseButton = Instance.new("TextButton")
local MinimizeButton = Instance.new("TextButton")
local DropdownButton = Instance.new("TextButton")
local Dropdown = Instance.new("Frame")

-- Variables for dragging
local dragging, dragInput, dragStart, startPos

-- Dropdown options data
local dropdownOptions = {
    {name = "Macro 1", data = {{["money"] = 1000, ["type"] = "Soldier", ["cframe"] = {X = 10, Y = 0, Z = 10}, ["unit"] = "Player1"}}},
    {name = "Macro 2", data = {{["money"] = 2000, ["type"] = "Archer", ["cframe"] = {X = 20, Y = 0, Z = 20}, ["unit"] = "Player2"}}},
    {name = "Macro 3", data = {{["money"] = 3000, ["type"] = "Mage", ["cframe"] = {X = 30, Y = 0, Z = 30}, ["unit"] = "Player3"}}}
}

-- Utility function to append text to the console
local function appendConsole(message)
    TextBox.Text = TextBox.Text .. message .. "\n"
end

-- Function to set up common button properties
local function setupButton(button, parent, position, size, text, color, onClick)
    button.Parent = parent
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.TextScaled = true
    button.MouseButton1Click:Connect(onClick)
end

-- Dragging functionality for the frame
local function setupDragging()
    local function update(input)
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Save recorded macro data
local function saveUnitData()
    local jsonData = HttpService:JSONEncode(savedUnitsData)
    local dataValue = workspace:FindFirstChild("SavedUnitData")
    
    if not dataValue then
        dataValue = Instance.new("StringValue", workspace)
        dataValue.Name = "SavedUnitData"
    end
    
    dataValue.Value = jsonData
end

-- Start and stop recording functions
local function startRecording()
    isRecording = true
    recordingStartTime = tick()
    TextBox.Text = "Recording macro...\n"
    savedUnitsData = {}
end

local function stopRecording()
    isRecording = false
    appendConsole("Recording stopped! Macro saved.")
    saveUnitData()
end

-- Dropdown setup for macro selection
local function createDropdownOptions()
    for i, option in pairs(dropdownOptions) do
        local dropdownOption = Instance.new("TextButton")
        setupButton(dropdownOption, Dropdown, UDim2.new(0, 0, (i-1) * 0.33, 0), UDim2.new(1, 0, 0.33, 0), option.name, Color3.fromRGB(50, 50, 50), function()
            TextBox.Text = option.name .. " selected\n"
            savedUnitsData = option.data
            Dropdown.Visible = false
        end)
    end
end

-- UI Setup
local function setupUI()
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Frame properties
    Frame.Parent = ScreenGui
    Frame.Size = UDim2.new(0.3, 0, 0.3, 0)
    Frame.Position = UDim2.new(0.35, 0, 0.35, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 2
    Frame.BorderColor3 = Color3.fromRGB(255, 255, 0)
    Frame.Active = true

    -- Title setup
    Title.Parent = Frame
    Title.Text = "Vai lon tre em"
    Title.Size = UDim2.new(1, 0, 0.2, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true

    -- TextBox setup (console)
    TextBox.Parent = Frame
    TextBox.Size = UDim2.new(0.9, 0, 0.4, 0)
    TextBox.Position = UDim2.new(0.05, 0, 0.3, 0)
    TextBox.Text = "Macro Console"
    TextBox.TextScaled = true
    TextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.TextEditable = false
    TextBox.TextYAlignment = Enum.TextYAlignment.Top

    -- Button Setup
    setupButton(RecordButton, Frame, UDim2.new(0.05, 0, 0.75, 0), UDim2.new(0.4, 0, 0.2, 0), "Record Macro", Color3.fromRGB(0, 170, 0), startRecording)
    setupButton(StopButton, Frame, UDim2.new(0.55, 0, 0.75, 0), UDim2.new(0.4, 0, 0.2, 0), "Stop Recording", Color3.fromRGB(170, 0, 0), stopRecording)
    setupButton(CloseButton, Frame, UDim2.new(1, -30, 0, 5), UDim2.new(0, 25, 0, 25), "X", Color3.fromRGB(170, 0, 0), function() ScreenGui:Destroy() end)
    setupButton(MinimizeButton, Frame, UDim2.new(1, -60, 0, 5), UDim2.new(0, 25, 0, 25), "-", Color3.fromRGB(255, 255, 0), function()
        Frame.Visible = not Frame.Visible
    end)

    -- Dropdown Setup
    Dropdown.Parent = Frame
    Dropdown.Size = UDim2.new(0.9, 0, 0.2, 0)
    Dropdown.Position = UDim2.new(0.05, 0, 0.55, 0)
    Dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Dropdown.Visible = false

    setupButton(DropdownButton, Frame, UDim2.new(0.05, 0, 0.55, 0), UDim2.new(0.9, 0, 0.2, 0), "Select Macro", Color3.fromRGB(0, 0, 170), function()
        Dropdown.Visible = not Dropdown.Visible
    end)

    createDropdownOptions()
end

-- Record positions and update the console
RunService.Stepped:Connect(function()
    if isRecording then
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoidRootPart then
            local currentPosition = humanoidRootPart.CFrame
            local unitData = {
                ["money"] = 1000, 
                ["type"] = "Soldier", 
                ["cframe"] = {X = currentPosition.X, Y = currentPosition.Y, Z = currentPosition.Z}, 
                ["unit"] = player.Name
            }

            table.insert(savedUnitsData, unitData)
            appendConsole("Recorded position at X: " .. currentPosition.X .. ", Y: " .. currentPosition.Y .. ", Z: " .. currentPosition.Z)
        end
    end
end)

-- Initialize UI and functionality
setupUI()
setupDragging()
