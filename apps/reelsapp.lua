local ReelsApp = {
    config = {
        slide_speed = 1000,  -- Speed of the sliding animation
        panel_color = {0.1333, 0.1333, 0.1333, 1},  -- Dark background for the panel
    }
}
ReelsApp.__index = ReelsApp

function ReelsApp:new(videos)
    local obj = setmetatable({}, ReelsApp)

    -- Merge provided config with defaults
    obj.config = setmetatable({}, {__index = ReelsApp.config})

    -- Initialize state using virtual resolution
    obj.gameWidth = 1920
    obj.gameHeight = 1080

    -- Video list
    obj.videos = videos
    obj.currentIndex = 1
    obj.offsetY = 0  -- Vertical offset for sliding
    obj.isDragging = false
    obj.dragStartY = 0
    obj.slideSpeed = 0

    -- Load the first video
    obj.currentVideo = love.graphics.newVideo(obj.videos[obj.currentIndex])
    obj.currentVideo:play()

    return obj
end

function ReelsApp:update(dt)
    -- Update sliding animation
    if not self.isDragging then
        self.offsetY = self.offsetY + self.slideSpeed * dt
        self.slideSpeed = self.slideSpeed * 0.9  -- Slow down over time

        -- Snap to the nearest video
        if math.abs(self.slideSpeed) < 50 then
            local targetIndex = self.currentIndex
            if self.offsetY > self.gameHeight / 2 then
                targetIndex = targetIndex - 1
            elseif self.offsetY < -self.gameHeight / 2 then
                targetIndex = targetIndex + 1
            end

            if targetIndex ~= self.currentIndex then
                self:switchToVideo(targetIndex)
            else
                self.offsetY = 0
                self.slideSpeed = 0
            end
        end
    end
end

function ReelsApp:draw()
    -- Draw the current video
    love.graphics.draw(self.currentVideo, 0, self.offsetY)

    -- Draw the next or previous video if sliding
    if self.offsetY > 0 then
        -- Draw the previous video above
        local prevVideo = love.graphics.newVideo(self.videos[self.currentIndex - 1])
        love.graphics.draw(prevVideo, 0, self.offsetY - self.gameHeight)
    elseif self.offsetY < 0 then
        -- Draw the next video below
        local nextVideo = love.graphics.newVideo(self.videos[self.currentIndex + 1])
        love.graphics.draw(nextVideo, 0, self.offsetY + self.gameHeight)
    end
end

function ReelsApp:switchToVideo(index)
    -- Clamp the index to valid range
    index = math.max(1, math.min(index, #self.videos))

    if index ~= self.currentIndex then
        self.currentIndex = index
        self.currentVideo = love.graphics.newVideo(self.videos[self.currentIndex])
        self.currentVideo:play()
        self.offsetY = 0
        self.slideSpeed = 0
    end
end

function ReelsApp:mousepressed(x, y, button)
    if button == 1 then
        self.isDragging = true
        self.dragStartY = y
    end
end

function ReelsApp:mousereleased(x, y, button)
    if button == 1 and self.isDragging then
        self.isDragging = false
        local dragDistance = y - self.dragStartY
        self.slideSpeed = dragDistance * 10  -- Adjust sensitivity
    end
end

function ReelsApp:mousemoved(x, y, dx, dy)
    if self.isDragging then
        self.offsetY = self.offsetY + dy
    end
end