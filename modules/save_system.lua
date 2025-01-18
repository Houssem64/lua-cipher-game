local SaveSystem = {}
local json = require("libraries/json")

function SaveSystem:save(data, filename)
    local success, message = pcall(function()
        local saveData = json.encode(data)
        love.filesystem.write(filename .. ".sav", saveData)
    end)
    
    if not success then
        print("Error saving game: " .. message)
        return false
    end
    
    return true

end

function SaveSystem:load(filename)
    if not love.filesystem.getInfo(filename .. ".sav") then
        return nil
    end
    
    local success, data = pcall(function()
        local saveData = love.filesystem.read(filename .. ".sav")
        return json.decode(saveData)
    end)
    
    if not success then
        print("Error loading game: " .. data)
        return nil
    end
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