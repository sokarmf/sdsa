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
local highlightInstance = nil

-- Create a highlight effect for selected objects
local function createHighlight()
    if not highlightInstance then
        highlightInstance = Instance.new("Highlight")
        highlightInstance.FillColor = Color3.fromRGB(0, 255, 0)
        highlightInstance.OutlineColor = Color3.fromRGB(0, 255, 0)
        highlightInstance.FillTransparency = 0.5
        highlightInstance.OutlineTransparency = 0
        highlightInstance.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlightInstance.Parent = game:GetService("CoreGui")
    end
    return highlightInstance
end

-- Function to highlight an object
local function highlightObject(object)
    local highlight = createHighlight()
    highlight.Adornee = object
    highlight.Enabled = true
end

-- Function to clear highlight
local function clearHighlight()
    if highlightInstance then
        highlightInstance.Adornee = nil
        highlightInstance.Enabled = false
    end
end

-- Improved function to recursively find selectable objects in a hierarchy with better filtering
local function findSelectableObjects(parent, maxDepth, currentDepth)
    currentDepth = currentDepth or 0
    maxDepth = maxDepth or 10
    
    local selectableObjects = {}
    
    if currentDepth > maxDepth then
        return selectableObjects
    end
    
    local function isSelectableType(obj)
        local validTypes = {
            "Model", "Part", "MeshPart", "UnionOperation", 
            "Decal", "SpecialMesh", "Folder", "BasePart",
            "Terrain", "Workspace"
        }
        
        for _, typeName in ipairs(validTypes) do
            if obj:IsA(typeName) then
                return true
            end
        end
        
        return false
    end
    
    local function shouldSkipObject(obj)
        -- Skip player characters
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            if player.Character and (obj == player.Character or obj:IsDescendantOf(player.Character)) then
                return true
            end
        end
        
        -- Skip CoreGui elements
        if obj:IsDescendantOf(game:GetService("CoreGui")) then
            return true
        end
        
        -- Skip empty named objects
        if obj.Name == "" then
            return true
        end
        
        return false
    end
    
    -- Process current parent
    if parent and isSelectableType(parent) and not shouldSkipObject(parent) then
        table.insert(selectableObjects, parent)
    end
    
    -- Process children
    if parent and parent:GetChildren then
        for _, child in pairs(parent:GetChildren()) do
            for _, obj in pairs(findSelectableObjects(child, maxDepth, currentDepth + 1)) do
                table.insert(selectableObjects, obj)
            end
        end
    end
    
    return selectableObjects
end

-- Optimized function to handle mouse click for object selection
local function setupClickToSelect()
    if not clickToSelectEnabled then
        clickToSelectEnabled = true
        
        -- Create a new connection if it doesn't exist
        if not selectConnection then
            selectConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
                    local player = game:GetService("Players").LocalPlayer
                    local mouse = player:GetMouse()
                    
                    -- Use Ray casting to find object at cursor position
                    local camera = workspace.CurrentCamera
                    local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
                    
                    local target, hitPosition = workspace:FindPartOnRayWithIgnoreList(
                        Ray.new(ray.Origin, ray.Direction * 5000), 
                        {player.Character}
                    )
                    
                    if target then
                        -- Find the most appropriate ancestor model
                        local currentObj = target
                        local objectToSelect = currentObj
                        
                        -- Look for appropriate object or model
                        while currentObj and currentObj ~= workspace do
                            -- Prioritize Models or significant objects
                            if currentObj:IsA("Model") or 
                               (currentObj.Name ~= "" and 
                                not currentObj:IsDescendantOf(game:GetService("Players").LocalPlayer.Character)) then
                                objectToSelect = currentObj
                                
                                -- If we find a meaningful model, prefer it
                                if currentObj:IsA("Model") and currentObj.Name ~= "" then
                                    break
                                end
                            end
                            
                            -- Move up to parent
                            currentObj = currentObj.Parent
                        end
                        
                        -- Select the object
                        selectedObject = objectToSelect
                        
                        -- Highlight the selected object
                        clearHighlight()
                        highlightObject(selectedObject)
                        
                        -- Show notification
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
        end
        
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
        clearHighlight()
        
        Rayfield:Notify({
            Title = "Click to Select",
            Content = "Disabled",
            Duration = 3.5,
            Image = nil,
        })
    end
end

-- Enhanced save function that consolidates multiple saving methods for better reliability
local function saveObjectAsRBXM(obj, fileName)
    if not obj then
        return false, "No object selected"
    end
    
    -- Create a safe clone of the object to prevent in-game issues
    local success, clone
    success, clone = pcall(function()
        return obj:Clone()
    end)
    
    if not success or not clone then
        return false, "Failed to clone object. It might be locked or protected."
    end
    
    -- Ensure fileName is safe
    fileName = fileName or obj.Name
    fileName = fileName:gsub("[^%w_]", "_")
    
    -- Check if file already exists and add timestamp to avoid overwriting
    if pcall(function() return readfile(fileName .. ".rbxm") end) then
        fileName = fileName .. "_" .. os.time()
    end
    
    -- Try all available saving methods
    local methods = {
        -- Method 1: Use saveinstance directly if available
        function()
            if saveinstance then
                local data = saveinstance(clone)
                writefile(fileName .. ".rbxm", data)
                return true
            end
            return false
        end,
        
        -- Method 2: Use getgenv().saveinstance
        function()
            if getgenv and getgenv().saveinstance then
                local data = getgenv().saveinstance(clone)
                writefile(fileName .. ".rbxm", data)
                return true
            end
            return false
        end,
        
        -- Method 3: Use dumpmodel
        function()
            if dumpmodel then
                dumpmodel(clone, fileName .. ".rbxm")
                return true
            end
            return false
        end,
        
        -- Method 4: Use Synapse-specific methods
        function()
            if syn and syn.write_file then
                if syn.save_instance then
                    local data = syn.save_instance(clone)
                    syn.write_file(fileName .. ".rbxm", data)
                    return true
                end
            end
            return false
        end,
        
        -- Method 5: Use KRNL-specific methods
        function()
            if KRNL_LOADED and krnl and krnl.saveinstance then
                local data = krnl.saveinstance(clone)
                writefile(fileName .. ".rbxm", data)
                return true
            end
            return false
        end,
        
        -- Method 6: Use generic writefile with instance-to-string converter
        function()
            if getinstancecontent and writefile then
                local data = getinstancecontent(clone)
                writefile(fileName .. ".rbxm", data)
                return true
            end
            return false
        end,
        
        -- Method 7: Try game-specific methods from ReplicatedStorage
        function()
            local saveInstance = game:GetService("ReplicatedStorage"):FindFirstChild("SaveInstance")
            if saveInstance and saveInstance:IsA("RemoteFunction") then
                local data = saveInstance:InvokeServer(clone)
                writefile(fileName .. ".rbxm", data)
                return true
            end
            return false
        end,
        
        -- Method 8: Advanced method - search for SaveInstance in memory
        function()
            for _, v in pairs(getgc(true)) do
                if typeof(v) == "table" and rawget(v, "SaveInstance") and typeof(v.SaveInstance) == "function" then
                    local data = v.SaveInstance(clone)
                    if data then
                        writefile(fileName .. ".rbxm", data)
                        return true
                    end
                end
            end
            return false
        end
    }
    
    -- Try all methods
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            return true, fileName .. ".rbxm"
        end
    end
    
    -- If we get here, all methods failed
    return false, "All saving methods failed. This object might be unsupported."
end

-- Optimized function to get all objects in the workspace efficiently
local function getAllObjects(includePlayers, maxDepth)
    local startTime = tick()
    
    -- Get all objects efficiently
    local allObjects = {}
    local processed = {}  -- Use a table for O(1) lookups
    
    -- Add important base locations
    local locations = {workspace}
    
    -- Add lighting and other services if needed
    table.insert(locations, game:GetService("Lighting"))
    table.insert(locations, game:GetService("ReplicatedStorage"))
    
    -- Process each location
    for _, location in ipairs(locations) do
        local objects = findSelectableObjects(location, maxDepth or 15)
        
        for _, obj in ipairs(objects) do
            -- Use a unique identifier for each object
            local uniqueId = obj:GetFullName()
            
            -- Only add if not already processed
            if not processed[uniqueId] then
                processed[uniqueId] = true
                
                -- Skip player objects if not including players
                local isPlayerObject = false
                if not includePlayers then
                    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                        if player.Character and obj:IsDescendantOf(player.Character) then
                            isPlayerObject = true
                            break
                        end
                    end
                end
                
                -- Add objects that pass filters
                if not isPlayerObject then
                    table.insert(allObjects, {
                        Name = obj.Name,
                        Path = obj:GetFullName(),
                        Instance = obj,
                        Class = obj.ClassName
                    })
                end
            end
        end
    end
    
    -- Sort objects by path for easier navigation
    table.sort(allObjects, function(a, b)
        return a.Path < b.Path
    end)
    
    local endTime = tick()
    
    Rayfield:Notify({
        Title = "Object Scan Complete",
        Content = "Found " .. #allObjects .. " objects in " .. string.format("%.2f", endTime - startTime) .. " seconds",
        Duration = 3.5,
        Image = nil,
    })
    
    return allObjects
end

-- Enhanced object categorization for better organization
local function categorizeObjects(objects)
    local categories = {
        ["Models"] = {},
        ["Parts"] = {},
        ["Terrain"] = {},
        ["Lighting"] = {},
        ["Effects"] = {},
        ["GUI"] = {},
        ["Other"] = {}
    }
    
    for _, obj in ipairs(objects) do
        local instance = obj.Instance
        local category = "Other"
        
        if instance:IsA("Model") then
            category = "Models"
        elseif instance:IsA("BasePart") or instance:IsA("MeshPart") or instance:IsA("UnionOperation") then
            category = "Parts"
        elseif instance:IsA("Terrain") then
            category = "Terrain"
        elseif instance:IsDescendantOf(game:GetService("Lighting")) then
            category = "Lighting"
        elseif instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then
            category = "Effects"
        elseif instance:IsA("GuiObject") or instance:IsA("ScreenGui") or instance:IsA("SurfaceGui") then
            category = "GUI"
        end
        
        table.insert(categories[category], obj)
    end
    
    return categories
end

-- Add Dumpster (Drmp) function with enhanced abilities
WorkspaceTab:CreateButton({
    Name = "Enhanced Map Dumper",
    Callback = function()
        -- Clear any existing highlights
        clearHighlight()
        
        -- Initialization notification
        Rayfield:Notify({
            Title = "Map Dumper",
            Content = "Scanning map objects, please wait...",
            Duration = 3.5,
            Image = nil,
        })
        
        -- Scan for objects in the game
        local objects = getAllObjects(false, 20)  -- Don't include players, search deeper
        
        -- Create categories
        local categories = categorizeObjects(objects)
        
        -- Create options for dropdown
        local options = {}
        for _, obj in ipairs(objects) do
            table.insert(options, obj.Name .. " [" .. obj.Class .. "] " .. obj.Path)
        end
        
        -- Variable to store selected object
        local dropdownSelectedObject = nil
        
        -- Create section for object selection
        local mapSection = WorkspaceTab:CreateSection("Map Objects")
        
        -- Create dropdown for object selection
        local dropdown = WorkspaceTab:CreateDropdown({
            Name = "Select Object to Dump",
            Options = options,
            CurrentOption = options[1] or "No objects found",
            Flag = "ObjectDropdown",
            Callback = function(Value)
                for i, option in ipairs(options) do
                    if option == Value then
                        dropdownSelectedObject = objects[i].Instance
                        
                        -- Highlight the selected object
                        clearHighlight()
                        highlightObject(dropdownSelectedObject)
                        break
                    end
                end
            end,
        })
        
        -- Select first object by default
        if #options > 0 then
            dropdownSelectedObject = objects[1].Instance
            highlightObject(dropdownSelectedObject)
        end
        
        -- Add search functionality
        WorkspaceTab:CreateInput({
            Name = "Search Objects",
            PlaceholderText = "Enter name or class...",
            RemoveTextAfterFocusLost = false,
            Callback = function(Text)
                if Text and Text ~= "" then
                    local filteredOptions = {}
                    local filteredObjects = {}
                    
                    for i, obj in ipairs(objects) do
                        if string.find(string.lower(obj.Name), string.lower(Text), 1, true) or
                           string.find(string.lower(obj.Class), string.lower(Text), 1, true) or
                           string.find(string.lower(obj.Path), string.lower(Text), 1, true) then
                            table.insert(filteredOptions, obj.Name .. " [" .. obj.Class .. "] " .. obj.Path)
                            table.insert(filteredObjects, obj)
                        end
                    end
                    
                    -- Update dropdown
                    dropdown:Refresh(filteredOptions, filteredOptions[1])
                    
                    -- Select first filtered object
                    if #filteredObjects > 0 then
                        dropdownSelectedObject = filteredObjects[1].Instance
                        clearHighlight()
                        highlightObject(dropdownSelectedObject)
                    else
                        dropdownSelectedObject = nil
                        clearHighlight()
                    end
                    
                    Rayfield:Notify({
                        Title = "Search Results",
                        Content = "Found " .. #filteredOptions .. " matching objects",
                        Duration = 2,
                        Image = nil,
                    })
                else
                    -- If search is cleared, restore full list
                    dropdown:Refresh(options, options[1])
                    if #objects > 0 then
                        dropdownSelectedObject = objects[1].Instance
                        clearHighlight()
                        highlightObject(dropdownSelectedObject)
                    end
                end
            end,
        })
        
        -- Add Click to Select button
        WorkspaceTab:CreateButton({
            Name = "Click to Select Object",
            Callback = function()
                setupClickToSelect()
            end,
        })
        
        -- Add button to dump selected object
        WorkspaceTab:CreateButton({
            Name = "Dump Selected Object",
            Callback = function()
                -- Use either dropdown selected or click selected object
                local objectToDump = dropdownSelectedObject or selectedObject
                
                if objectToDump then
                    Rayfield:Notify({
                        Title = "Dumping Object",
                        Content = "Saving " .. objectToDump.Name .. "...",
                        Duration = 3.5,
                        Image = nil,
                    })
                    
                    local success, result = saveObjectAsRBXM(objectToDump, objectToDump.Name)
                    
                    if success then
                        Rayfield:Notify({
                            Title = "Success",
                            Content = "Object saved to " .. result,
                            Duration = 3.5,
                            Image = nil,
                        })
                    else
                        Rayfield:Notify({
                            Title = "Error",
                            Content = result or "Failed to save object",
                            Duration = 3.5,
                            Image = nil,
                        })
                    end
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
        
        -- Advanced options section
        local advancedSection = WorkspaceTab:CreateSection("Advanced Options")
        
        -- Function to dump entire workspace in chunks
        WorkspaceTab:CreateButton({
            Name = "Dump Entire Map",
            Callback = function()
                Rayfield:Notify({
                    Title = "Full Map Dump",
                    Content = "Starting full map dump. This may take some time...",
                    Duration = 5,
                    Image = nil,
                })
                
                -- Create a folder to store the files
                local folderName = "MapDump_" .. game.PlaceId .. "_" .. os.time()
                pcall(function()
                    makefolder(folderName)
                end)
                
                -- Counter variables
                local totalObjects = #objects
                local successCount = 0
                local failCount = 0
                local lastUpdateTime = tick()
                
                -- Process objects in chunks to avoid game freezing
                local chunkSize = 5
                local currentIndex = 1
                
                -- Function to process the next chunk
                local function processNextChunk()
                    local endIndex = math.min(currentIndex + chunkSize - 1, totalObjects)
                    
                    for i = currentIndex, endIndex do
                        local obj = objects[i]
                        local safeName = obj.Name:gsub("[^%w_]", "_") .. "_" .. i
                        local filePath = folderName .. "/" .. safeName
                        
                        local success, result = saveObjectAsRBXM(obj.Instance, filePath)
                        
                        if success then
                            successCount = successCount + 1
                        else
                            failCount = failCount + 1
                        end
                        
                        -- Update progress notification every 2 seconds
                        if tick() - lastUpdateTime > 2 then
                            lastUpdateTime = tick()
                            Rayfield:Notify({
                                Title = "Dumping Progress",
                                Content = string.format("Progress: %d/%d (%.1f%%)", i, totalObjects, (i/totalObjects)*100),
                                Duration = 1,
                                Image = nil,
                            })
                        end
                    end
                    
                    currentIndex = endIndex + 1
                    
                    -- Check if we're done
                    if currentIndex <= totalObjects then
                        -- Schedule next chunk with a slight delay
                        task.delay(0.1, processNextChunk)
                    else
                        -- All done, show final notification
                        Rayfield:Notify({
                            Title = "Dump Complete",
                            Content = string.format("Successfully dumped %d/%d objects to folder: %s", 
                                successCount, totalObjects, folderName),
                            Duration = 10,
                            Image = nil,
                        })
                    end
                end
                
                -- Start processing chunks
                processNextChunk()
            end,
        })
        
        -- Add button to dump specific categories
        for category, categoryObjects in pairs(categories) do
            if #categoryObjects > 0 then
                WorkspaceTab:CreateButton({
                    Name = "Dump All " .. category .. " (" .. #categoryObjects .. ")",
                    Callback = function()
                        -- Create a folder
                        local folderName = category .. "_" .. os.time()
                        pcall(function()
                            makefolder(folderName)
                        end)
                        
                        Rayfield:Notify({
                            Title = "Category Dump",
                            Content = "Starting dump of " .. #categoryObjects .. " " .. category .. "...",
                            Duration = 5,
                            Image = nil,
                        })
                        
                        -- Counter variables
                        local successCount = 0
                        local failCount = 0
                        local lastUpdateTime = tick()
                        
                        -- Process objects in chunks
                        local chunkSize = 5
                        local totalObjects = #categoryObjects
                        local currentIndex = 1
                        
                        -- Function to process the next chunk
                        local function processNextChunk()
                            local endIndex = math.min(currentIndex + chunkSize - 1, totalObjects)
                            
                            for i = currentIndex, endIndex do
                                local obj = categoryObjects[i]
                                local safeName = obj.Name:gsub("[^%w_]", "_") .. "_" .. i
                                local filePath = folderName .. "/" .. safeName
                                
                                local success, result = saveObjectAsRBXM(obj.Instance, filePath)
                                
                                if success then
                                    successCount = successCount + 1
                                else
                                    failCount = failCount + 1
                                end
                                
                                -- Update progress
                                if tick() - lastUpdateTime > 2 then
                                    lastUpdateTime = tick()
                                    Rayfield:Notify({
                                        Title = category .. " Dump Progress",
                                        Content = string.format("Progress: %d/%d (%.1f%%)", i, totalObjects, (i/totalObjects)*100),
                                        Duration = 1,
                                        Image = nil,
                                    })
                                end
                            end
                            
                            currentIndex = endIndex + 1
                            
                            -- Check if we're done
                            if currentIndex <= totalObjects then
                                -- Schedule next chunk
                                task.delay(0.1, processNextChunk)
                            else
                                -- All done
                                Rayfield:Notify({
                                    Title = category .. " Dump Complete",
                                    Content = string.format("Successfully dumped %d/%d objects to folder: %s", 
                                        successCount, totalObjects, folderName),
                                    Duration = 5,
                                    Image = nil,
                                })
                            end
                        end
                        
                        -- Start processing
                        processNextChunk()
                    end,
                })
            end
        end
        
        -- Add optimized methods for large maps
        WorkspaceTab:CreateSection("Large Map Options")
        
        -- Add button to dump entire workspace at once (terrain method)
        WorkspaceTab:CreateButton({
            Name = "Dump Entire Map (Terrain Method)",
            Callback = function()
                Rayfield:Notify({
                    Title = "Terrain Method",
                    Content = "Attempting to dump entire map using terrain method...",
                    Duration = 5,
                    Image = nil,
                })
                
                local success, result
                
                -- Try several methods
                
                -- Method 1: Try to save workspace directly
                success, result = saveObjectAsRBXM(workspace, "FullMap_" .. os.time())
                
                if success then
                    Rayfield:Notify({
                        Title = "Success",
                        Content = "Full map saved to " .. result,
                        Duration = 5,
                        Image = nil,
                    })
                    return
                end
                
                -- Method 2: Try to save terrain and main models separately
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    success, result = saveObjectAsRBXM(terrain, "MapTerrain_" .. os.time())
                    if success then
                        Rayfield:Notify({
                            Title = "Partial Success",
                            Content = "Map terrain saved to " .. result,
                            Duration = 3,
                            Image = nil,
                        })
                    end
                end
                
                -- Method 3: Try to save main workspace children
                local savedCount = 0
                for _, child in pairs(workspace:GetChildren()) do
                    if child:IsA("Model") and child.Name ~= "" and not child:IsA("Player") then
                        success, result = saveObjectAsRBXM(child, "MapPart_" .. child.Name .. "_" .. os.time())
                        if success then
                            savedCount = savedCount + 1
                        end
                        task.wait(0.1) -- Prevent game freeze
                    end
                end
                
                if savedCount > 0 then
                    Rayfield:Notify({
                        Title = "Partial Success",
                        Content = "Saved " .. savedCount .. " major map components",
                        Duration = 5,
                        Image = nil,
                    })
                else
                    Rayfield:Notify({
                        Title = "Failed",
                        Content = "Could not save map using any method. Try individual objects.",
                        Duration = 5,
                        Image = nil,
                    })
                end
            end,
        })
    end,
})

-- Add an improved button that combines the best methods
WorkspaceTab:CreateButton({
    Name = "🔥 One-Click Full Map Dumper 🔥",
    Callback = function()
        Rayfield:Notify({
            Title = "Super Map Dumper",
            Content = "Starting optimized full map dump...",
            Duration = 5,
            Image = nil,
        })
        
        -- Create a main folder
        local mainFolder = "SuperMapDump_" .. game.PlaceId .. "_" .. os.time()
        pcall(function()
            makefolder(mainFolder)
        end)
        
        -- First, try to save the entire workspace at once
        local wholeMapSuccess, wholeMapResult = saveObjectAsRBXM(workspace, mainFolder .. "/EntireMap")
        
        if wholeMapSuccess then
            Rayfield:Notify({
                Title = "Success!",
                Content = "Entire map saved successfully to " .. wholeMapResult,
                Duration = 5,
                Image = nil,
            })
            return
        end
        
        -- If whole map save failed, fallback to chunked approach
        Rayfield:Notify({
            Title = "Direct Save Failed",
            Content = "Switching to advanced chunked approach...",
            Duration = 3,
            Image = nil,
        })
        
        -- Scan with higher depth to catch everything
        local allObjects = getAllObjects(false, 30)
        
        -- Create categories for better organization
        local categories = categorizeObjects(allObjects)
        
        -- Create folders for each category
        for category, _ in pairs(categories) do
            pcall(function()
                makefolder(mainFolder .. "/" .. category)
            end)
        end
        
        -- Create a processing queue to handle all objects efficiently
        local queue = {}
        for category, categoryObjects in pairs(categories) do
            for _, obj in ipairs(categoryObjects) do
                table.insert(queue, {
                    object = obj.Instance,
                    name = obj.Name:gsub("[^%w_]", "_"),
                    path = mainFolder .. "/" .. category .. "/"
                })
            end
        end
        
        -- Process queue in chunks
        local totalObjects = #queue
        local processedCount = 0
        local successCount = 0
        local batchSize = 5
        local lastUpdateTime = tick()
        
        -- Display progress bar UI
        local ProgressSection = WorkspaceTab:CreateSection("Dump Progress")
        
        -- Process function for queue
        local function processQueue()
            while #queue > 0 do
                local batch = {}
                for i = 1, math.min(batchSize, #queue) do
                    table.insert(batch, table.remove(queue, 1))
                end
                
                for _, item in ipairs(batch) do
                    local fileName = item.path .. item.name .. "_" .. processedCount
                    local success, result = saveObjectAsRBXM(item.object, fileName)
                    
                    processedCount = processedCount + 1
                    if success then
                        successCount = successCount + 1
                    end
                    
                    -- Update progress notification periodically
                    if tick() - lastUpdateTime > 1 then
                        lastUpdateTime = tick()
                        
                        -- Calculate progress percentage
                        local percentage = math.floor((processedCount / totalObjects) * 100)
                        
                        Rayfield:Notify({
                            Title = "Map Dump Progress",
                            Content = string.format("%d%% complete (%d/%d objects saved)", 
                                percentage, processedCount, totalObjects),
                            Duration = 1,
                            Image = nil,
                        })
                    end
                    
                    -- Small delay to prevent game freeze
                    task.wait(0.05)
                end
                
                -- Add slightly longer delay between batches
                task.wait(0.1)
                
                -- Check if we're done
                if #queue == 0 then
                    Rayfield:Notify({
                        Title = "Map Dump Complete!",
                        Content = string.format("Successfully saved %d/%d objects to folder: %s", 
                            successCount, totalObjects, mainFolder),
                        Duration = 10,
                        Image = nil,
                    })
                    
                    -- Create a log file with summary
                    local logContent = string.format([[
Super Map Dumper Summary:
------------------------
Game ID: %d
Time: %s
Total Objects Found: %d
Successfully Saved: %d
Success Rate: %.1f%%
Saved to Folder: %s
]], 
                        game.PlaceId, 
                        os.date(), 
                        totalObjects, 
                        successCount, 
                        (successCount/totalObjects) * 100,
                        mainFolder)
                    
                    pcall(function()
                        writefile(mainFolder .. "/dump_summary.txt", logContent)
                    end)
                end
            end
        end
        
        -- Start processing
        task.spawn(processQueue)
    end,
})

-- Add special terrain dumper
WorkspaceTab:CreateButton({
    Name = "Extract Map Terrain",
    Callback = function()
        Rayfield:Notify({
            Title = "Terrain Extractor",
            Content = "Attempting to extract terrain data...",
            Duration = 3,
            Image = nil,
        })
        
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if not terrain then
            Rayfield:Notify({
                Title = "Error",
                Content = "No terrain found in this game",
                Duration = 3,
                Image = nil,
            })
            return
        end
        
        -- Try to get terrain region
        local success, result = pcall(function()
            local regions = {}
            
            -- Get terrain extents
            local minX, minY, minZ = -2048, -2048, -2048
            local maxX, maxY, maxZ = 2048, 2048, 2048
            
            -- Create a list of regions to capture terrain in chunks
            local regionSize = 512 -- Size of each region chunk
            for x = minX, maxX, regionSize do
                for y = minY, maxY, regionSize do
                    for z = minZ, maxZ, regionSize do
                        local region = Region3.new(
                            Vector3.new(x, y, z),
                            Vector3.new(x + regionSize, y + regionSize, z + regionSize)
                        )
                        
                        -- Only add regions that have material
                        local materialCount = 0
                        local materials = terrain:ReadVoxels(region, 4)
                        
                        for i = 1, #materials do
                            if materials[i] ~= Enum.Material.Air then
                                materialCount = materialCount + 1
                            end
                            
                            if materialCount > 10 then -- Only save if it has meaningful terrain
                                table.insert(regions, region)
                                break
                            end
                        end
                    end
                end
            end
            
            -- Create a folder for terrain data
            local folderName = "TerrainData_" .. game.PlaceId .. "_" .. os.time()
            pcall(function()
                makefolder(folderName)
            end)
            
            -- Save each region
            for i, region in ipairs(regions) do
                local fileName = folderName .. "/terrain_region_" .. i
                
                -- Get materials and occupancy
                local materials = terrain:ReadVoxels(region, 4)
                local occupancy = terrain:ReadVoxels(region, 4)
                
                -- Save materials and occupancy as binary files
                pcall(function()
                    -- Convert to string representation
                    local dataString = "Region: " .. tostring(region.CFrame.Position) .. "\n"
                    dataString = dataString .. "Size: " .. tostring(region.Size) .. "\n"
                    dataString = dataString .. "Materials: " .. #materials .. " voxels\n"
                    
                    -- Save to file
                    writefile(fileName .. ".txt", dataString)
                end)
            end
            
            -- Try to save the entire terrain
            local success, result = saveObjectAsRBXM(terrain, folderName .. "/full_terrain")
            
            return folderName, #regions
        end)
        
        if success then
            Rayfield:Notify({
                Title = "Terrain Extracted",
                Content = "Saved terrain data to " .. tostring(result),
                Duration = 5,
                Image = nil,
            })
        else
            -- Fallback method if the primary method fails
            pcall(function()
                local folderName = "TerrainData_" .. game.PlaceId .. "_" .. os.time()
                makefolder(folderName)
                
                -- Try to save terrain directly
                local success, result = saveObjectAsRBXM(workspace:FindFirstChildOfClass("Terrain"), folderName .. "/terrain")
                
                if success then
                    Rayfield:Notify({
                        Title = "Terrain Saved",
                        Content = "Saved terrain to " .. result,
                        Duration = 5,
                        Image = nil,
                    })
                else
                    Rayfield:Notify({
                        Title = "Terrain Export Failed",
                        Content = "Could not save terrain data. Try saving entire workspace instead.",
                        Duration = 5,
                        Image = nil,
                    })
                end
            end)
        end
    end,
})

-- Add extra tools for map exploration
local ExtraTools = WorkspaceTab:CreateSection("Map Explorer Tools")

-- Tool to visualize map boundaries
WorkspaceTab:CreateButton({
    Name = "Show Map Boundaries",
    Callback = function()
        -- Remove old boundary visualization
        for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
            if v.Name == "MapBoundaryVisualization" then
                v:Destroy()
            end
        end
        
        -- Create container
        local visualization = Instance.new("Folder")
        visualization.Name = "MapBoundaryVisualization"
        visualization.Parent = game:GetService("CoreGui")
        
        -- Analyze map to find boundaries
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        
        -- Find all BaseParts
        local parts = {}
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(game:GetService("Players").LocalPlayer.Character) then
                table.insert(parts, v)
            end
        end
        
        -- Sample a subset of parts to avoid performance issues
        local sampleSize = math.min(500, #parts)
        local sampled = {}
        
        -- Random sampling or take first N if small enough
        if #parts <= sampleSize then
            sampled = parts
        else
            -- Take distributed samples
            local step = #parts / sampleSize
            for i = 1, sampleSize do
                local index = math.floor(i * step)
                table.insert(sampled, parts[index])
            end
        end
        
        -- Find boundaries
        for _, part in ipairs(sampled) do
            local cf = part.CFrame
            local size = part.Size
            
            -- Calculate corners
            local corners = {
                cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
                cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
                cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
                cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                cf * CFrame.new(size.X/2, size.Y/2, size.Z/2)
            }
            
            for _, corner in ipairs(corners) do
                local pos = corner.Position
                minX = math.min(minX, pos.X)
                minY = math.min(minY, pos.Y)
                minZ = math.min(minZ, pos.Z)
                maxX = math.max(maxX, pos.X)
                maxY = math.max(maxY, pos.Y)
                maxZ = math.max(maxZ, pos.Z)
            end
        end
        
        -- Add some padding
        local padding = 10
        minX = minX - padding
        minY = minY - padding
        minZ = minZ - padding
        maxX = maxX + padding
        maxY = maxY + padding
        maxZ = maxZ + padding
        
        -- Create boundary box
        local function createBoundaryLine(from, to, color)
            local line = Instance.new("Part")
            line.Anchored = true
            line.CanCollide = false
            line.Material = Enum.Material.Neon
            line.Color = color or Color3.fromRGB(0, 255, 0)
            line.Transparency = 0.7
            line.Size = Vector3.new(0.5, 0.5, (to - from).Magnitude)
            line.CFrame = CFrame.new(from:Lerp(to, 0.5), to)
            line.Parent = visualization
        end
        
        -- Create corners
        local corners = {
            Vector3.new(minX, minY, minZ), -- 1
            Vector3.new(minX, minY, maxZ), -- 2
            Vector3.new(minX, maxY, minZ), -- 3
            Vector3.new(minX, maxY, maxZ), -- 4
            Vector3.new(maxX, minY, minZ), -- 5
            Vector3.new(maxX, minY, maxZ), -- 6
            Vector3.new(maxX, maxY, minZ), -- 7
            Vector3.new(maxX, maxY, maxZ)  -- 8
        }
        
        -- Bottom square
        createBoundaryLine(corners[1], corners[2], Color3.fromRGB(255, 0, 0))
        createBoundaryLine(corners[1], corners[5], Color3.fromRGB(255, 0, 0))
        createBoundaryLine(corners[2], corners[6], Color3.fromRGB(255, 0, 0))
        createBoundaryLine(corners[5], corners[6], Color3.fromRGB(255, 0, 0))
        
        -- Top square
        createBoundaryLine(corners[3], corners[4], Color3.fromRGB(0, 255, 0))
        createBoundaryLine(corners[3], corners[7], Color3.fromRGB(0, 255, 0))
        createBoundaryLine(corners[4], corners[8], Color3.fromRGB(0, 255, 0))
        createBoundaryLine(corners[7], corners[8], Color3.fromRGB(0, 255, 0))
        
        -- Vertical lines
        createBoundaryLine(corners[1], corners[3], Color3.fromRGB(0, 0, 255))
        createBoundaryLine(corners[2], corners[4], Color3.fromRGB(0, 0, 255))
        createBoundaryLine(corners[5], corners[7], Color3.fromRGB(0, 0, 255))
        createBoundaryLine(corners[6], corners[8], Color3.fromRGB(0, 0, 255))
        
        -- Calculate map size
        local width = maxX - minX
        local height = maxY - minY
        local depth = maxZ - minZ
        local volume = width * height * depth
        
        Rayfield:Notify({
            Title = "Map Boundaries",
            Content = string.format("Width: %.1f, Height: %.1f, Depth: %.1f\nTotal Area: %.1f studs²", 
                width, height, depth, volume),
            Duration = 10,
            Image = nil,
        })
    end,
})

-- Add tool to count map objects by type
WorkspaceTab:CreateButton({
    Name = "Analyze Map Objects",
    Callback = function()
        Rayfield:Notify({
            Title = "Map Analyzer",
            Content = "Scanning and analyzing map objects...",
            Duration = 3,
            Image = nil,
        })
        
        -- Initialize counters
        local stats = {
            BaseParts = 0,
            Models = 0,
            Meshes = 0,
            Scripts = 0,
            Decals = 0,
            Lights = 0,
            Sounds = 0,
            Other = 0,
            Total = 0
        }
        
        -- Scan objects
        for _, v in pairs(workspace:GetDescendants()) do
            stats.Total = stats.Total + 1
            
            if v:IsA("BasePart") then
                stats.BaseParts = stats.BaseParts + 1
            elseif v:IsA("Model") then
                stats.Models = stats.Models + 1
            elseif v:IsA("MeshPart") or v:IsA("SpecialMesh") then
                stats.Meshes = stats.Meshes + 1
            elseif v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
                stats.Scripts = stats.Scripts + 1
            elseif v:IsA("Decal") or v:IsA("Texture") then
                stats.Decals = stats.Decals + 1
            elseif v:IsA("Light") or v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
                stats.Lights = stats.Lights + 1
            elseif v:IsA("Sound") then
                stats.Sounds = stats.Sounds + 1
            else
                stats.Other = stats.Other + 1
            end
        end
        
        -- Format results
        local results = string.format([[
Map Analysis Results:
--------------------
Total Objects: %d
BaseParts: %d (%.1f%%)
Models: %d (%.1f%%)
Meshes: %d (%.1f%%)
Decals/Textures: %d (%.1f%%)
Scripts: %d (%.1f%%)
Lights: %d (%.1f%%)
Sounds: %d (%.1f%%)
Other: %d (%.1f%%)
]], 
            stats.Total,
            stats.BaseParts, (stats.BaseParts / stats.Total) * 100,
            stats.Models, (stats.Models / stats.Total) * 100,
            stats.Meshes, (stats.Meshes / stats.Total) * 100,
            stats.Decals, (stats.Decals / stats.Total) * 100,
            stats.Scripts, (stats.Scripts / stats.Total) * 100,
            stats.Lights, (stats.Lights / stats.Total) * 100,
            stats.Sounds, (stats.Sounds / stats.Total) * 100,
            stats.Other, (stats.Other / stats.Total) * 100
        )
        
        -- Save analysis
        pcall(function()
            writefile("MapAnalysis_" .. game.PlaceId .. ".txt", results)
        end)
        
        -- Display results
        Rayfield:Notify({
            Title = "Map Analysis Complete",
            Content = "Results saved to MapAnalysis_" .. game.PlaceId .. ".txt",
            Duration = 5,
            Image = nil,
        })
    end,
})

-- Add button to teleport to map center
WorkspaceTab:CreateButton({
    Name = "Teleport to Map Center",
    Callback = function()
        -- Find map center
        local parts = {}
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(game:GetService("Players").LocalPlayer.Character) then
                table.insert(parts, v)
            end
        end
        
        -- Calculate center point
        local totalPos = Vector3.new(0, 0, 0)
        local count = 0
        
        for _, part in ipairs(parts) do
            totalPos = totalPos + part.Position
            count = count + 1
            
            if count >= 500 then break end -- Limit to 500 parts for performance
        end
        
        if count > 0 then
            local centerPos = totalPos / count
            
            -- Adjust Y position to be slightly above ground
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = {game:GetService("Players").LocalPlayer.Character}
            
            local raycastResult = workspace:Raycast(centerPos + Vector3.new(0, 1000, 0), Vector3.new(0, -2000, 0), raycastParams)
            if raycastResult then
                centerPos = raycastResult.Position + Vector3.new(0, 5, 0)
            end
            
            -- Teleport character
            local character = game:GetService("Players").LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = CFrame.new(centerPos)
                
                Rayfield:Notify({
                    Title = "Teleported",
                    Content = "You've been teleported to the center of the map",
                    Duration = 3,
                    Image = nil,
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Could not teleport - character not found",
                    Duration = 3,
                    Image = nil,
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Could not determine map center",
                Duration = 3,
                Image = nil,
            })
        end
    end,
})

return {
    getAllObjects = getAllObjects,
    saveObjectAsRBXM = saveObjectAsRBXM,
    findSelectableObjects = findSelectableObjects,
    setupClickToSelect = setupClickToSelect
}
