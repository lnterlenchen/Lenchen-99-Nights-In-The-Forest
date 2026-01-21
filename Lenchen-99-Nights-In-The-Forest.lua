if not (syn and syn.protect_gui) and not gethui then
    warn("⚠️ Your exploit may not fully support Rayfield UI")
end

if shared.Rayfield then
    pcall(function() shared.Rayfield:Destroy() end)
end

local RayfieldLoaded, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not RayfieldLoaded then
    RayfieldLoaded, Rayfield = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()
    end)
end

if not RayfieldLoaded or type(Rayfield) ~= "table" or not Rayfield.CreateWindow then
    error("❌ CRITICAL: Failed to load Rayfield library!\n" .. tostring(Rayfield))
end

shared.Rayfield = Rayfield

-- ==================== SERVICES & PLAYER ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ==================== WINDOW CREATION ====================
local Window = Rayfield:CreateWindow({
    Name = "Lenchen | 99 Nights In The Forest",
    LoadingTitle = "Script made by Lenchen",
    LoadingSubtitle = "discord.gg/EnxSw9stje",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
    DestroyOnClose = true,
})

-- ==================== TABS ====================
local mainTab = Window:CreateTab("Main")
local autofarmTab = Window:CreateTab("Auto")
local plrTab = Window:CreateTab("Player")
local visTab = Window:CreateTab("Visuals")
local miscTab = Window:CreateTab("Misc")

-- ==================== UTILITY FUNCTIONS ====================
local SafeZoneBaseplates = {}
local BaseplateSize = Vector3.new(2048, 1, 2048)
local CenterPos = Vector3.new(0, 100, 0)

for dx = -1, 1 do
    for dz = -1, 1 do
        local pos = CenterPos + Vector3.new(dx * BaseplateSize.X, 0, dz * BaseplateSize.Z)
        local baseplate = Instance.new("Part")
        baseplate.Name = "SafeZoneBaseplate"
        baseplate.Size = BaseplateSize
        baseplate.Position = pos
        baseplate.Anchored = true
        baseplate.CanCollide = true
        baseplate.Transparency = 1
        baseplate.Color = Color3.fromRGB(255, 255, 255)
        baseplate.Parent = workspace
        table.insert(SafeZoneBaseplates, baseplate)
    end
end

local function MoveItemToPosition(item, position)
    if not item or not item:IsDescendantOf(workspace) then return end
    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("Handle")
    if not part then return end
    
    if not item.PrimaryPart then
        pcall(function() item.PrimaryPart = part end)
    end
    
    pcall(function()
        ReplicatedStorage.RemoteEvents.RequestStartDraggingItem:FireServer(item)
        task.wait(0.05)
        item:SetPrimaryPartCFrame(CFrame.new(position))
        task.wait(0.05)
        ReplicatedStorage.RemoteEvents.StopDraggingItem:FireServer(item)
    end)
end

-- ==================== MAIN TAB ====================
-- Safe Zone Toggle
local SafeZoneToggle = mainTab:CreateToggle({
    Name = "Show Safe Zone",
    CurrentValue = false,
    Flag = "SafeZoneToggle",
    Callback = function(Value)
        for _, baseplate in ipairs(SafeZoneBaseplates) do
            baseplate.Transparency = Value and 0.8 or 1
            baseplate.CanCollide = Value
        end
    end,
})

-- Kill Aura
local KillAuraEnabled = false
local KillAuraRadius = 200

local ToolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

local function GetAnyTool()
    for toolName, damageID in pairs(ToolsDamageIDs) do
        local tool = LocalPlayer.Inventory:FindFirstChild(toolName)
        if tool then return tool, damageID end
    end
    return nil, nil
end

local KillAuraToggle = mainTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(Value)
        KillAuraEnabled = Value
        if Value then
            task.spawn(function()
                while KillAuraEnabled do
                    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                    if HumanoidRootPart then
                        local Tool, DamageID = GetAnyTool()
                        if Tool and DamageID then
                            ReplicatedStorage.RemoteEvents.EquipItemHandle:FireServer("FireAllClients", Tool)
                            for _, Mob in ipairs(Workspace.Characters:GetChildren()) do
                                if Mob:IsA("Model") then
                                    local Part = Mob:FindFirstChildWhichIsA("BasePart")
                                    if Part and (Part.Position - HumanoidRootPart.Position).Magnitude <= KillAuraRadius then
                                        pcall(function()
                                            ReplicatedStorage.RemoteEvents.ToolDamageObject:InvokeServer(Mob, Tool, DamageID, CFrame.new(Part.Position))
                                        end)
                                    end
                                end
                            end
                            task.wait(0.1)
                        else
                            task.wait(1)
                        end
                    else
                        task.wait(0.5)
                    end
                end
            end)
        else
            local Tool = GetAnyTool()
            if Tool then
                ReplicatedStorage.RemoteEvents.UnequipItemHandle:FireServer("FireAllClients", Tool)
            end
        end
    end,
})

local KillAuraRadiusSlider = mainTab:CreateSlider({
    Name = "Kill Aura Radius",
    Range = {20, 500},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 200,
    Flag = "KillAuraRadius",
    Callback = function(Value)
        KillAuraRadius = math.clamp(Value, 20, 500)
    end,
})

-- Stronghold Timer
local StrongholdTimeLabel = mainTab:CreateLabel("Stronghold Timer: Loading...")

coroutine.wrap(function()
    while true do
        local Label = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Landmarks") and workspace.Map.Landmarks:FindFirstChild("Stronghold") and workspace.Map.Landmarks.Stronghold:FindFirstChild("Functional") and workspace.Map.Landmarks.Stronghold.Functional:FindFirstChild("Sign") and workspace.Map.Landmarks.Stronghold.Functional.Sign:FindFirstChild("SurfaceGui") and workspace.Map.Landmarks.Stronghold.Functional.Sign.SurfaceGui:FindFirstChild("Frame") and workspace.Map.Landmarks.Stronghold.Functional.Sign.SurfaceGui.Frame:FindFirstChild("Body")
        StrongholdTimeLabel:Set("Stronghold Timer: " .. (Label and Label.ContentText or "N/A"))
        task.wait(0.5)
    end
end)()

-- Stronghold Teleport Buttons
local TeleportStrongholdBtn = mainTab:CreateButton({
    Name = "Teleport to Stronghold",
    Callback = function()
        local TargetPart = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Landmarks") and workspace.Map.Landmarks:FindFirstChild("Stronghold") and workspace.Map.Landmarks.Stronghold:FindFirstChild("Functional") and workspace.Map.Landmarks.Stronghold.Functional:FindFirstChild("EntryDoors") and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors:FindFirstChild("DoorRight") and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors.DoorRight:FindFirstChild("Model")
        if TargetPart then
            local Destination = TargetPart:GetChildren()[5]
            if Destination and Destination:IsA("BasePart") then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = Destination.CFrame + Vector3.new(0, 5, 0)
                end
            end
        end
    end,
})

local TeleportDiamondChestBtn = mainTab:CreateButton({
    Name = "Teleport to Diamond Chest",
    Callback = function()
        local Items = workspace:FindFirstChild("Items")
        if not Items then return end
        local Chest = Items:FindFirstChild("Stronghold Diamond Chest")
        if not Chest then return end
        local ChestLid = Chest:FindFirstChild("ChestLid")
        if not ChestLid then return end
        local DiamondChest = ChestLid:FindFirstChild("Meshes/diamondchest_Cube.002")
        if not DiamondChest then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = DiamondChest.CFrame + Vector3.new(0, 5, 0)
        end
    end,
})

-- ==================== PLAYER TAB ====================
-- JUMP POWER FIX: Use JumpHeight for modern games, fallback to JumpPower
local JumpPowerSlider = plrTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 700},
    Increment = 10,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                -- Try modern JumpHeight first
                pcall(function()
                    humanoid.JumpHeight = Value / 10
                end)
                -- Legacy JumpPower fallback
                pcall(function()
                    humanoid.JumpPower = Value
                end)
                
                Rayfield:Notify({
                    Title = "Jump Power Set",
                    Content = "Jump power: " .. Value,
                    Duration = 2
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Humanoid not found!",
                    Duration = 3
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Character not ready!",
                Duration = 3
            })
        end
    end,
})

-- WalkSpeed Slider
local WalkSpeedSlider = plrTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 700},
    Increment = 10,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        _G.HackedWalkSpeed = Value
        local function ApplySpeed(humanoid)
            if humanoid then
                humanoid.WalkSpeed = _G.HackedWalkSpeed
                humanoid.Changed:Connect(function(prop)
                    if prop == "WalkSpeed" and humanoid.WalkSpeed ~= _G.HackedWalkSpeed then
                        humanoid.WalkSpeed = _G.HackedWalkSpeed
                    end
                end)
            end
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            ApplySpeed(LocalPlayer.Character.Humanoid)
        end
        
        LocalPlayer.CharacterAdded:Connect(function(char)
            char:WaitForChild("Humanoid")
            ApplySpeed(char:FindFirstChild("Humanoid"))
        end)
    end,
})

-- WalkSpeed Toggle
local WalkSpeedToggle = plrTab:CreateToggle({
    Name = "WalkSpeed Toggle (50)",
    CurrentValue = false,
    Flag = "WalkSpeedToggle50",
    Callback = function(Value)
        _G.HackedWalkSpeed = Value and 50 or 16
        local function ApplySpeed(humanoid)
            if humanoid then
                humanoid.WalkSpeed = _G.HackedWalkSpeed
                humanoid.Changed:Connect(function(prop)
                    if prop == "WalkSpeed" and humanoid.WalkSpeed ~= _G.HackedWalkSpeed then
                        humanoid.WalkSpeed = _G.HackedWalkSpeed
                    end
                end)
            end
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            ApplySpeed(LocalPlayer.Character.Humanoid)
        end
        
        LocalPlayer.CharacterAdded:Connect(function(char)
            char:WaitForChild("Humanoid")
            ApplySpeed(char:FindFirstChild("Humanoid"))
        end)
    end,
})

-- ==================== AUTO FARM TAB ====================
-- Automation Variables
local AutoFuelEnabledItems = {}
local AutoCookEnabledItems = {}
local AutoGrindEnabledItems = {}
local AutoEatEnabled = false
local AutoEatHPEnabled = false
local AutoBreakEnabled = false
local AutoBiofuelEnabledItems = {}
local AlwaysFeedEnabledItems = {}

-- Auto Feed Campfire (Always)
local CampfireFuelItems = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"}
autofarmTab:CreateDropdown({
    Name = "Auto Feed Campfire (Ignores HP)",
    Options = CampfireFuelItems,
    MultipleOptions = true,
    CurrentOption = {},
    Callback = function(SelectedItems)
        table.clear(AlwaysFeedEnabledItems)
        for _, item in ipairs(SelectedItems) do AlwaysFeedEnabledItems[item] = true end
    end,
})

-- Auto Feed Campfire (HP Based)
autofarmTab:CreateDropdown({
    Name = "Auto Feed Campfire (HP Based)",
    Options = CampfireFuelItems,
    MultipleOptions = true,
    CurrentOption = {},
    Callback = function(SelectedItems)
        table.clear(AutoFuelEnabledItems)
        for _, item in ipairs(SelectedItems) do AutoFuelEnabledItems[item] = true end
    end,
})

-- Auto Cook Food
local AutoCookItems = {"Morsel", "Steak"}
autofarmTab:CreateDropdown({
    Name = "Auto Cook Food",
    Options = AutoCookItems,
    MultipleOptions = true,
    CurrentOption = {},
    Callback = function(SelectedItems)
        table.clear(AutoCookEnabledItems)
        for _, item in ipairs(SelectedItems) do AutoCookEnabledItems[item] = true end
    end,
})

-- Auto Machine Grind
local AutoGrindItems = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Cultist Experiment", "Cultist Component", "Gem of the Forest Fragment", "Broken Microwave"}
autofarmTab:CreateDropdown({
    Name = "Auto Machine Grind",
    Options = AutoGrindItems,
    MultipleOptions = true,
    CurrentOption = {},
    Callback = function(SelectedItems)
        table.clear(AutoGrindEnabledItems)
        for _, item in ipairs(SelectedItems) do AutoGrindEnabledItems[item] = true end
    end,
})

-- Auto Eat (3 sec interval)
local AutoEatToggle = autofarmTab:CreateToggle({
    Name = "Auto Eat (3 sec interval)",
    CurrentValue = false,
    Flag = "AutoEat3Sec",
    Callback = function(Value)
        AutoEatEnabled = Value
    end,
})

-- Auto Eat (HP Based)
local AutoEatHPToggle = autofarmTab:CreateToggle({
    Name = "Auto Eat (HP Bar Based)",
    CurrentValue = false,
    Flag = "AutoEatHP",
    Callback = function(Value)
        AutoEatHPEnabled = Value
    end,
})

-- Auto Biofuel Processor
local BiofuelItems = {"Carrot", "Cooked Morsel", "Morsel", "Steak", "Cooked Steak", "Log"}
autofarmTab:CreateDropdown({
    Name = "Auto Biofuel Processor",
    Options = BiofuelItems,
    MultipleOptions = true,
    CurrentOption = {},
    Callback = function(SelectedItems)
        table.clear(AutoBiofuelEnabledItems)
        for _, item in ipairs(SelectedItems) do AutoBiofuelEnabledItems[item] = true end
    end,
})

-- Auto Bring All Small Trees
local TreeToggle = autofarmTab:CreateToggle({
    Name = "Auto Bring All Small Trees",
    CurrentValue = false,
    Flag = "AutoTrees",
    Callback = function(Value)
        AutoBreakEnabled = Value
        
        local OriginalTreeCFrames = {}
        local TreesBrought = false
        
        local function GetAllSmallTrees()
            local Trees = {}
            local function Scan(folder)
                for _, obj in ipairs(folder:GetChildren()) do
                    if obj:IsA("Model") and obj.Name == "Small Tree" then
                        table.insert(Trees, obj)
                    end
                end
            end
            
            local Map = Workspace:FindFirstChild("Map")
            if Map then
                if Map:FindFirstChild("Foliage") then Scan(Map.Foliage) end
                if Map:FindFirstChild("Landmarks") then Scan(Map.Landmarks) end
            end
            return Trees
        end
        
        local function FindTrunk(tree)
            for _, part in ipairs(tree:GetDescendants()) do
                if part:IsA("BasePart") and part.Name == "Trunk" then return part end
            end
            return nil
        end
        
        if Value and not TreesBrought then
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local RootPart = Character:WaitForChild("HumanoidRootPart")
            local Target = CFrame.new(RootPart.Position + RootPart.CFrame.LookVector * 10)
            
            for _, Tree in ipairs(GetAllSmallTrees()) do
                local Trunk = FindTrunk(Tree)
                if Trunk then
                    if not OriginalTreeCFrames[Tree] then OriginalTreeCFrames[Tree] = Trunk.CFrame end
                    Tree.PrimaryPart = Trunk
                    Trunk.Anchored = false
                    Trunk.CanCollide = false
                    Tree:SetPrimaryPartCFrame(Target + Vector3.new(math.random(-5,5), 0, math.random(-5,5)))
                    Trunk.Anchored = true
                end
            end
            TreesBrought = true
        elseif not Value and TreesBrought then
            for Tree, CFrame in pairs(OriginalTreeCFrames) do
                local Trunk = FindTrunk(Tree)
                if Trunk then
                    Tree.PrimaryPart = Trunk
                    Tree:SetPrimaryPartCFrame(CFrame)
                    Trunk.Anchored = true
                    Trunk.CanCollide = true
                end
            end
            OriginalTreeCFrames = {}
            TreesBrought = false
        end
    end,
})

-- ==================== AUTO FARM COROUTINES ====================
local AutoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}
local CampfireDropPos = Vector3.new(0, 19, 0)
local MachineDropPos = Vector3.new(21, 16, -5)

coroutine.wrap(function()
    while true do
        for ItemName, Enabled in pairs(AlwaysFeedEnabledItems) do
            if Enabled then
                for _, Item in ipairs(Workspace.Items:GetChildren()) do
                    if Item.Name == ItemName then
                        MoveItemToPosition(Item, CampfireDropPos)
                    end
                end
            end
        end
        task.wait(2)
    end
end)()

coroutine.wrap(function()
    local Campfire = Workspace:WaitForChild("Map"):WaitForChild("Campground"):WaitForChild("MainFire")
    local FillFrame = Campfire.Center.BillboardGui.Frame.Background.Fill
    while true do
        local HealthPercent = FillFrame.Size.X.Scale
        if HealthPercent < 0.7 then
            repeat
                for ItemName, Enabled in pairs(AutoFuelEnabledItems) do
                    if Enabled then
                        for _, Item in ipairs(Workspace.Items:GetChildren()) do
                            if Item.Name == ItemName then
                                MoveItemToPosition(Item, CampfireDropPos)
                            end
                        end
                    end
                end
                task.wait(0.5)
                HealthPercent = FillFrame.Size.X.Scale
            until HealthPercent >= 1
        end
        task.wait(2)
    end
end)()

coroutine.wrap(function()
    while true do
        for ItemName, Enabled in pairs(AutoCookEnabledItems) do
            if Enabled then
                for _, Item in ipairs(Workspace.Items:GetChildren()) do
                    if Item.Name == ItemName then
                        MoveItemToPosition(Item, CampfireDropPos)
                    end
                end
            end
        end
        task.wait(2.5)
    end
end)()

coroutine.wrap(function()
    while true do
        for ItemName, Enabled in pairs(AutoGrindEnabledItems) do
            if Enabled then
                for _, Item in ipairs(Workspace.Items:GetChildren()) do
                    if Item.Name == ItemName then
                        MoveItemToPosition(Item, MachineDropPos)
                    end
                end
            end
        end
        task.wait(2.5)
    end
end)()

coroutine.wrap(function()
    while true do
        if AutoEatEnabled then
            local Available = {}
            for _, Item in ipairs(Workspace.Items:GetChildren()) do
                if table.find(AutoEatFoods, Item.Name) then
                    table.insert(Available, Item)
                end
            end
            if #Available > 0 then
                local Food = Available[math.random(1, #Available)]
                pcall(function() ReplicatedStorage.RemoteEvents.RequestConsumeItem:InvokeServer(Food) end)
            end
        end
        task.wait(3)
    end
end)()

local HungerBar = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Interface"):WaitForChild("StatBars"):WaitForChild("HungerBar"):WaitForChild("Bar")
coroutine.wrap(function()
    while true do
        if AutoEatHPEnabled then
            if HungerBar.Size.X.Scale <= 0.5 then
                repeat
                    local Available = {}
                    for _, Item in ipairs(Workspace.Items:GetChildren()) do
                        if table.find(AutoEatFoods, Item.Name) then
                            table.insert(Available, Item)
                        end
                    end
                    if #Available > 0 then
                        local Food = Available[math.random(1, #Available)]
                        pcall(function() ReplicatedStorage.RemoteEvents.RequestConsumeItem:InvokeServer(Food) end)
                    else
                        break
                    end
                    task.wait(1)
                until HungerBar.Size.X.Scale >= 0.99 or not AutoEatHPEnabled
            end
        end
        task.wait(3)
    end
end)()

coroutine.wrap(function()
    local BiofuelProcessorPos
    while true do
        if not BiofuelProcessorPos then
            local Processor = Workspace:FindFirstChild("Structures") and Workspace.Structures:FindFirstChild("Biofuel Processor")
            local Part = Processor and Processor:FindFirstChild("Part")
            if Part then
                BiofuelProcessorPos = Part.Position + Vector3.new(0, 5, 0)
            end
        end
        
        if BiofuelProcessorPos then
            for ItemName, Enabled in pairs(AutoBiofuelEnabledItems) do
                if Enabled then
                    for _, Item in ipairs(Workspace.Items:GetChildren()) do
                        if Item.Name == ItemName then
                            MoveItemToPosition(Item, BiofuelProcessorPos)
                        end
                    end
                end
            end
        end
        task.wait(2)
    end
end)()

-- ==================== VISUALS TAB ====================
local EspTransparency = 0.4
local TeamCheck = true
local CustomFont = Font.new("rbxassetid://16658246179", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local BillboardESPs = {}
local ChamsESPs = {}
local ESPConnections = {}
local ESPEnabled = false
local ChamsEnabled = false

local function GetRoot(char) return char and char:FindFirstChild("HumanoidRootPart") end

local function CreateBillboardESP(plr)
    if BillboardESPs[plr] or plr == LocalPlayer then return end
    if not plr.Character or not plr.Character:FindFirstChild("Head") then return end
    
    local gui = Instance.new("BillboardGui")
    gui.Name = "Billboard_ESP"
    gui.Adornee = plr.Character.Head
    gui.Parent = plr.Character.Head
    gui.Size = UDim2.new(0, 100, 0, 40)
    gui.AlwaysOnTop = true
    gui.StudsOffset = Vector3.new(0, 2, 0)
    
    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.FontFace = CustomFont
    
    local conn = RunService.RenderStepped:Connect(function()
        if not plr.Character or not plr.Character:FindFirstChild("Humanoid") then
            gui:Destroy()
            conn:Disconnect()
            BillboardESPs[plr] = nil
            ESPConnections[plr] = nil
            return
        end
        local hp = math.floor(plr.Character.Humanoid.Health / plr.Character.Humanoid.MaxHealth * 100)
        label.Text = plr.Name .. " | " .. hp .. "%"
    end)
    
    BillboardESPs[plr] = gui
    ESPConnections[plr] = conn
end

local function CreateChamsESP(plr)
    if ChamsESPs[plr] or plr == LocalPlayer then return end
    local root = GetRoot(plr.Character)
    if not root then return end
    
    local folder = Instance.new("Folder")
    folder.Name = "Chams_ESP"
    folder.Parent = CoreGui
    ChamsESPs[plr] = folder
    
    for _, part in pairs(plr.Character:GetChildren()) do
        if part:IsA("BasePart") then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "Cham_" .. plr.Name
            box.Adornee = part
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Size = part.Size
            box.Transparency = EspTransparency
            box.Color = BrickColor.new(TeamCheck and (plr.TeamColor == LocalPlayer.TeamColor and "Bright green" or "Bright red") or tostring(plr.TeamColor))
            box.Parent = folder
        end
    end
end

local function CleanupBillboardESP()
    for _, gui in pairs(BillboardESPs) do if gui then gui:Destroy() end end
    for _, conn in pairs(ESPConnections) do if conn then conn:Disconnect() end end
    BillboardESPs = {}
    ESPConnections = {}
end

local function CleanupChamsESP()
    for _, folder in pairs(ChamsESPs) do if folder then folder:Destroy() end end
    ChamsESPs = {}
end

local function HandlePlayerESP(plr)
    if ESPEnabled then CreateBillboardESP(plr) end
    if ChamsEnabled then CreateChamsESP(plr) end
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if ESPEnabled then CreateBillboardESP(plr) end
        if ChamsEnabled then CreateChamsESP(plr) end
    end)
end

local ESPToggle = visTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(Value)
        ESPEnabled = Value
        if Value then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then HandlePlayerESP(plr) end
            end
        else
            CleanupBillboardESP()
        end
    end,
})

local ChamsToggle = visTab:CreateToggle({
    Name = "Chams",
    CurrentValue = false,
    Flag = "PlayerChams",
    Callback = function(Value)
        ChamsEnabled = Value
        if Value then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then HandlePlayerESP(plr) end
            end
        else
            CleanupChamsESP()
        end
    end,
})

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 1
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.ZIndex = 2

RunService.RenderStepped:Connect(function()
    if FOVCircle.Visible then
        FOVCircle.Radius = 100
        FOVCircle.Position = UserInputService:GetMouseLocation()
    end
end)

local FOVToggle = visTab:CreateToggle({
    Name = "FOV Circle",
    CurrentValue = false,
    Flag = "FOVCircle",
    Callback = function(Value)
        FOVCircle.Visible = Value
    end,
})

-- ==================== MISC TAB ====================
local BtnInfiniteYield = miscTab:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end,
})

local BtnEmoteGui = miscTab:CreateButton({
    Name = "Emote GUI",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/dimension-sources/random-scripts-i-found/refs/heads/main/r6%20animations"))()
    end,
})

local BtnAntiAfk = miscTab:CreateButton({
    Name = "Anti AFK",
    Callback = function()
        pcall(function()
            if game.CoreGui:FindFirstChild("AntiAFK") then
                game.CoreGui.AntiAFK:Destroy()
            end
        end)
        
        local VirtualUser = game:GetService("VirtualUser")
        
        local gui = Instance.new("ScreenGui")
        gui.Name = "AntiAFK"
        gui.Parent = game.CoreGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 370, 0, 52)
        frame.Position = UDim2.new(0.7, 0, 0.1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        frame.Parent = gui
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = "Anti AFK: ACTIVE"
        label.TextColor3 = Color3.fromRGB(0, 255, 255)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSansSemibold
        label.TextSize = 22
        label.Parent = frame
        
        local conn
        conn = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            label.Text = "Anti AFK: Prevented kick!"
            wait(2)
            label.Text = "Anti AFK: ACTIVE"
        end)
        
        gui.AncestryChanged:Connect(function()
            if not gui:IsDescendantOf(game) then
                conn:Disconnect()
            end
        end)
        
        Rayfield:Notify({
            Title = "Anti AFK",
            Content = "Anti-AFK script activated!",
            Duration = 3
        })
    end,
})

local BtnTurtleSpy = miscTab:CreateButton({
    Name = "Turtle Spy",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Spy/main/source.lua", true))()
    end,
})

-- ==================== FINAL INITIALIZATION ====================
-- ESP for existing players
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then HandlePlayerESP(plr) end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then HandlePlayerESP(plr) end
end)

Rayfield:Notify({
    Title = "✅ Script Fully Loaded",
    Content = "Lenchen | 99 Nights in the Forest v1.0",
    Duration = 5,
})

print("✅ loaded successfully!")
