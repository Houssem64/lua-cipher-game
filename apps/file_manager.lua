local FileManager = {}

function FileManager:new()
    local obj = {
        currentPath = "/home/user",
        files = {
            {name = "Documents", type = "folder"},
            {name = "Downloads", type = "folder"},
            {name = "readme.txt", type = "file"},
            {name = "image.png", type = "file"}
        }
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function FileManager:draw(x, y, width, height)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print(self.currentPath, x + 10, y + 10)
    
    local yOffset = 40
    for _, file in ipairs(self.files) do
        if file.type == "folder" then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end
        love.graphics.print(file.name, x + 10, y + yOffset)
        yOffset = yOffset + 20
    end
end

return FileManager 