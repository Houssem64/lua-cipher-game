local Desktop = {}

function Desktop:new()
    local obj = {
        backgroundColor = {0.2, 0.2, 0.2}, -- Dark gray background
        wallpaper = nil -- We can add wallpaper support later
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Desktop:draw()
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

return Desktop