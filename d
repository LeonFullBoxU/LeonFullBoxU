-- =============================================
-- COMBINED FIREBALL + HIT – SINGLE BUTTON TOGGLE (Draggable Black GUI)
-- Fireball: ~1310–1320 ms | Hit: ~590–630 ms | ONE BUTTON for BOTH
-- =============================================
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Fireball Remote (fixed)
local fireballRemote = ReplicatedStorage:WaitForChild("SkillsInRS"):WaitForChild("RemoteEvent")
print("Fireball remote locked: " .. fireballRemote.Name)

-- Hit Remote (with fallback)
local hitRemote = ReplicatedStorage:FindFirstChild("jdskhfsIIIllliiIIIdchgdIiIIIlIlIli")
if not hitRemote then
    print("Exact hit remote not found → scanning...")
    for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") and #obj.Name > 20 and (obj.Name:match("I") or obj.Name:match("l") or obj.Name:match("d")) then
            hitRemote = obj
            print("Detected hit remote: " .. obj.Name)
            break
        end
    end
end
if not hitRemote then warn("No hit remote found!") end
print("Hit remote: " .. (hitRemote and hitRemote.Name or "NONE"))

-- Compact Mobile-Friendly GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CombinedAuto"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = false
ScreenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 196)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -98)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Header / drag area
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
header.BorderSizePixel = 0
header.Active = true
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 10)
headerFix.Position = UDim2.new(0, 0, 1, -10)
headerFix.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -72, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🔥 FIRE + HIT"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.Parent = header

-- Hide button
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 28, 0, 24)
hideBtn.Position = UDim2.new(1, -62, 0, 4)
hideBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
hideBtn.TextColor3 = Color3.new(1, 1, 1)
hideBtn.Text = "—"
hideBtn.TextSize = 18
hideBtn.Font = Enum.Font.GothamBold
hideBtn.AutoButtonColor = true
hideBtn.Parent = header

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 6)
hideCorner.Parent = hideBtn

-- Small close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "×"
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = true
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Fireball stats
local statsFireball = Instance.new("TextLabel")
statsFireball.Size = UDim2.new(1, -12, 0, 27)
statsFireball.Position = UDim2.new(0, 6, 0, 38)
statsFireball.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statsFireball.TextColor3 = Color3.fromRGB(255, 165, 0)
statsFireball.TextSize = 11
statsFireball.Font = Enum.Font.GothamSemibold
statsFireball.Text = "Fire: 0 | 1317 ms | 0.76/s"
statsFireball.Parent = mainFrame

local fireCorner = Instance.new("UICorner")
fireCorner.CornerRadius = UDim.new(0, 6)
fireCorner.Parent = statsFireball

-- Hit stats
local statsHit = Instance.new("TextLabel")
statsHit.Size = UDim2.new(1, -12, 0, 27)
statsHit.Position = UDim2.new(0, 6, 0, 69)
statsHit.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statsHit.TextColor3 = Color3.fromRGB(100, 255, 100)
statsHit.TextSize = 11
statsHit.Font = Enum.Font.GothamSemibold
statsHit.Text = "Hits: 0 | 616 ms | 0.00/s"
statsHit.Parent = mainFrame

local hitCorner = Instance.new("UICorner")
hitCorner.CornerRadius = UDim.new(0, 6)
hitCorner.Parent = statsHit

-- Main toggle button
local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(1, -12, 0, 44)
autoBtn.Position = UDim2.new(0, 6, 0, 102)
autoBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
autoBtn.TextColor3 = Color3.new(1, 1, 1)
autoBtn.TextSize = 15
autoBtn.Font = Enum.Font.GothamBlack
autoBtn.Text = "START BOTH"
autoBtn.AutoButtonColor = true
autoBtn.Parent = mainFrame

local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0, 8)
autoCorner.Parent = autoBtn

-- Destroy button kept compact
local destroyBtn = Instance.new("TextButton")
destroyBtn.Size = UDim2.new(1, -12, 0, 34)
destroyBtn.Position = UDim2.new(0, 6, 0, 154)
destroyBtn.BackgroundColor3 = Color3.fromRGB(150, 35, 35)
destroyBtn.TextColor3 = Color3.new(1, 1, 1)
destroyBtn.TextSize = 12
destroyBtn.Text = "DESTROY GUI"
destroyBtn.Font = Enum.Font.GothamBold
destroyBtn.AutoButtonColor = true
destroyBtn.Parent = mainFrame

local destroyCorner = Instance.new("UICorner")
destroyCorner.CornerRadius = UDim.new(0, 7)
destroyCorner.Parent = destroyBtn

-- Tiny floating restore button shown while GUI is hidden
local showBtn = Instance.new("TextButton")
showBtn.Name = "ShowButton"
showBtn.Size = UDim2.new(0, 46, 0, 46)
showBtn.Position = UDim2.new(1, -58, 0.5, -23)
showBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
showBtn.TextColor3 = Color3.new(1, 1, 1)
showBtn.Text = "🔥"
showBtn.TextSize = 22
showBtn.Font = Enum.Font.GothamBold
showBtn.Visible = false
showBtn.Active = true
showBtn.AutoButtonColor = true
showBtn.Parent = ScreenGui

local showCorner = Instance.new("UICorner")
showCorner.CornerRadius = UDim.new(1, 0)
showCorner.Parent = showBtn

-- Mouse + touch dragging
local function makeDraggable(target, handle)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(mainFrame, header)
makeDraggable(showBtn, showBtn)

hideBtn.Activated:Connect(function()
    mainFrame.Visible = false
    showBtn.Visible = true
end)

showBtn.Activated:Connect(function()
    showBtn.Visible = false
    mainFrame.Visible = true
end)

-- Shared findDummy
local function findDummy()
    local map = Workspace:FindFirstChild("MAP")
    if not map then return nil end
    local folder = map:FindFirstChild("5k_dummies")
    if not folder then return nil end

    local prio = folder:FindFirstChild("Dummy2")
    if prio and prio:FindFirstChild("Humanoid") and prio.Humanoid.Health > 0 and prio:FindFirstChild("HumanoidRootPart") then
        return prio
    end

    for _, obj in ipairs(folder:GetChildren()) do
        local hum = obj:FindFirstChild("Humanoid")
        local hrp = obj:FindFirstChild("HumanoidRootPart")
        if obj.Name:match("Dummy") and hum and hum.Health > 0 and hrp then
            return obj
        end
    end
    return nil
end

-- ==================== FIREBALL LOGIC ====================
local runningFireball = false
local connFireball
local currentDummyFire, currentHumanoidFire
local lastDropTimeFire, lastDropHPFire = 0, math.huge
local cooldownEstFire, hitCountFire = 1.317, 0
local SAFETY_MS_FIRE, MIN_GAP_FIRE, OUTLIER_RESET_FIRE = 0.035, 1.260, 1.360

local function updateStatsFire()
    local rate = cooldownEstFire > 0 and (1 / cooldownEstFire) or 0
    statsFireball.Text = string.format("Fire: %d | %d ms | %.2f/s", hitCountFire, math.round(cooldownEstFire * 1000), rate)
end

-- ==================== HIT LOGIC ====================
local runningHit = false
local connHit
local currentDummyHit, currentHumanoidHit
local lastDropTimeHit, lastDropHPHit = 0, math.huge
local cooldownEstHit, hitCountHit = 0.616, 0
local SAFETY_MS_HIT, MIN_GAP_HIT, OUTLIER_RESET_HIT = 0.012, 0.600, 0.650

local function updateStatsHit()
    local rate = cooldownEstHit > 0 and (1 / cooldownEstHit) or 0
    statsHit.Text = string.format("Hits: %d | %d ms | %.2f/s", hitCountHit, math.round(cooldownEstHit * 1000), rate)
end

-- SINGLE TOGGLE FUNCTION (starts/stops BOTH)
local function toggleBoth()
    local wasRunning = runningFireball or runningHit
    runningFireball = not runningFireball
    runningHit = not runningHit

    if runningFireball and runningHit then
        -- Start Fireball
        currentDummyFire = findDummy()
        if currentDummyFire then
            currentHumanoidFire = currentDummyFire.Humanoid
            lastDropHPFire = currentHumanoidFire.Health
            lastDropTimeFire = tick()
            hitCountFire = 0
            print("Fireball started on " .. currentDummyFire.Name)
        else
            warn("No dummy for fireball!")
            runningFireball = false
        end

        -- Start Hit
        currentDummyHit = findDummy()
        if currentDummyHit then
            currentHumanoidHit = currentDummyHit.Humanoid
            lastDropHPHit = currentHumanoidHit.Health
            lastDropTimeHit = tick()
            hitCountHit = 0
            print("Hit started on " .. currentDummyHit.Name)
        else
            warn("No dummy for hit!")
            runningHit = false
        end

        autoBtn.Text = "STOP BOTH"
        autoBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)

        -- Fireball Loop
        if connFireball then connFireball:Disconnect() end
        connFireball = RunService.Heartbeat:Connect(function()
            if not runningFireball then return end
            if not currentDummyFire or not currentDummyFire.Parent or currentHumanoidFire.Health <= 0 then
                currentDummyFire = findDummy()
                if not currentDummyFire then runningFireball = false return end
                currentHumanoidFire = currentDummyFire.Humanoid
                lastDropHPFire = currentHumanoidFire.Health
                lastDropTimeFire = tick()
                hitCountFire = 0
                cooldownEstFire = 1.317
                print("Fireball switched: " .. currentDummyFire.Name)
            end
            local now = tick()
            local elapsed = now - lastDropTimeFire
            if elapsed >= math.max(MIN_GAP_FIRE, cooldownEstFire - SAFETY_MS_FIRE) then
                pcall(function()
                    local hrp = currentDummyFire.HumanoidRootPart
                    if hrp then fireballRemote:FireServer(hrp.Position, "NewFireball") end
                end)
                local hp = currentHumanoidFire.Health
                if hp < lastDropHPFire then
                    local actual = now - lastDropTimeFire
                    hitCountFire += 1
                    cooldownEstFire = cooldownEstFire * 0.88 + actual * 0.12
                    if cooldownEstFire > OUTLIER_RESET_FIRE then
                        cooldownEstFire = 1.317
                        print("Fireball reset → 1317 ms")
                    end
                    print(string.format("FIREBALL #%d | %d ms | HP:%.0f | Est:%d | %s", hitCountFire, math.round(actual*1000), hp, math.round(cooldownEstFire*1000), currentDummyFire.Name))
                    lastDropHPFire = hp
                    lastDropTimeFire = now
                    updateStatsFire()
                end
            end
        end)

        -- Hit Loop
        if connHit then connHit:Disconnect() end
        connHit = RunService.Heartbeat:Connect(function()
            if not runningHit then return end
            if not currentDummyHit or not currentDummyHit.Parent or currentHumanoidHit.Health <= 0 then
                currentDummyHit = findDummy()
                if not currentDummyHit then runningHit = false return end
                currentHumanoidHit = currentDummyHit.Humanoid
                lastDropHPHit = currentHumanoidHit.Health
                lastDropTimeHit = tick()
                hitCountHit = 0
                cooldownEstHit = 0.616
                print("Hit switched: " .. currentDummyHit.Name)
            end
            local now = tick()
            local elapsed = now - lastDropTimeHit
            if elapsed >= math.max(MIN_GAP_HIT, cooldownEstHit - SAFETY_MS_HIT) then
                if hitRemote then hitRemote:FireServer(currentHumanoidHit, 1) end
                local hp = currentHumanoidHit.Health
                if hp < lastDropHPHit then
                    local actual = now - lastDropTimeHit
                    hitCountHit += 1
                    cooldownEstHit = cooldownEstHit * 0.88 + actual * 0.12
                    if cooldownEstHit > OUTLIER_RESET_HIT then
                        cooldownEstHit = 0.616
                        print("Hit reset → 616 ms")
                    end
                    print(string.format("HIT #%d | %d ms | HP:%.0f | Est:%d | %s", hitCountHit, math.round(actual*1000), hp, math.round(cooldownEstHit*1000), currentDummyHit.Name))
                    lastDropHPHit = hp
                    lastDropTimeHit = now
                    updateStatsHit()
                end
            end
        end)

    else  -- Stop both
        runningFireball = false
        runningHit = false
        autoBtn.Text = "START BOTH"
        autoBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
        if connFireball then connFireball:Disconnect() end
        if connHit then connHit:Disconnect() end
    end
end

autoBtn.Activated:Connect(toggleBoth)

local function destroyGui()
    runningFireball = false
    runningHit = false
    if connFireball then connFireball:Disconnect() end
    if connHit then connHit:Disconnect() end
    ScreenGui:Destroy()
    print("Combined GUI destroyed")
end

destroyBtn.Activated:Connect(destroyGui)
closeBtn.Activated:Connect(destroyGui)

print("Combined SINGLE-BUTTON auto loaded – Drag GUI, click START BOTH!")
