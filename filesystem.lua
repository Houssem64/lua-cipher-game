local FileSystem = {
    current_path = "/home/kali",
    root = {
        home = {
            kali = {
                Documents = {},
                Downloads = {},
                Desktop = {},
                Pictures = {}
            }
        }
    }
}

local SaveSystem = require("modules/save_system")  -- Adjust path as needed

function FileSystem:getDirectory(path)
    local current = self.root
    for dir in path:gmatch("[^/]+") do
        if current[dir] then
            current = current[dir]
        else
            return nil
        end
    end
    return current
end

function FileSystem:listFiles(path)
    local dir = self:getDirectory(path)
    if dir then
        local files = {}
        for name, _ in pairs(dir) do
            table.insert(files, name)
        end
        return files
    end
    return {}
end

function FileSystem:changePath(newPath)
    if newPath:sub(1, 1) == "/" then
        -- Absolute path
        if self:getDirectory(newPath) then
           
            return newPath
        end
    else
        -- Relative path
        local fullPath = self.current_path .. "/" .. newPath
        if self:getDirectory(fullPath) then
            return fullPath
        end
    end
    return nil
end

function FileSystem:createDirectory(name)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and not parent[name] then
        parent[name] = {}
        -- Save the updated filesystem state
        SaveSystem:save(self.root, "filesystem_data")
        return true
    end
    return false
end

function FileSystem:createFile(name)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and not parent[name] then
        parent[name] = ""
        -- Save the updated filesystem state
        SaveSystem:save(self.root, "filesystem_data")
        return true
    end
    return false
end

function FileSystem:removeFile(name)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and parent[name] then
        parent[name] = nil
        -- Save the updated filesystem state
        SaveSystem:save(self.root, "filesystem_data")
        return true
    end
    return false
end

-- New method to load the filesystem state
function FileSystem:loadState()
    local data = SaveSystem:load("filesystem_data")
    if data then
        self.root = data
    end
end

function FileSystem:renameFile(oldName, newName)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and parent[oldName] then
        -- Store the content/structure
        local content = parent[oldName]
        -- Remove old entry
        parent[oldName] = nil
        -- Create new entry with same content
        parent[newName] = content
        -- Save the updated filesystem state
        SaveSystem:save(self.root, "filesystem_data")
        return true
    end
    return false
end

function FileSystem:getParentPath(path)
    return path:match("(.+)/[^/]+$") or "/"
end

function FileSystem:copyFile(srcPath, destPath)
    local srcDir = self:getDirectory(self:getParentPath(srcPath))
    local destDir = self:getDirectory(self:getParentPath(destPath))
    local srcName = srcPath:match("[^/]+$")
    local destName = destPath:match("[^/]+$")
    
    if srcDir and destDir and srcDir[srcName] then
        -- Copy the content/structure
        destDir[destName] = srcDir[srcName]
        -- Save the updated filesystem state
        SaveSystem:save(self.root, "filesystem_data")
        return true
    end
    return false
end

function FileSystem:moveFile(srcPath, destPath)
    if self:copyFile(srcPath, destPath) then
        -- Remove the source file after successful copy
        local srcDir = self:getDirectory(self:getParentPath(srcPath))
        local srcName = srcPath:match("[^/]+$")
        if srcDir and srcDir[srcName] then
            srcDir[srcName] = nil
            -- Save the updated filesystem state
            SaveSystem:save(self.root, "filesystem_data")
            return true
        end
    end
    return false
end

function FileSystem:readFile(name)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and parent[name] then
        return parent[name]
    end
    return nil
end

function FileSystem:writeFile(name, content)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent then
        parent[name] = content
        SaveSystem:save(self.root, "filesystem_data")
        return true
    end
    return false
end

function FileSystem:findFiles(pattern)
    local function searchDirectory(dir, path, results)
        for name, content in pairs(dir) do
            local fullPath = path .. "/" .. name
            if type(content) == "table" then
                searchDirectory(content, fullPath, results)
            elseif type(content) == "string" then
                if name:match(pattern) then
                    table.insert(results, fullPath)
                end
            end
        end
    end
    
    local results = {}
    searchDirectory(self.root, "", results)
    return results
end

function FileSystem:setFilePermissions(name, permissions)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and parent[name] then
        -- Store permissions in a metadata table if it doesn't exist
        if not parent[name .. "_meta"] then
            parent[name .. "_meta"] = {}
        end
        parent[name .. "_meta"].permissions = permissions
        SaveSystem:save(self.root, "filesystem_data")
        return true
    end
    return false
end

function FileSystem:getFilePermissions(name)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and parent[name] and parent[name .. "_meta"] then
        return parent[name .. "_meta"].permissions
    end
    return "644" -- Default permissions
end

return FileSystem