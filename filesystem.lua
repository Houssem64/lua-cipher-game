local FileSystem = {
    current_path = "/home/love",
    root = {
        ["home"] = {
            ["love"] = {
                ["Documents"] = {
                    ["_type"] = "directory"
                },
                ["Downloads"] = {
                    ["_type"] = "directory"
                },
                ["Desktop"] = {
                    ["_type"] = "directory"
                },
                ["Pictures"] = {
                    ["_type"] = "directory"
                },
                ["_type"] = "directory"
            },
            ["_type"] = "directory"
        },
        ["_type"] = "directory"
    }
}

local SaveSystem = require("modules/save_system")

-- Initialize the filesystem
function FileSystem:init()
    -- Create initial structure if it doesn't exist
    self:createDirectoryStructure("home/love")
    self:createDirectoryStructure("home/love/Documents")
    self:createDirectoryStructure("home/love/Downloads")
    self:createDirectoryStructure("home/love/Desktop")
    self:createDirectoryStructure("home/love/Pictures")
    
    -- Load saved state if available
    local saved_data = SaveSystem:load("filesystem_data")
    if saved_data then
        self.root = saved_data
    else
        -- Save initial state if no saved data exists
        SaveSystem:save(self.root, "filesystem_data")
    end
    
    -- Ensure we're in a valid directory
    if not self:getDirectory(self.current_path) then
        self.current_path = "/home/love"
    end
    
    return self
end

function FileSystem:normalizePath(path)
    -- Remove multiple slashes and normalize
    path = path:gsub("//+", "/"):gsub("^/+", "/"):gsub("/+$", "")
    if path == "" then
        return "/"
    end
    return path
end

function FileSystem:getDirectory(path)
    -- Handle empty or root path
    if not path or path == "/" then
        return self.root
    end
    
    -- Normalize path
    path = self:normalizePath(path)
    
    -- Split path into components
    local components = {}
    for dir in path:gsub("^/", ""):gmatch("[^/]+") do
        if dir == "." then
            -- Skip current directory marker
        elseif dir == ".." then
            -- Remove last component for parent directory
            if #components > 0 then
                table.remove(components)
            end
        else
            table.insert(components, dir)
        end
    end
    
    -- Traverse the path
    local current = self.root
    for _, dir in ipairs(components) do
        if current[dir] and current[dir]["_type"] == "directory" then
            current = current[dir]
        else
            return nil
        end
    end
    return current
end


function FileSystem:listFiles(path)
    -- If no path provided, use current_path
    local target_path = path or self.current_path
    local dir = self:getDirectory(target_path)
    
    if dir then
        local files = {}
        for name, content in pairs(dir) do
            -- Skip _type field and only show actual files/directories
            if name ~= "_type" then
                -- Add trailing slash for directories
                if type(content) == "table" and content["_type"] == "directory" then
                    table.insert(files, name .. "/")
                else
                    table.insert(files, name)
                end
            end
        end
        table.sort(files)
        return files
    end
    return {}
end

function FileSystem:changePath(newPath)
    -- Handle special cases
    if newPath == "~" or newPath == "" then
        self.current_path = "/home/love"
        return self.current_path
    end

    -- Handle absolute paths
    local targetPath
    if newPath:sub(1, 1) == "/" then
        targetPath = self:normalizePath(newPath)
    else
        -- Handle relative paths
        targetPath = self:normalizePath(self.current_path .. "/" .. newPath)
    end

    -- Check if target directory exists
    local dir = self:getDirectory(targetPath)
    if dir and dir["_type"] == "directory" then
        self.current_path = targetPath
        return targetPath
    end
    
    return nil
end


function FileSystem:createDirectoryStructure(path)
    local current = self.root
    for dir in path:gmatch("[^/]+") do
        if not current[dir] then
            current[dir] = {
                ["_type"] = "directory"
            }
        end
        current = current[dir]
    end
    return current
end

function FileSystem:createDirectory(name)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and parent["_type"] == "directory" and not parent[name] then
        parent[name] = {
            ["_type"] = "directory"
        }
        SaveSystem:save(self.root, "filesystem_data")
        return true
    end
    return false
end

function FileSystem:createFile(name)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and parent["_type"] == "directory" and not parent[name] then
        parent[name] = {
            ["_type"] = "file",
            ["content"] = ""
        }
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
    if parent and parent[name] and parent[name]["_type"] == "file" then
        return parent[name]["content"]
    end
    return nil
end

function FileSystem:writeFile(name, content)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and parent["_type"] == "directory" then
        parent[name] = {
            ["_type"] = "file",
            ["content"] = content
        }
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

-- Add this function to clear filesystem data
function FileSystem:clearState()
    -- Reset to default state
    self.root = {
        ["home"] = {
            ["love"] = {
                ["Documents"] = {
                    ["_type"] = "directory"
                },
                ["Downloads"] = {
                    ["_type"] = "directory"
                },
                ["Desktop"] = {
                    ["_type"] = "directory"
                },
                ["Pictures"] = {
                    ["_type"] = "directory"
                },
                ["_type"] = "directory"
            },
            ["_type"] = "directory"
        },
        ["_type"] = "directory"
    }
    self.current_path = "/home/love"
    
    -- Remove saved state file
    if love.filesystem.getInfo("filesystem_data.sav") then
        love.filesystem.remove("filesystem_data.sav")
    end
    
    -- Save the new clean state
    SaveSystem:save(self.root, "filesystem_data")
    
    return true
end

-- Initialize filesystem before returning
FileSystem:init()

return FileSystem