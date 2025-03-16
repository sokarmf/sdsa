local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Purge hub",
    LoadingTitle = "Purge OT",
    LoadingSubtitle = "สร้างโดย Lxwnu",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "W"
    },
    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Purge hub keys",
        Note = "No method of obtaining the key is provided",
        FileName = "hub",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {""}
    }
})

local MainTab = Window:CreateTab("หน้าหลัก", nil)
local MainSection = MainTab:CreateSection("เมนูหลัก")

-- Add Workspace category tab
local WorkspaceTab = Window:CreateTab("Workspace", nil)
local WorkspaceSection = WorkspaceTab:CreateSection("Workspace Tools")

-- Add Dumpster (Drmp) function
WorkspaceTab:CreateButton({
    Name = "Dumpster (Drmp)",
    Callback = function()
        -- ลองโหลดบริการสำหรับการบันทึกโมเดล
        local saveModule = nil
        
        -- ลองหาหรือโหลดโมดูลที่จำเป็นในการบันทึกโมเดล
        pcall(function()
            if getgenv().saveinstance then
                saveModule = getgenv().saveinstance
            elseif saveinstance then
                saveModule = saveinstance
            elseif dumpmodel then
                saveModule = dumpmodel
            elseif getsynasset then
                -- มีการเข้ารหัสสำหรับ Synapse X
                saveModule = function(instance)
                    return (syn and syn.secure_call) and syn.secure_call(saveinstance, nil, instance) or saveinstance(instance)
                end
            elseif KRNL_LOADED then
                -- มีการเข้ารหัสสำหรับ KRNL
                saveModule = function(instance)
                    return (krnl and krnl.saveinstance) and krnl.saveinstance(instance) or saveinstance(instance)
                end
            end
        end)
        
        -- แจ้งเตือนถ้าไม่พบฟังก์ชันที่จำเป็น
        if not saveModule then
            pcall(function()
                -- ลองโหลด SaveInstance จาก exploit ที่ใช้อยู่
                saveModule = game:GetService("ReplicatedStorage").SaveInstance
                
                if not saveModule then
                    -- ลองใช้ฟังก์ชัน Dex's SaveInstance
                    saveModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/loglizzy/dexV4/main/saveinstance.lua"))()
                end
            end)
        end
        
        -- ค้นหาวัตถุต่างๆ ในเกม
        local objects = {}
        
        -- ฟังก์ชันค้นหาวัตถุแบบง่าย
        local function findObjects(parent, depth)
            if depth > 2 then return end
            
            for _, obj in pairs(parent:GetChildren()) do
                if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
                    -- ข้ามตัวละครของผู้เล่น
                    local isPlayerModel = false
                    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                        if player.Character == obj then
                            isPlayerModel = true
                            break
                        end
                    end
                    
                    if not isPlayerModel then
                        table.insert(objects, {
                            Name = obj.Name,
                            Path = obj:GetFullName(),
                            Instance = obj
                        })
                    end
                end
                
                findObjects(obj, depth + 1)
            end
        end
        
        findObjects(workspace, 0)
        
        -- สร้างรายการตัวเลือก
        local options = {}
        for _, obj in ipairs(objects) do
            table.insert(options, obj.Name .. " (" .. obj.Path .. ")")
        end
        
        -- ตัวแปรเก็บวัตถุที่ถูกเลือก
        local selectedObject = nil
        
        -- ฟังก์ชั่นสำหรับการบันทึกเป็นไฟล์ RBXM
        local function saveAsRBXM(obj, fileName)
            if not obj then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "No object selected",
                    Duration = 3.5,
                    Image = nil,
                })
                return false
            end
            
            -- สร้างสำเนาของวัตถุเพื่อป้องกันปัญหา
            local clone = obj:Clone()
            
            -- ลองบันทึกวัตถุ
            local success, result = pcall(function()
                -- ลองใช้ฟังก์ชันบันทึกหลายแบบ
                if saveModule then
                    if typeof(saveModule) == "function" then
                        -- กรณีที่ saveModule เป็นฟังก์ชันโดยตรง
                        return saveModule(clone)
                    elseif typeof(saveModule) == "Instance" and saveModule:IsA("RemoteFunction") then
                        -- กรณีที่ saveModule เป็น RemoteFunction
                        return saveModule:InvokeServer(clone)
                    elseif typeof(saveModule) == "table" and saveModule.saveinstance then
                        -- กรณีที่ saveModule เป็นตารางที่มีฟังก์ชัน saveinstance
                        return saveModule.saveinstance(clone)
                    end
                end
                
                -- แนวทางแก้ปัญหาอื่นๆ
                -- ใช้ Roblox API
                local saveAsset = game:GetService("ServerStorage"):FindFirstChild("SaveAsset")
                if saveAsset and saveAsset:IsA("RemoteFunction") then
                    return saveAsset:InvokeServer(clone, "rbxm")
                end
                
                -- ลองอีกวิธีหนึ่ง - สร้างข้อมูล RBXM ด้วยตัวเอง
                if syn and syn.crypt then
                    -- สำหรับ Synapse X
                    local rbxmData = syn.crypt.custom.encrypt("rbxm", game:GetService("HttpService"):JSONEncode({
                        ClassName = clone.ClassName,
                        Name = clone.Name,
                        Properties = {}  -- ต้องใส่ properties ของ object
                    }))
                    return rbxmData
                end
                
                error("No suitable method found to save RBXM")
            end)
            
            if success and result then
                -- ลองบันทึกไฟล์
                pcall(function()
                    writefile(fileName .. ".rbxm", result)
                end)
                
                Rayfield:Notify({
                    Title = "Success",
                    Content = "Object saved to " .. fileName .. ".rbxm",
                    Duration = 3.5,
                    Image = nil,
                })
                return true
            else
                -- ถ้าทุกวิธีข้างต้นล้มเหลว ลองใช้วิธีพิเศษสำหรับเกมนี้
                pcall(function()
                    -- ค้นหาฟังก์ชันพิเศษในเกม
                    for _, v in pairs(getgc(true)) do
                        if typeof(v) == "table" and rawget(v, "SaveInstance") and typeof(v.SaveInstance) == "function" then
                            local rbxmData = v.SaveInstance(clone)
                            if rbxmData then
                                writefile(fileName .. ".rbxm", rbxmData)
                                Rayfield:Notify({
                                    Title = "Success",
                                    Content = "Object saved using game-specific method",
                                    Duration = 3.5,
                                    Image = nil,
                                })
                                return true
                            end
                        end
                    end
                    
                    error("Game-specific method also failed")
                end)
                
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Failed to save as RBXM: " .. tostring(result),
                    Duration = 3.5,
                    Image = nil,
                })
                return false
            end
        end
        
        -- สร้างดร็อปดาวน์สำหรับเลือกวัตถุ
        local dropdown = WorkspaceTab:CreateDropdown({
            Name = "Select Object to Dump",
            Options = options,
            CurrentOption = options[1] or "No objects found",
            Flag = "ObjectDropdown",
            Callback = function(Value)
                for i, option in ipairs(options) do
                    if option == Value then
                        selectedObject = objects[i].Instance
                        
                        -- แสดงข้อมูลของวัตถุที่เลือกใน ESP
                        highlightSelectedObject(selectedObject)
                        break
                    end
                end
            end,
        })
        
        -- เลือกวัตถุแรกโดยอัตโนมัติ
        if #options > 0 then
            selectedObject = objects[1].Instance
        end
        
        -- ฟังก์ชันการค้นหา
        WorkspaceTab:CreateInput({
            Name = "Search by Name",
            PlaceholderText = "Enter object name...",
            RemoveTextAfterFocusLost = false,
            Callback = function(Text)
                if Text and Text ~= "" then
                    local filteredOptions = {}
                    local filteredObjects = {}
                    
                    for i, obj in ipairs(objects) do
                        if string.find(string.lower(obj.Name), string.lower(Text)) then
                            table.insert(filteredOptions, obj.Name .. " (" .. obj.Path .. ")")
                            table.insert(filteredObjects, obj)
                        end
                    end
                    
                    -- อัพเดทดร็อปดาวน์
                    if dropdown.Refresh then
                        dropdown:Refresh(filteredOptions, filteredOptions[1])
                    end
                    
                    -- เลือกวัตถุแรกอัตโนมัติ
                    if #filteredObjects > 0 then
                        selectedObject = filteredObjects[1].Instance
                        
                        -- แสดงข้อมูลของวัตถุที่เลือกใน ESP
                        highlightSelectedObject(selectedObject)
                    else
                        selectedObject = nil
                    end
                end
            end,
        })
        
        -- เพิ่มฟังก์ชัน Click Part to Select ที่มีความเสถียรมากขึ้น
        local clickToSelectEnabled = false
        local clickConnection = nil
        local selectionBox = nil
        local clickDebounce = false
        local raycastParams = nil
        
        -- สร้าง SelectionBox สำหรับไฮไลท์ object ที่เลือก
        local function createSelectionBox()
            if selectionBox then
                selectionBox:Destroy()
            end
            
            selectionBox = Instance.new("SelectionBox")
            selectionBox.Name = "PurgeHubSelectionBox"
            selectionBox.LineThickness = 0.05 -- เพิ่มความหนาของเส้นให้เห็นชัดขึ้น
            selectionBox.Color3 = Color3.fromRGB(0, 255, 0) -- เปลี่ยนเป็นสีเขียวให้เห็นชัดกว่าเดิม
            selectionBox.SurfaceTransparency = 0.8 -- ทำให้มีความโปร่งใสบางส่วน
            selectionBox.Adornee = nil
            selectionBox.Parent = game:GetService("CoreGui")
            
            return selectionBox
        end
        
        -- ฟังก์ชันสำหรับไฮไลท์ object ที่เลือก
        function highlightSelectedObject(object)
            if not object or (typeof(object) == "Instance" and not object:IsDescendantOf(game)) then
                return -- ป้องกันการเกิด error เมื่อ object ถูกลบไปแล้ว
            end
            
            if not selectionBox then
                selectionBox = createSelectionBox()
            end
            
            selectionBox.Adornee = object
            
            -- แสดงข้อมูลของวัตถุที่เลือก
            Rayfield:Notify({
                Title = "Selected Object",
                Content = object.Name .. " (" .. object:GetFullName() .. ")",
                Duration = 3.5,
                Image = nil,
            })
        end
        
        -- ฟังก์ชันสำหรับระบุ model ที่ดีที่สุดจาก part ที่คลิก - เวอร์ชันที่ปรับปรุงใหม่
        local function getBestModelFromPart(part)
            if not part then
                return nil
            end
            
            -- กรณีพิเศษสำหรับ DecalSign, MeshPart, Mesh หรือชิ้นส่วนพิเศษที่มักมีปัญหา
            if part:IsA("MeshPart") or part:IsA("UnionOperation") then
                return part
            end
            
            -- ในกรณีที่เป็น part ธรรมดา ให้พยายามมองหา model ที่อยู่เหนือขึ้นไป
            -- เก็บค่า model ที่มีความสำคัญตามลำดับ
            local bestMatch = part
            
            -- ตรวจสอบว่าเป็น part ของ player หรือไม่
            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                if player.Character and part:IsDescendantOf(player.Character) then
                    return nil -- ถ้าเป็นส่วนของ player ให้ข้ามไป
                end
            end
            
            -- ตรวจสอบว่า part นี้เป็นส่วนหนึ่งของ model หรือไม่
            -- ลองค้นหาจากลูกขึ้นไปถึงพ่อสูงสุด 3 ระดับ
            local currentObject = part
            local level = 0
            local maxLevel = 3
            
            while currentObject and currentObject ~= workspace and level < maxLevel do
                level = level + 1
                
                -- ตรวจสอบว่าเป็น model หรือไม่
                if currentObject:IsA("Model") then
                    -- ถ้าเป็น model และไม่ใช่ character ของผู้เล่น
                    local isPlayerModel = false
                    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                        if player.Character == currentObject then
                            isPlayerModel = true
                            break
                        end
                    end
                    
                    if not isPlayerModel then
                        bestMatch = currentObject
                        break -- หาก model แล้วให้หยุดเลย
                    end
                end
                
                -- วัตถุที่มีความสำคัญ เช่น โต๊ะ เก้าอี้ ที่มักจะมีชื่อเฉพาะ
                local importantNames = {
                    "Chair", "Table", "Bench", "Fire", "Campfire", "Chest", 
                    "Guitar", "Crate", "Cooler", "Dock", "Cabin", "เก้าอี้", 
                    "โต๊ะ", "กองไฟ", "ลัง", "เครื่องดนตรี"
                }
                
                for _, name in ipairs(importantNames) do
                    if string.find(currentObject.Name, name) then
                        bestMatch = currentObject
                        -- กำหนดให้หยุดทันที เพราะพบวัตถุที่มีความสำคัญ
                        return bestMatch
                    end
                end
                
                -- เลื่อนขึ้นไปยัง parent
                currentObject = currentObject.Parent
            end
            
            -- ส่งคืนผลลัพธ์ที่ดีที่สุดที่พบ
            return bestMatch
        end
        
        -- ปุ่มสำหรับเปิด/ปิดโหมด Click to Select
        WorkspaceTab:CreateToggle({
            Name = "Click Part to Select",
            CurrentValue = false,
            Flag = "ClickToSelect",
            Callback = function(Value)
                clickToSelectEnabled = Value
                
                if Value then
                    -- สร้าง SelectionBox ถ้ายังไม่มี
                    if not selectionBox then
                        selectionBox = createSelectionBox()
                    end
                    
                    -- สร้าง RaycastParams สำหรับใช้ในการ raycast อย่างแม่นยำ
                    raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    
                    -- ตั้งค่าให้ข้ามตัวละครของผู้เล่นทั้งหมด
                    local playersToIgnore = {}
                    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                        if player.Character then
                            table.insert(playersToIgnore, player.Character)
                        end
                    end
                    raycastParams.FilterDescendantsInstances = playersToIgnore
                    
                    -- เปลี่ยนสีเมาส์เพื่อแสดงว่ากำลังอยู่ในโหมด Select
                    local player = game:GetService("Players").LocalPlayer
                    if player and player:FindFirstChild("Mouse") then
                        player.Mouse.Icon = "rbxassetid://6031068429" -- เปลี่ยนไอคอนเมาส์เป็นรูปเลือกที่เห็นชัดกว่า
                    end
                    
                    -- สร้าง BeamHighlight ชั่วคราวเพื่อแสดงผลเมื่อเลือก
                    local highlightBeam = nil
                    
                    -- ปรับปรุงเส้นทางในการค้นหาวัตถุให้ลึกขึ้น
                    findObjects(workspace, 0)
                    
                    -- เชื่อมต่อกับ Input ของเมาส์ - ปรับปรุงใหม่
                    clickConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
                        -- ตรวจสอบว่าเป็นคลิกซ้ายและไม่ได้ถูกใช้ไปก่อนแล้ว และไม่อยู่ในช่วง debounce
                        if input.UserInputType == Enum.UserInputType.MouseButton1 and not processed and not clickDebounce then
                            clickDebounce = true -- ป้องกันการคลิกซ้ำเร็วเกินไป
                            
                            -- แสดงแจ้งเตือนเล็กๆ ว่ากำลังทำงาน
                            Rayfield:Notify({
                                Title = "กำลังเลือก...",
                                Content = "กำลังพยายามเลือกวัตถุ",
                                Duration = 1,
                                Image = nil,
                            })
                            
                            -- ใช้ mouse.Target โดยตรงแทนการใช้ raycast
                            local player = game:GetService("Players").LocalPlayer
                            local mouse = player:GetMouse()
                            
                            -- ใช้ mouse.Target จากเมาส์โดยตรง (วิธีดั้งเดิม)
                            local hitPart = mouse.Target
                            
                            -- ถ้าไม่สามารถหา part ที่คลิกได้ ลองใช้ raycast
                            if not hitPart then
                                -- ใช้ raycast เป็นแผนสำรอง
                                local camera = workspace.CurrentCamera
                                local mousePos = mouse.Hit.Position
                                local direction = (mousePos - camera.CFrame.Position).Unit
                                local rayOrigin = camera.CFrame.Position
                                local ray = Ray.new(rayOrigin, direction * 1000) -- ระยะสูงสุด 1000 studs
                                
                                -- ทำ raycast
                                local raycastResult = workspace:Raycast(rayOrigin, direction * 1000, raycastParams)
                                if raycastResult then
                                    hitPart = raycastResult.Instance
                                end
                            end
                            
                            if hitPart
                                
                                -- สร้าง effect ไฮไลท์ชั่วคราวที่จุดที่คลิก
                                if highlightBeam then
                                    highlightBeam:Destroy()
                                end
                                
                                local highlightPart = Instance.new("Part")
                                highlightPart.Size = Vector3.new(0.2, 0.2, 0.2)
                                highlightPart.Anchored = true
                                highlightPart.CanCollide = false
                                highlightPart.Transparency = 1
                                highlightPart.CFrame = CFrame.new(raycastResult.Position)
                                highlightPart.Parent = workspace
                                
                                local attachment0 = Instance.new("Attachment")
                                attachment0.Parent = highlightPart
                                
                                local attachment1 = Instance.new("Attachment")
                                attachment1.Position = Vector3.new(0, 2, 0)
                                attachment1.Parent = highlightPart
                                
                                highlightBeam = Instance.new("Beam")
                                highlightBeam.Width0 = 0.5
                                highlightBeam.Width1 = 0
                                highlightBeam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
                                highlightBeam.Attachment0 = attachment0
                                highlightBeam.Attachment1 = attachment1
                                highlightBeam.Parent = highlightPart
                                
                                -- ลบ effect หลังจาก 1 วินาที
                                game:GetService("Debris"):AddItem(highlightPart, 1)
                                
                                -- หา model ที่ดีที่สุดจาก part ที่คลิก
                                local model = getBestModelFromPart(hitPart)
                                
                                if model then
                                    -- อัพเดทวัตถุที่เลือก
                                    selectedObject = model
                                    
                                    -- อัพเดทการแสดงผล
                                    highlightSelectedObject(model)
                                    
                                    -- เพิ่มวัตถุเข้าไปในรายการถ้ายังไม่มี
                                    local objectPath = model:GetFullName()
                                    local objectExists = false
                                    local objectIndex = nil
                                    
                                    for i, obj in ipairs(objects) do
                                        if obj.Instance == model then
                                            objectExists = true
                                            objectIndex = i
                                            break
                                        end
                                    end
                                    
                                    if not objectExists then
                                        table.insert(objects, {
                                            Name = model.Name,
                                            Path = objectPath,
                                            Instance = model
                                        })
                                        
                                        -- อัพเดทตัวเลือกในดร็อปดาวน์
                                        local newOption = model.Name .. " (" .. objectPath .. ")"
                                        table.insert(options, newOption)
                                        objectIndex = #options
                                        
                                        if dropdown.Refresh then
                                            dropdown:Refresh(options)
                                        end
                                    end
                                    
                                    -- อัพเดทค่าในดร็อปดาวน์
                                    if objectIndex and dropdown.Set then
                                        dropdown:Set(options[objectIndex])
                                    end
                                else
                                    Rayfield:Notify({
                                        Title = "Cannot Select",
                                        Content = "Could not find a suitable object at this position",
                                        Duration = 3.5,
                                        Image = nil,
                                    })
                                end
                            end
                            
                            -- รอเวลาเล็กน้อยก่อนปลดล็อค debounce
                            task.wait(0.5)
                            clickDebounce = false
                        end
                    end)
                    
                    Rayfield:Notify({
                        Title = "Click to Select Enabled",
                        Content = "Click on any part to select it for dumping",
                        Duration = 3.5,
                        Image = nil,
                    })
                else
                    -- ปิดโหมด Click to Select
                    if clickConnection then
                        clickConnection:Disconnect()
                        clickConnection = nil
                    end
                    
                    -- คืนค่าเมาส์กลับเป็นปกติ
                    local player = game:GetService("Players").LocalPlayer
                    if player and player:FindFirstChild("Mouse") then
                        player.Mouse.Icon = ""
                    end
                    
                    Rayfield:Notify({
                        Title = "Click to Select Disabled",
                        Content = "Click to select mode has been turned off",
                        Duration = 3.5,
                        Image = nil,
                    })
                end
            end,
        })
        
        -- ปุ่มสำหรับดึงข้อมูลวัตถุที่เลือก
        WorkspaceTab:CreateButton({
            Name = "Dump Selected Object",
            Callback = function()
                if selectedObject then
                    local safeFileName = selectedObject.Name:gsub("[^%w_]", "_")
                    saveAsRBXM(selectedObject, safeFileName)
                else
                    Rayfield:Notify({
                        Title = "Error",
                        Content = "Please select an object first",
                        Duration = 3.5,
                        Image = nil,
                    })
                end
            end,
        })
        
        -- ปุ่มสำหรับดึงข้อมูลวัตถุทั้งหมด
        WorkspaceTab:CreateButton({
            Name = "Dump All Objects",
            Callback = function()
                local successCount = 0
                
                for i, obj in ipairs(objects) do
                    local safeFileName = obj.Name:gsub("[^%w_]", "_") .. "_" .. i
                    
                    if saveAsRBXM(obj.Instance, safeFileName) then
                        successCount = successCount + 1
                    end
                    
                    -- รอสักครู่เพื่อไม่ให้เกมค้าง
                    task.wait(0.1)
                end
                
                Rayfield:Notify({
                    Title = "Dump Complete",
                    Content = "Successfully dumped " .. successCount .. " out of " .. #objects .. " objects",
                    Duration = 3.5,
                    Image = nil,
                })
            end,
        })
    end,
})