
local function autoDetectUnitId(unitName)
    for _, unit in pairs(game:GetService("ReplicatedStorage").Units:GetChildren()) do
        if unit:FindFirstChild("UnitName") and unit.UnitName.Value == unitName then
            return unit.UnitId.Value 
        end
    end
    return nil 
end


local function waitForSeconds(seconds)
    local endTime = tick() + seconds
    while tick() < endTime do
        task.wait(0.1)
    end
end


local function extractNumber(value)
    return tonumber(string.match(value:gsub("[^%d]", ""), "%d+")) or 0
end


local function savePositionsToFile(positions)
    local jsonData = json:JSONEncode(positions)
    writefile(getgenv().SettingFarm.PositionFile, jsonData)
end


local function loadPositionsFromFile()
    if isfile(getgenv().SettingFarm.PositionFile) then
        local jsonData = readfile(getgenv().SettingFarm.PositionFile)
        return json:JSONDecode(jsonData)
    else
        return {}
    end
end


local function getNextPosition(startPos, currentPos, stepSize, endPos)
    local nextZ = currentPos.Z - stepSize
    local nextX = currentPos.X

    if nextZ < endPos.Z then
        nextZ = startPos.Z
        nextX = currentPos.X - stepSize
    end

    if nextX < endPos.X then
        return nil
    end

    return Vector3.new(nextX, startPos.Y, nextZ)
end


local function isPositionOccupied(newPos, stepSize)
    for _, unit in pairs(workspace.Units:GetChildren()) do
        local unitPos = unit.PrimaryPart.Position
        if math.abs(unitPos.X - newPos.X) < stepSize and math.abs(unitPos.Z - newPos.Z) < stepSize then
            return true
        end
    end
    return false
end

local function FarmGem()
    local player = game.Players.LocalPlayer
    local unitFolder = player:WaitForChild("PlayerGui"):WaitForChild("Hotbar"):WaitForChild("Main"):WaitForChild("Units")
    
    local argsSkip = { "Skip" }
    game:GetService("ReplicatedStorage").Networking.SkipWaveEvent:FireServer(unpack(argsSkip))
    wait(2)
    
    local startPos = Vector3.new(140.065, 8.752, 123.342)
    local endPos = Vector3.new(129.989, 8.752, 117.640)
    local stepSize = 2
    local currentPos = startPos
    local pendingPositions = {}

    while true do
        local yenValueLabel = player:WaitForChild("PlayerGui"):WaitForChild("Hotbar"):WaitForChild("Main"):WaitForChild("Yen")
        local yenValue = extractNumber(yenValueLabel.Text)
        local anyPlaced = false
        local enoughMoney = false

        for i = 1, 6 do
            local unitSlot = unitFolder:FindFirstChild(tostring(i))
            if unitSlot and unitSlot:FindFirstChild("UnitTemplate") then
                local unitName = unitSlot.UnitTemplate.Holder.Main.UnitName.Text
                local unitId = autoDetectUnitId(unitName) 

                if unitId then
                    local placementText = unitSlot.UnitTemplate.Holder.Main.MaxPlacement.Text
                    local maxPlacement = extractNumber(string.match(placementText, "/(%d+)"))
                    local currentPlacement = extractNumber(string.match(placementText, "(%d+)/"))

                    if currentPlacement < maxPlacement then
                        local price = extractNumber(unitSlot.UnitTemplate.Holder.Main.Price.Text)

                        if #pendingPositions > 0 then
                            local savedPos = table.remove(pendingPositions, 1)

                            if yenValue >= price then
                                local argsRender = {
                                    "Render",
                                    { unitName, unitId, savedPos, 0 }
                                }
                                game:GetService("ReplicatedStorage").Networking.UnitEvent:FireServer(unpack(argsRender))
                                wait(2)
                                anyPlaced = true
                                yenValue = yenValue - price
                            else
                                table.insert(pendingPositions, savedPos)
                            end
                        end

                        if yenValue >= price then
                            while currentPos do
                                if not isPositionOccupied(currentPos, stepSize) then
                                    local argsRender = {
                                        "Render",
                                        { unitName, unitId, currentPos, 0 }
                                    }
                                    game:GetService("ReplicatedStorage").Networking.UnitEvent:FireServer(unpack(argsRender))
                                    wait(2)
                                    anyPlaced = true
                                    yenValue = yenValue - price
                                    currentPos = getNextPosition(startPos, currentPos, stepSize, endPos)
                                    enoughMoney = true
                                    break
                                else
                                    currentPos = getNextPosition(startPos, currentPos, stepSize, endPos)
                                end
                            end
                        else
                            if currentPos then
                                table.insert(pendingPositions, currentPos)
                                currentPos = getNextPosition(startPos, currentPos, stepSize, endPos)
                            end
                        end
                    end
                else
                    print("Unit ID not found for " .. unitName)
                end
            end
        end

        if not enoughMoney then
            print("Not enough yen to place unit, pausing...")
            wait(5)
        end

        if not anyPlaced and #pendingPositions == 0 and not currentPos then
            print("All units placed.")
            break
        end
    end

    while true do
        local anyUpgraded = false

        for _, unit in pairs(workspace.Units:GetChildren()) do
            local unitId = unit.Name
            local argsUpgrade = { "Upgrade", unitId }
            local upgradeResponse = game:GetService("ReplicatedStorage").Networking.UnitEvent:FireServer(unpack(argsUpgrade))
            wait(2)

            if upgradeResponse and upgradeResponse.Success then
                anyUpgraded = true
            end
        end
    end
end


local function sendDialogueEvent(args)
    game:GetService("ReplicatedStorage").Networking.State.DialogueEvent:FireServer(unpack(args))
end


local function enterCodes(codes)
    for _, code in pairs(getgenv().SettingFarm.Codes) do
        local codeArgs = { code }
        game:GetService("ReplicatedStorage").Networking.CodesEvent:FireServer(unpack(codeArgs))
        waitForSeconds(2)
    end
end

local function selectUnit(unitName)
    local selectArgs = { "Select", unitName }
    game:GetService("ReplicatedStorage").Networking.Units.UnitSelectionEvent:FireServer(unpack(selectArgs))
end

local function equipUnit(fileName)
    local equipArgs = { "Equip", fileName }
    game:GetService("ReplicatedStorage").Networking.Units.EquipEvent:FireServer(unpack(equipArgs))
    print("Unit equipment request sent: " .. fileName)
end

local function claimTutorial()
    local tutorial = { "ClaimTutorial", "SummonTutorial" }
    game:GetService("ReplicatedStorage").Networking.ClientListeners.TutorialEvent:FireServer(unpack(tutorial))
end


local function findUnit(unitName, unitFolder)
    for _, unitFile in pairs(unitFolder:GetChildren()) do
        local fileName = unitFile.Name
        if not (fileName:sub(1, 2) == "Ui" or fileName == "UIPadding") then
            local unitHolder = unitFile:FindFirstChild("Holder")
            if unitHolder then
                local unitMain = unitHolder:FindFirstChild("Main")
                if unitMain then
                    local unitNameObj = unitMain:FindFirstChild("UnitName")
                    if unitNameObj and unitNameObj.Text == unitName then
                        return fileName
                    end
                end
            end
        end
    end
    return nil
end


local function equipUnits(targetUnits, backupUnits)
    local player = game.Players.LocalPlayer
    local unitFolder = player:WaitForChild("PlayerGui"):WaitForChild("Windows"):WaitForChild("Units"):WaitForChild("Holder"):WaitForChild("Main"):WaitForChild("Units")
    local unitsToEquip = {}

    for _, targetUnit in pairs(targetUnits) do
        local unitFileName = findUnit(targetUnit, unitFolder)
        if unitFileName then
            table.insert(unitsToEquip, unitFileName)
        else
            for _, backupUnit in pairs(backupUnits) do
                local backupFileName = findUnit(backupUnit, unitFolder)
                if backupFileName then
                    table.insert(unitsToEquip, backupFileName)
                    table.remove(backupUnits, table.find(backupUnits, backupUnit))
                    break
                end
            end
        end
    end

    for _, unitFileName in pairs(unitsToEquip) do
        equipUnit(unitFileName)
        waitForSeconds(2)
    end

    return #unitsToEquip == #targetUnits
end


local function performLobbyActions()
    local enterArgs = { "Enter", workspace.MainLobby.Lobby.Lobby }
    game:GetService("ReplicatedStorage").Networking.LobbyEvent:FireServer(unpack(enterArgs))
    waitForSeconds(2)

    local confirmArgs = {
        "Confirm",
        { "Story", "Stage1", "Act1", "Normal", 4, 0, false }
    }
    game:GetService("ReplicatedStorage").Networking.LobbyEvent:FireServer(unpack(confirmArgs))
    waitForSeconds(2)

    local startArgs = { "Start", workspace.MainLobby.Lobby.Lobby }
    game:GetService("ReplicatedStorage").Networking.LobbyEvent:FireServer(unpack(startArgs))
end


local targetPlaceId = 16146832113
local function runFarmGem()
    if game.PlaceId ~= targetPlaceId then
        FarmGem()
        return
    end
end

local function main()
    if game.PlaceId ~= targetPlaceId then
        print("Script only runs in Anime Vanguard Game ID: " .. targetPlaceId)
        return
    end

    sendDialogueEvent({ "Interact", { "StarterUnitDialogue", 1, "Okay!" } })
    waitForSeconds(1)

    sendDialogueEvent({ "Interact", { "StarterUnitDialogue", 2, "Yeah!" } })
    waitForSeconds(1)

    sendDialogueEvent({ "Interact", { "StarterUnitDialogue", 3, "Yeah!" } })
    waitForSeconds(1)

    selectUnit("Luffo")
    waitForSeconds(1)

    enterCodes(getgenv().SettingFarm.Codes)

    game:GetService("ReplicatedStorage").Networking.Settings.SettingsEvent:FireServer("Toggle", "SkipSummonAnimation")
    game:GetService("ReplicatedStorage").Networking.Settings.SettingsEvent:FireServer("Toggle", "AutoSkipWaves")
    
    for i = 1, 6 do
        game:GetService("ReplicatedStorage").Networking.Units.SummonEvent:FireServer("SummonTen", "Special")
        waitForSeconds(1)
    end

    claimTutorial()
    if getgenv().SettingFarm.Equipment.Enable then
        local success = equipUnits(getgenv().SettingFarm.Equipment.Units, getgenv().SettingFarm.Equipment.BackupUnits)
        if success then
            performLobbyActions()
        else
            print("Cannot equip enough units from main and backup list.")
        end
    end
end

main()  
runFarmGem()
