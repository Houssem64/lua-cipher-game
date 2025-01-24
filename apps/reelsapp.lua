local ReelsApp = {
    config = {
        button_radius = 20,
        panel_width = 500,
        slide_speed = 1000,
        button_color = {0.9, 0.2, 0.4},  -- TikTok-like red
        panel_color = {0.1, 0.1, 0.1, 0.95},
        text_color = {1, 1, 1}
    }
}
ReelsApp.__index = ReelsApp

function ReelsApp:new()
    local obj = setmetatable({}, ReelsApp)
    obj.config = setmetatable({}, {__index = ReelsApp.config})
    
    obj.gameWidth = 1920
    obj.gameHeight = 1080
    
    obj.button = {
        x = obj.gameWidth - 60,
        y = 240,
        radius = obj.config.button_radius
    }
    
    obj.panel = {
        x = obj.gameWidth,
        target_x = obj.gameWidth - obj.config.panel_width,
        y = 0,
        width = obj.config.panel_width,
        height = obj.gameHeight,
        visible = false
    }
    
    -- Enhanced reels data
    obj.reels = {
        {
            title = "cooluser123",
            video = "test.ogv",
            likes = 10200,
            comments = 1200,
            shares = 450,
            description = "Check out this awesome video! #trending #fyp",
            isLiked = false,
            music = "Original Sound - cooluser123"
        },
        {
            title = "gamer_pro",
            video = "test2.ogv",
            likes = 5000,
            comments = 800,
            shares = 200,
            description = "Gaming moment 🎮 #gaming #fail",
            isLiked = false,
            music = "Funny Sound Effect"
        }
    }
    
    obj.currentReelIndex = 1
    obj.isPlaying = false
    obj.currentVideo = nil
    obj.videoLoaded = false
    
    -- Initialize first video
    obj:loadReel(obj.currentReelIndex)
    
    return obj
end

function ReelsApp:loadReel(index)
    if self.currentVideo then
        self.currentVideo:release()
    end
    
    local reel = self.reels[index]
    if love.filesystem.getInfo(reel.video) then
        self.currentVideo = love.graphics.newVideo(reel.video, {
            audio = true,  -- Enable audio
            sync = true    -- Sync audio with video
        })
        self.videoLoaded = true
        if self.panel.visible then  -- Auto-play if panel is visible
            self.currentVideo:play()
            self.isPlaying = true
        end
    else
        print("Error: Video file not found -", reel.video)
        self.videoLoaded = false
    end
end

function ReelsApp:nextReel()
    self.currentReelIndex = (self.currentReelIndex % #self.reels) + 1
    self:loadReel(self.currentReelIndex)
end

function ReelsApp:previousReel()
    self.currentReelIndex = ((self.currentReelIndex - 2) % #self.reels) + 1
    self:loadReel(self.currentReelIndex)
end

function ReelsApp:toggleLike()
    local reel = self.reels[self.currentReelIndex]
    reel.isLiked = not reel.isLiked
    if reel.isLiked then
        reel.likes = reel.likes + 1
    else
        reel.likes = reel.likes - 1
    end
end

function ReelsApp:formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num/1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num/1000)
    end
    return tostring(num)
end

function ReelsApp:update(dt)
    -- Update panel sliding
    if self.panel.visible then
        self.panel.x = math.max(self.panel.target_x, self.panel.x - self.config.slide_speed * dt)
        -- Auto-play video when panel is fully visible
        if self.panel.x == self.panel.target_x and self.currentVideo and not self.currentVideo:isPlaying() then
            self.currentVideo:play()
            self.isPlaying = true
        end
    else
        self.panel.x = math.min(self.gameWidth, self.panel.x + self.config.slide_speed * dt)
        -- Pause video when panel starts closing
        if self.currentVideo and self.currentVideo:isPlaying() then
            self.currentVideo:pause()
            self.isPlaying = false
        end
    end
    
    -- Loop video when it ends
    if self.isPlaying and self.currentVideo and not self.currentVideo:isPlaying() then
        self.currentVideo:rewind()
        self.currentVideo:play()
    end
end

function ReelsApp:draw()
    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont("joty.otf", 18)
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)

    -- Draw toggle button
    love.graphics.setColor(unpack(self.config.button_color))
    local buttonCenterX = self.button.x + self.button.radius
    local buttonCenterY = self.button.y + self.button.radius
    
    -- Draw the button
    love.graphics.circle("fill", buttonCenterX, buttonCenterY, self.button.radius)
    
    -- Debug: Draw hit area
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.circle("line", buttonCenterX, buttonCenterY, self.button.radius)

    -- Draw reel icon
    love.graphics.setColor(1, 1, 1)
    local iconX = self.button.x + self.button.radius - 10
    local iconY = self.button.y + self.button.radius - 10
    
    -- Draw film reel circles
    love.graphics.circle("line", iconX + 10, iconY + 10, 8)
    love.graphics.circle("fill", iconX + 10, iconY + 10, 3)
    
    -- Draw sprockets
    for i = 1, 6 do
        local angle = (i - 1) * math.pi / 3
        local sprocketX = iconX + 10 + math.cos(angle) * 6
        local sprocketY = iconY + 10 + math.sin(angle) * 6
        love.graphics.circle("fill", sprocketX, sprocketY, 1.5)
    end

    if self.panel.x < self.gameWidth then
        local reel = self.reels[self.currentReelIndex]
        
        -- Draw panel background
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle("fill", 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height)

        if self.currentVideo then
            local videoWidth = self.panel.width
            local videoHeight = self.panel.height * 0.8
            local videoX = self.panel.x
            local videoY = self.panel.y + (self.panel.height - videoHeight) / 2

            -- Draw video
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(self.currentVideo, 
                videoX, 
                videoY, 
                0, 
                videoWidth / self.currentVideo:getWidth(), 
                videoHeight / self.currentVideo:getHeight())

            -- Draw interaction buttons
            local actionBarX = self.panel.x + self.panel.width - 60
            local actionBarY = videoY + videoHeight / 2
            local iconSpacing = 60

            -- Like button
            love.graphics.setColor(reel.isLiked and {1, 0, 0} or {1, 1, 1})
            love.graphics.circle("line", actionBarX + 20, actionBarY, 20)
            love.graphics.print("♥", actionBarX + 10, actionBarY - 10)
            love.graphics.print(self:formatNumber(reel.likes), 
                actionBarX + 5, actionBarY + 25)

            -- Comment button
            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("line", actionBarX + 20, actionBarY + iconSpacing, 20)
            love.graphics.print("💬", actionBarX + 10, actionBarY + iconSpacing - 10)
            love.graphics.print(self:formatNumber(reel.comments), 
                actionBarX + 5, actionBarY + iconSpacing + 25)

            -- Share button
            love.graphics.circle("line", actionBarX + 20, actionBarY + iconSpacing * 2, 20)
            love.graphics.print("↗", actionBarX + 10, actionBarY + iconSpacing * 2 - 10)
            love.graphics.print(self:formatNumber(reel.shares), 
                actionBarX, actionBarY + iconSpacing * 2 + 25)

            -- Video info overlay
            love.graphics.setColor(0, 0, 0, 0.5)
            local infoY = videoY + videoHeight - 120
            love.graphics.rectangle("fill", videoX, infoY, videoWidth - 70, 120)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("@" .. reel.title, videoX + 20, infoY + 20)
            love.graphics.print(reel.description, videoX + 20, infoY + 50)
            love.graphics.print("🎵 " .. reel.music, videoX + 20, infoY + 80)
        end
    end

    love.graphics.setFont(default_font)
end

function ReelsApp:mousepressed(x, y, button)
    local dx = x - (self.button.x + self.button.radius)
    local dy = y - (self.button.y + self.button.radius)
    if dx * dx + dy * dy <= self.button.radius * self.button.radius then
        self.panel.visible = not self.panel.visible
        -- Start playing when panel opens
        if self.panel.visible then
            if not self.currentVideo then
                self:loadReel(self.currentReelIndex)
            end
            if self.currentVideo then
                self.currentVideo:play()
                self.isPlaying = true
            end
        else
            -- Pause when panel closes
            if self.currentVideo then
                self.currentVideo:pause()
                self.isPlaying = false
            end
        end
        return true
    end
    
    if self.panel.visible then
        -- Store swipe start position
        self.swipeStart = y
        
        -- Video play/pause on click
        if x >= self.panel.x and x <= self.panel.x + self.panel.width then
            local videoHeight = self.panel.height * 0.8
            local videoY = self.panel.y + (self.panel.height - videoHeight) / 2
            if y >= videoY and y <= videoY + videoHeight then
                if self.currentVideo then
                    if self.currentVideo:isPlaying() then
                        self.currentVideo:pause()
                    else
                        self.currentVideo:play()
                    end
                    self.isPlaying = not self.isPlaying
                    return true
                end
            end
        end
        
        -- Like button detection (keep existing code)
        local videoHeight = self.panel.height * 0.8
        local videoY = self.panel.y + (self.panel.height - videoHeight) / 2
        local actionBarX = self.panel.x + self.panel.width - 60
        local actionBarY = videoY + videoHeight / 2

        local likeDx = x - (actionBarX + 20)
        local likeDy = y - actionBarY
        if likeDx * likeDx + likeDy * likeDy <= 400 then
            self:toggleLike()
            return true
        end
    end
    
    return false
end

function ReelsApp:mousereleased(x, y, button)
    if self.swipeStart and self.panel.visible then
        local swipeDist = y - self.swipeStart
        if math.abs(swipeDist) > self.swipeThreshold then
            if swipeDist > 0 then
                self:previousReel()
            else
                self:nextReel()
            end
        end
    end
    self.swipeStart = nil
end

function ReelsApp:keypressed(key)
    if self.panel.visible then
        if key == "up" then
            self:previousReel()
        elseif key == "down" then
            self:nextReel()
        elseif key == "space" then
            if self.currentVideo then
                if self.currentVideo:isPlaying() then
                    self.currentVideo:pause()
                else
                    self.currentVideo:play()
                end
                self.isPlaying = not self.isPlaying
            end
        end
    end
end

return ReelsApp