local EmailClient = {}

function EmailClient:new()
    local obj = {
        emails = {
            {subject = "Welcome", from = "system@linux.com", read = false},
            {subject = "Hello", from = "friend@email.com", read = true},
            {subject = "Meeting", from = "work@company.com", read = false}
        }
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function EmailClient:draw(x, y, width, height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    
    local yOffset = 10
    for _, email in ipairs(self.emails) do
        if not email.read then
            love.graphics.setColor(0.2, 0.4, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end
        love.graphics.print(email.subject .. " - " .. email.from, x + 10, y + yOffset)
        yOffset = yOffset + 25
    end
end

return EmailClient 