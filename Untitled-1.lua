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

-- Function to handle mouse click for object selection
local function setupClickToSelect()
    if not clickToSelectEnabled then
        clickToSelectEnabled = true
        selectConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
                local player = game:GetService("Players").LocalPlayer
                local mouse = player:GetMouse()
                local target = mouse.Target
                
                if target then
                    -- Select the object
                    selectedObject = target
                    
                    -- Notify the user
                    Rayfield:Notify({
                        Title = "Object Selected",
                        Content = "Selected: " .. target:GetFullName(),
                        Duration = 3.5,
                        Image = nil,
                    })
                end
            end
        end)
        
        Rayfield:Notify({
            Title = "Click to Select",
            Content = "Click on any part in the game to select it",
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
