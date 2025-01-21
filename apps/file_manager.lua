local FileManager = {}

function FileManager:new()
    local obj = {
        currentPath = "/home/user",
        files = {
            {name = "Documents", type = "folder"},
            {name = "Downloads", type = "folder"},
            {name = "readme.txt", type = "file"},
            {name = "image.png", type = "file"}
        },
        selectedFile = nil
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function FileManager:draw(x, y, width, height)
    -- Draw background
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw current path
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("Path: " .. self.currentPath, x + 10, y + 10)
    
    -- Draw files and folders
    local yOffset = 40
    for _, file in ipairs(self.files) do
        if file.type == "folder" then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end
        
        -- Highlight selected file
        if self.selectedFile == file.name then
            love.graphics.setColor(0.8, 0.4, 0.4)
        end
        
        love.graphics.print(file.name, x + 10, y + yOffset)
        yOffset = yOffset + 20
    end
end

function FileManager:mousepressed(x, y, button)
    if button == 1 then -- Left click
        local yOffset = 40
        for _, file in ipairs(self.files) do
            if y >= yOffset and y <= yOffset + 20 then
                self.selectedFile = file.name
                if file.type == "folder" then
                    self:changeDirectory(file.name)
                end
                break
            end
            yOffset = yOffset + 20
        end
    end
end

function FileManager:changeDirectory(dir)
    if dir == ".." then
        -- Navigate up one directory
        local lastSlash = self.currentPath:find("/[^/]*$")
        if lastSlash then
            self.currentPath = self.currentPath:sub(1, lastSlash - 1)
        end
    else
        -- Navigate into the selected directory
        self.currentPath = self.currentPath .. "/" .. dir
    end
    -- Update files list (this is a placeholder, you would need to read the actual directory)
    self.files = {
        {name = "..", type = "folder"},
        {name = "Documents", type = "folder"},
        {name = "Downloads", type = "folder"},
        {name = "readme.txt", type = "file"},
        {name = "image.png", type = "file"}
    }
end

return FileManager