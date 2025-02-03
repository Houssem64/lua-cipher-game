local SaveSystem = {}
local json = require("libraries/json")

function SaveSystem:save(data, filename)
    local success, message = pcall(function()
        local saveData = json.encode(data)
        print("Saving to file: " .. filename .. ".sav")
        print("Save data: " .. saveData)
        love.filesystem.write(filename .. ".sav", saveData)
    end)
    
    if not success then
        print("Error saving game: " .. message)
        return false
    end
    
    print("Successfully saved to: " .. filename .. ".sav")
    return true
end

function SaveSystem:load(filename)
    local filePath = filename .. ".sav"
    if not love.filesystem.getInfo(filePath) then
        print("No save file found: " .. filePath)
        return nil
    end
    
    local success, data = pcall(function()
        local saveData = love.filesystem.read(filePath)
        print("Loading from file: " .. filePath)
        print("Loaded data: " .. saveData)
        return json.decode(saveData)
    end)
    
    if not success then
        print("Error loading game: " .. tostring(data))
        return nil
    end
    
    print("Successfully loaded from: " .. filePath)
    return data
end

function SaveSystem:getTextFilesList()
    local files = {}
    local savedData = self:load("text_files_index") or {}
    for filename, _ in pairs(savedData) do
        table.insert(files, filename)
    end
    return files
end

return SaveSystem