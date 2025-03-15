-- Enhanced Dex Explorer for Roblox Executor
-- Created by [Your Name] with assistance from Grok
-- Date: March 15, 2025

local Services = setmetatable({}, {
    __index = function(self, ind)
        return game:GetService(ind)
    end
})

local Players = Services.Players
local CoreGui = Services.CoreGui
local UserInputService = Services.UserInputService

-- Utility Functions
local function CreateInstance(class, props)
    local inst = Instance.new(class)
    for i, v in pairs(props or {}) do
        inst[i] = v
    end
    return inst
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Error in " .. debug.getinfo(func).name .. ": " .. result)
        return nil
    end
    return result
end

-- Explorer Class
local Explorer = {}
Explorer.__index = Explorer

function Explorer.new(parent)
    local self = setmetatable({}, Explorer)
    self.Nodes = {[game] = {Object = game, Children = {}, Depth = 0}}
    self.Tree = {}
    self.Selection = {List = {}, Selected = {}}
    self.Expanded = {}
    self.SearchText = ""
    
    -- GUI Setup
    self.Frame = CreateInstance("Frame", {
        Size = UDim2.new(0.5, -5, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    self.ScrollFrame = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 8,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = self.Frame
    })
    
    self.SearchBox = CreateInstance("TextBox", {
        Size = UDim2.new(1, -10, 0, 30),
        Position = UDim2.new(0, 5, 0, 5),
        PlaceholderText = "Search Workspace...",
        Text = "",
        Font = Enum.Font.SourceSans,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Parent = parent
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = self.SearchBox})
    
    -- Event Connections
    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self.SearchText = self.SearchBox.Text:lower()
        self:UpdateTree()
    end)
    
    self:Initialize()
    return self
end

function Explorer:Initialize()
    for _, child in pairs(game:GetChildren()) do
        self:AddObject(child, game)
    end
    self:UpdateTree()
end

function Explorer:GetOrder(className)
    -- Simplified order system; expand as needed
    local orders = {
        Workspace = 1,
        Players = 2,
        Lighting = 3,
        ReplicatedStorage = 4,
        StarterGui = 5
    }
    return orders[className] or 999
end

function Explorer:AddObject(object, parent)
    local node = {
        Object = object,
        Parent = self.Nodes[parent],
        Children = {},
        Depth = (self.Nodes[parent].Depth or 0) + 1,
        Order = self:GetOrder(object.ClassName)
    }
    
    self.Nodes[object] = node
    table.insert(self.Nodes[parent].Children, node)
    
    node.Connections = {
        Ancestry = object.AncestryChanged:Connect(function(_, newParent)
            self:MoveObject(object, newParent)
        end),
        Added = object.ChildAdded:Connect(function(child)
            self:AddObject(child, object)
        end),
        Removed = object.ChildRemoved:Connect(function(child)
            self:RemoveObject(child)
        end)
    }
    
    for _, child in pairs(object:GetChildren()) do
        self:AddObject(child, object)
    end
    
    if self.SearchText ~= "" then
        self:UpdateTree()
    end
end

function Explorer:RemoveObject(object)
    local node = self.Nodes[object]
    if not node then return end
    
    for _, conn in pairs(node.Connections) do
        conn:Disconnect()
    end
    
    local parent = node.Parent
    for i, child in ipairs(parent.Children) do
        if child == node then
            table.remove(parent.Children, i)
            break
        end
    end
    
    self.Nodes[object] = nil
    self:UpdateTree()
end

function Explorer:MoveObject(object, newParent)
    local node = self.Nodes[object]
    if not node or not self.Nodes[newParent] then return end
    
    local oldParent = node.Parent
    for i, child in ipairs(oldParent.Children) do
        if child == node then
            table.remove(oldParent.Children, i)
            break
        end
    end
    
    node.Parent = self.Nodes[newParent]
    node.Depth = node.Parent.Depth + 1
    table.insert(node.Parent.Children, node)
    self:UpdateTree()
end

function Explorer:UpdateTree()
    self.Tree = {}
    local function buildTree(node, depth)
        table.sort(node.Children, function(a, b)
            local o1 = a.Order or 999
            local o2 = b.Order or 999
            if o1 ~= o2 then return o1 < o2 end
            return a.Object.Name < b.Object.Name
        end)
        
        for _, child in ipairs(node.Children) do
            local nameMatch = self.SearchText == "" or child.Object.Name:lower():find(self.SearchText)
            if nameMatch then
                table.insert(self.Tree, child)
                if self.Expanded[child.Object] or self.SearchText ~= "" then
                    buildTree(child, depth + 1)
                end
            elseif self.SearchText ~= "" then
                buildTree(child, depth) -- Continue searching children
            end
        end
    end
    
    buildTree(self.Nodes[game], 0)
    self:Refresh()
end

function Explorer:Refresh()
    for _, child in pairs(self.ScrollFrame:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    
    local yOffset = 0
    for i, node in ipairs(self.Tree) do
        local entry = CreateInstance("TextButton", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, yOffset),
            Text = string.rep("  ", node.Depth) .. node.Object.Name,
            Font = Enum.Font.SourceSans,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            BackgroundColor3 = self.Selection.Selected[node.Object] and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.ScrollFrame
        })
        
        if #node.Object:GetChildren() > 0 then
            local expand = CreateInstance("TextButton", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(0, node.Depth * 16, 0, 2),
                Text = self.Expanded[node.Object] and "-" or "+",
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Parent = entry
            })
            expand.MouseButton1Click:Connect(function()
                self.Expanded[node.Object] = not self.Expanded[node.Object]
                self:UpdateTree()
            end)
        end
        
        entry.MouseButton1Click:Connect(function()
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                if self.Selection.Selected[node.Object] then
                    self.Selection.Selected[node.Object] = nil
                    for j, obj in ipairs(self.Selection.List) do
                        if obj == node.Object then
                            table.remove(self.Selection.List, j)
                            break
                        end
                    end
                else
                    self.Selection.Selected[node.Object] = true
                    table.insert(self.Selection.List, node.Object)
                end
            else
                self.Selection.List = {node.Object}
                self.Selection.Selected = {[node.Object] = true}
            end
            self:Refresh()
            if self.OnSelectionChanged then
                self.OnSelectionChanged(self.Selection.List)
            end
        end)
        
        yOffset = yOffset + 20
    end
    
    self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Properties Class
local Properties = {}
Properties.__index = Properties

function Properties.new(parent)
    local self = setmetatable({}, Properties)
    self.Properties = {}
    self.Categories = {}
    
    self.Frame = CreateInstance("Frame", {
        Size = UDim2.new(0.5, -5, 1, -40),
        Position = UDim2.new(0.5, 5, 0, 40),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    self.ScrollFrame = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 8,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = self.Frame
    })
    
    return self
end

function Properties:UpdateProperties(objects)
    self.Properties = {}
    self.Categories = {}
    
    if #objects ~= 1 then return end
    local object = objects[1]
    
    local function addProperty(name, value, readOnly)
        local category = "General" -- Simplified; expand with proper categories
        self.Categories[category] = self.Categories[category] or {}
        table.insert(self.Categories[category], {
            Name = name,
            Value = value,
            ReadOnly = readOnly,
            Control = self:CreateControl(name, value, readOnly, object)
        })
    end
    
    for _, prop in pairs({"Name", "Parent", "ClassName", "Archivable"}) do
        local success, value = pcall(function() return object[prop] end)
        if success then
            addProperty(prop, value, prop == "ClassName")
        end
    end
    
    self:Render()
end

function Properties:CreateControl(name, value, readOnly, object)
    local control = {}
    if typeof(value) == "string" or typeof(value) == "number" then
        control.Instance = CreateInstance(readOnly and "TextLabel" or "TextBox", {
            Size = UDim2.new(0.6, 0, 0, 20),
            Text = tostring(value),
            Font = Enum.Font.SourceSans,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        if not readOnly then
            control.Instance.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    local newValue = control.Instance.Text
                    if typeof(value) == "number" then
                        newValue = tonumber(newValue) or value
                    end
                    safeCall(function() object[name] = newValue end)
                end
            end)
        end
    else
        control.Instance = CreateInstance("TextLabel", {
            Size = UDim2.new(0.6, 0, 0, 20),
            Text = tostring(value),
            Font = Enum.Font.SourceSans,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    end
    return control
end

function Properties:Render()
    for _, child in pairs(self.ScrollFrame:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    
    local yOffset = 0
    for category, props in pairs(self.Categories) do
        local catLabel = CreateInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, yOffset),
            Text = category,
            Font = Enum.Font.SourceSansBold,
            TextSize = 16,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderSizePixel = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.ScrollFrame
        })
        yOffset = yOffset + 20
        
        for _, prop in ipairs(props) do
            local row = CreateInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, yOffset),
                BackgroundTransparency = 1,
                Parent = self.ScrollFrame
            })
            
            CreateInstance("TextLabel", {
                Size = UDim2.new(0.4, 0, 1, 0),
                Text = prop.Name,
                Font = Enum.Font.SourceSans,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(220, 220, 220),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row
            })
            
            prop.Control.Instance.Position = UDim2.new(0.4, 0, 0, 0)
            prop.Control.Instance.Parent = row
            
            yOffset = yOffset + 20
        end
    end
    
    self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Main GUI Setup
local function initializeDex()
    local gui = CreateInstance("ScreenGui", {
        Name = "EnhancedDex",
        DisplayOrder = 10,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui
    })
    
    local mainFrame = CreateInstance("Frame", {
        Size = UDim2.new(0.8, 0, 0.8, 0),
        Position = UDim2.new(0.1, 0, 0.1, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        Parent = gui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = mainFrame})
    
    local titleBar = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    CreateInstance("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Text = "Enhanced Dex Explorer",
        Font = Enum.Font.SourceSansBold,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Parent = titleBar
    })
    local closeButton = CreateInstance("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -30, 0, 0),
        Text = "X",
        Font = Enum.Font.SourceSans,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
        Parent = titleBar
    })
    closeButton.MouseButton1Click:Connect(function() gui:Destroy() end)
    
    local explorer = Explorer.new(mainFrame)
    local properties = Properties.new(mainFrame)
    
    explorer.OnSelectionChanged = function(selected)
        properties:UpdateProperties(selected)
    end
    
    return gui
end

-- Initialize
initializeDex()
