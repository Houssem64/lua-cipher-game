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
        return true
    end
    return false
end

function FileSystem:createFile(name)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and not parent[name] then
        parent[name] = ""
        return true
    end
    return false
end

function FileSystem:removeFile(name)
    local parentPath = self.current_path
    local parent = self:getDirectory(parentPath)
    if parent and parent[name] then
        parent[name] = nil
        return true
    end
    return false
end

return FileSystem