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

-- Global variables for Click to Select feature
local selectedObject = nil
local clickToSelectEnabled = false
local selectConnection = nil

-- Function to recursively find selectable objects in a hierarchy
local function findSelectableObjects(parent)
    local selectableObjects = {}
    
    local function recursiveSearch(obj)
        -- เพิ่มเงื่อนไขสำหรับการค้นหาอ็อบเจ็กต์ที่ซ่อนหรือยังไม่ถูกเลือก
        if obj and pcall(function() return obj.Name end) then
            -- เพิ่มประเภทอ็อบเจ็กต์ที่ต้องการเลือก
            local validTypes = {
                "Model", "Part", "MeshPart", "UnionOperation", 
                "Decal", "SpecialMesh", "Folder", "BasePart"
            }
            
            -- ตรวจสอบว่าเป็นประเภทที่ต้องการหรือไม่
            local isValidType = false
            for _, typeName in ipairs(validTypes) do
                if obj:IsA(typeName) then
                    isValidType = true
                    break
                end
            end
            
            if isValidType then
                -- ตรวจสอบเพิ่มเติมเพื่อหลีกเลี่ยงการเลือกวัตถุที่ไม่ต้องการ
                local shouldAdd = true
                
                -- ข้ามตัวละครของผู้เล่น
                for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                    if player.Character == obj or obj:IsDescendantOf(player.Character) then
                        shouldAdd = false
                        break
                    end
                end
                
                -- เพิ่มเงื่อนไขเพื่อกรองวัตถุ
                if shouldAdd and obj.Name ~= "" then
                    table.insert(selectableObjects, obj)
                end
            end
        end
        
        -- ค้นหาใน Children
        for _, child in pairs(obj:GetChildren()) do
            recursiveSearch(child)
        end
    end
    
    recursiveSearch(parent)
    return selectableObjects
end

-- Function to handle mouse click for object selection
local function setupClickToSelect()
    if not clickToSelectEnabled then
        clickToSelectEnabled = true
        selectConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
                local player = game:GetService("Players").LocalPlayer
                local mouse = player:GetMouse()
                
                -- ใช้ Ray casting เพื่อหาอ็อบเจ็กต์ตรงตำแหน่งเคอร์เซอร์
                local camera = workspace.CurrentCamera
                local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
                
                local target, hitPosition = workspace:FindPartOnRayWithIgnoreList(
                    Ray.new(ray.Origin, ray.Direction * 1000), 
                    {player.Character}
                )
                
                if target then
                    -- เริ่มจาก target แล้วค่อยๆ ขึ้นไปหา parent
                    local currentObj = target
                    local objectToSelect = currentObj
                    
                    -- หาอ็อบเจ็กต์ที่เป็นโมเดลหรือมีข้อมูลที่สำคัญ
                    while currentObj do
                        -- เช็คเงื่อนไขเพื่อหาอ็อบเจ็กต์ที่เหมาะสม
                        if currentObj:IsA("Model") or 
                           (pcall(function() return currentObj:GetFullName() end) and 
                            pcall(function() return currentObj.Name end) and 
                            currentObj.Name ~= "") then
                            objectToSelect = currentObj
                        end
                        
                        -- ขึ้นไปหา parent
                        currentObj = currentObj.Parent
                        
                        -- หยุดเมื่อถึง Workspace หรือ nil
                        if not currentObj or currentObj == workspace then
                            break
                        end
                    end
                    
                    -- เลือกอ็อบเจ็กต์
                    selectedObject = objectToSelect
                    
                    -- แสดงการแจ้งเตือน
                    local objectInfo = string.format(
                        "Name: %s\nClass: %s\nPath: %s", 
                        selectedObject.Name, 
                        selectedObject.ClassName, 
                        selectedObject:GetFullName()
                    )
                    
                    Rayfield:Notify({
                        Title = "Object Selected",
                        Content = objectInfo,
                        Duration = 5,
                        Image = nil,
                    })
                else
                    Rayfield:Notify({
                        Title = "Click to Select",
                        Content = "No object found at the cursor location",
                        Duration = 3.5,
                        Image = nil,
                    })
                end
            end
        end)
        
        Rayfield:Notify({
            Title = "Click to Select",
            Content = "Click directly on the object you want to select",
            Duration = 3.5,
            Image = nil,
        })
    else
        -- Disable Click to Select
        if selectConnection then
            selectConnection:Disconnect()
            selectConnection = nil
        end
        clickToSelectEnabled = false
        
        Rayfield:Notify({
            Title = "Click to Select",
            Content = "Disabled",
            Duration = 3.5,
            Image = nil,
        })
    end
end

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
            if depth > 10 then return end -- เพิ่มความลึกในการค้นหา
            
            for _, obj in pairs(parent:GetChildren()) do
                -- เพิ่มประเภทอ็อบเจ็กต์ให้มากขึ้น
                local validTypes = {
                    "Model", "Part", "MeshPart", "UnionOperation", "Decal", "Texture", 
                    "SpecialMesh", "Folder", "Script", "LocalScript", "ModuleScript", 
                    "TextLabel", "ImageLabel", "Frame", "ViewportFrame", "Sound", 
                    "RemoteEvent", "RemoteFunction", "BoolValue", "IntValue", "StringValue"
                }
                
                local isValidType = false
                for _, typeName in ipairs(validTypes) do
                    if obj:IsA(typeName) then
                        isValidType = true
                        break
                    end
                end
                
                if isValidType then
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
                            Instance = obj,
                            Class = obj.ClassName
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
        local dropdownSelectedObject = nil
        
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
                        dropdownSelectedObject = objects[i].Instance
                        break
                    end
                end
            end,
        })
        
        -- เลือกวัตถุแรกโดยอัตโนมัติ
        if #options > 0 then
            dropdownSelectedObject = objects[1].Instance
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
                        dropdownSelectedObject = filteredObjects[1].Instance
                    else
                        dropdownSelectedObject = nil
                    end
                end
            end,
        })

        -- เพิ่มปุ่ม Click to Select
        WorkspaceTab:CreateButton({
            Name = "Click to Select Object",
            Callback = function()
                setupClickToSelect()
            end,
        })
        
        -- ปุ่มสำหรับดึงข้อมูลวัตถุที่เลือก
        WorkspaceTab:CreateButton({
            Name = "Dump Selected Object",
            Callback = function()
                -- เลือกวัตถุจาก dropdown หรือ click to select
                local objectToDump = dropdownSelectedObject or selectedObject
                
                if objectToDump then
                    local safeFileName = objectToDump.Name:gsub("[^%w_]", "_")
                    saveAsRBXM(objectToDump, safeFileName)
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
