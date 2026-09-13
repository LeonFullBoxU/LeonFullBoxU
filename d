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

-- Main Draggable Black Frame
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CombinedAuto"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 420)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)  -- Black theme
mainFrame.BorderSizePixel = 0
mainFrame.Parent = ScreenGui

-- Draggable
local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
title.Text = "🔥 FIREBALL + HIT AUTO"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Fireball Stats
local statsFireball = Instance.new("TextLabel")
statsFireball.Size = UDim2.new(1, -20, 0, 35)
statsFireball.Position = UDim2.new(0, 10, 0, 45)
statsFireball.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statsFireball.TextColor3 = Color3.fromRGB(255, 165, 0)  -- Orange for fireball
statsFireball.TextScaled = true
statsFireball.Font = Enum.Font.GothamSemibold
statsFireball.Text = "Fireballs: 0 | Est: 1317 ms | Rate: 0.76 hps"
statsFireball.Parent = mainFrame

-- Hit Stats
local statsHit = Instance.new("TextLabel")
statsHit.Size = UDim2.new(1, -20, 0, 35)
statsHit.Position = UDim2.new(0, 10, 0, 90)
statsHit.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statsHit.TextColor3 = Color3.fromRGB(100, 255, 100)  -- Green for hit
statsHit.TextScaled = true
statsHit.Font = Enum.Font.GothamSemibold
statsHit.Text = "Hits: 0 | Est: 616 ms | Rate: 0.00 hps"
statsHit.Parent = mainFrame

-- SINGLE TOGGLE BUTTON (controls BOTH)
local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(1, -20, 0, 70)
autoBtn.Position = UDim2.new(0, 10, 0, 140)
autoBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
autoBtn.TextColor3 = Color3.new(1,1,1)
autoBtn.TextScaled = true
autoBtn.Font = Enum.Font.GothamBlack
autoBtn.Text = "START BOTH AUTOS"
autoBtn.Parent = mainFrame

-- Destroy Button
local destroyBtn = Instance.new("TextButton")
destroyBtn.Size = UDim2.new(1, -20, 0, 50)
destroyBtn.Position = UDim2.new(0, 10, 0, 230)
destroyBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
destroyBtn.TextColor3 = Color3.new(1,1,1)
destroyBtn.TextScaled = true
destroyBtn.Text = "DESTROY GUI"
destroyBtn.Font = Enum.Font.GothamBold
destroyBtn.Parent = mainFrame

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
    statsFireball.Text = string.format("Fireballs: %d | Est: %d ms | Rate: %.2f hps", hitCountFire, math.round(cooldownEstFire * 1000), rate)
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
    statsHit.Text = string.format("Hits: %d | Est: %d ms | Rate: %.2f hps", hitCountHit, math.round(cooldownEstHit * 1000), rate)
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

        autoBtn.Text = "STOP BOTH AUTOS"
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
        autoBtn.Text = "START BOTH AUTOS"
        autoBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
        if connFireball then connFireball:Disconnect() end
        if connHit then connHit:Disconnect() end
    end
end

autoBtn.MouseButton1Click:Connect(toggleBoth)

destroyBtn.MouseButton1Click:Connect(function()
    runningFireball = false
    runningHit = false
    if connFireball then connFireball:Disconnect() end
    if connHit then connHit:Disconnect() end
    ScreenGui:Destroy()
    print("Combined GUI destroyed")
end)

print("Combined SINGLE-BUTTON auto loaded – Drag GUI, click START BOTH!")
