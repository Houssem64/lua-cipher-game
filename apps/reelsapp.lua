local ReelsApp = {
    config = {
        button_radius = 15,
        panel_width = 500,
        slide_speed = 1000,
        button_color = {0.9, 0.2, 0.4},
        panel_color = {0.1, 0.1, 0.1, 0.95},
        text_color = {1, 1, 1},
        accent_color = {1, 0, 0.4},
        icon_scale = 3,
        loading_speed = 5,
        icon_spacing = 70
    }
}
ReelsApp.__index = ReelsApp

-- Helper functions for drawing icons
local function drawHeartIcon(x, y, size, filled)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(size, size)
    
    if filled then
        love.graphics.polygon("fill", 
            0, 4,
            -4, 0,
            -4, -2,
            -2, -4,
            0, -3,
            2, -4,
            4, -2,
            4, 0
        )
    else
        love.graphics.polygon("line", 
            0, 4,
            -4, 0,
            -4, -2,
            -2, -4,
            0, -3,
            2, -4,
            4, -2,
            4, 0
        )
    end
    love.graphics.pop()
end

local function drawCommentIcon(x, y, size)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(size, size)
    
    -- Speech bubble outline
    love.graphics.polygon("line",
        -4, -4,
        4, -4,
        4, 2,
        1, 2,
        0, 4,
        -1, 2,
        -4, 2
    )
    
    -- Lines inside
    love.graphics.line(-2, -2, 2, -2)
    love.graphics.line(-2, 0, 1, 0)
    love.graphics.pop()
end

local function drawShareIcon(x, y, size)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(size, size)
    
    -- Arrow
    love.graphics.line(-2, 0, 2, -4)
    love.graphics.line(2, -4, 2, -2)
    love.graphics.line(2, -4, 0, -2)
    
    -- Share box
    love.graphics.rectangle("line", -3, 0, 6, 4)
    love.graphics.pop()
end

function ReelsApp:new()
    local obj = setmetatable({}, ReelsApp)
    obj.config = setmetatable({}, {__index = ReelsApp.config})
    
    obj.gameWidth = 1920
    obj.gameHeight = 1080
    
    obj.button = {
        x = obj.gameWidth - 200,
        y = 5,
        radius = obj.config.button_radius
    }

    
    obj.panel = {
        x = obj.gameWidth,
        target_x = obj.gameWidth - obj.config.panel_width,
        y = 40,
        width = obj.config.panel_width,
        height = obj.gameHeight,
        visible = false
    }
    
    -- Enhanced reels data
    obj.reels = {
        {
            title = "cooluser123",
            video = "reels/1.ogv",
            likes = 10200,
            comments = 1200,
            shares = 450,
            description = "Check out this awesome video! #trending #fyp",
            isLiked = false,
            music = "Original Sound - cooluser123"
        },
        {
            title = "gamer_pro",
            video = "reels/2.ogv",
            likes = 5000,
            comments = 800,
            shares = 200,
            description = "Gaming moment 🎮 #gaming #fail",
            isLiked = false,
            music = "Funny Sound Effect"
        },
        {
            title = "bendover",
            video = "reels/3.ogv",
            likes = 10200,
            comments = 1200,
            shares = 450,
            description = "Check out this awesome video! #trending #fyp",
            isLiked = false,
            music = "Original Sound - cooluser123"
        }
    }
    
    obj.currentReelIndex = 1
    obj.isPlaying = false
    obj.currentVideo = nil
    obj.videoLoaded = false
    
    -- Add animation states
    obj.loadingRotation = 0
    obj.isLoading = false
    obj.iconScales = {
        like = 1.0,
        comment = 1.0,
        share = 1.0
    }
    
    -- Initialize first video
    obj:loadReel(obj.currentReelIndex)
    
    return obj
end

function ReelsApp:loadReel(index)
    self.isLoading = true
    if self.currentVideo then
        self.currentVideo:release()
    end
    
    local reel = self.reels[index]
    if love.filesystem.getInfo(reel.video) then
        -- Wrap video loading in pcall for safety
        local success, video = pcall(function()
            return love.graphics.newVideo(reel.video, {
                audio = true,
                sync = true
            })
        end)
        
        if success and video then
            self.currentVideo = video
            self.videoLoaded = true
            self.isLoading = false
            if self.panel.visible then
                self.currentVideo:play()
                self.isPlaying = true
            end
        else
            print("Error loading video:", reel.video)
            self.videoLoaded = false
            self.isLoading = false
            self.currentVideo = nil
        end
    else
        print("Error: Video file not found -", reel.video)
        self.videoLoaded = false
        self.isLoading = false
        self.currentVideo = nil
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
    -- Update loading animation
    if self.isLoading then
        self.loadingRotation = self.loadingRotation + dt * self.config.loading_speed
    end
    
    -- Update icon animations
    for key, scale in pairs(self.iconScales) do
        if scale > 1.0 then
            self.iconScales[key] = math.max(1.0, scale - dt * 4)
        else
            -- Draw loading state
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.push()
            love.graphics.translate(self.panel.x + self.panel.width/2, self.panel.y + self.panel.height/2)
            love.graphics.rotate(self.loadingRotation)
            for i=1,8 do
                local alpha = i/8 * math.pi * 2
                local radius = 4 * (1 + math.sin(self.loadingRotation + i/2)/4)
                love.graphics.circle("fill", math.cos(alpha)*20, math.sin(alpha)*20, radius)
            end
            love.graphics.pop()
        end
    end
    
    -- Update panel sliding with safety checks
    if self.panel.visible then
        self.panel.x = math.max(self.panel.target_x, self.panel.x - self.config.slide_speed * dt)
        -- Auto-play video when panel is fully visible
        if self.panel.x == self.panel.target_x and self.currentVideo then
            local isPlayingSuccess, isPlaying = pcall(function() return self.currentVideo:isPlaying() end)
            if isPlayingSuccess and not isPlaying then
                pcall(function() self.currentVideo:play() end)
                self.isPlaying = true
            end
        end
    else
        self.panel.x = math.min(self.gameWidth, self.panel.x + self.config.slide_speed * dt)
        -- Pause video when panel starts closing
        if self.currentVideo then
            local isPlayingSuccess, isPlaying = pcall(function() return self.currentVideo:isPlaying() end)
            if isPlayingSuccess and isPlaying then
                pcall(function() self.currentVideo:pause() end)
                self.isPlaying = false
            end
        end
    end
    
    -- Loop video when it ends with safety checks
    if self.isPlaying and self.currentVideo then
        local isPlayingSuccess, isPlaying = pcall(function() return self.currentVideo:isPlaying() end)
        if isPlayingSuccess and not isPlaying then
            pcall(function() 
                self.currentVideo:rewind()
                self.currentVideo:play()
            end)
        end
    end
end

function ReelsApp:draw()
    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont("fonts/FiraCode.ttf", 18)
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)

    -- Draw panel content first



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

            -- Draw video with safety checks
            if self.currentVideo:getWidth() > 0 and self.currentVideo:getHeight() > 0 then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(self.currentVideo, 
                    videoX, 
                    videoY, 
                    0, 
                    videoWidth / self.currentVideo:getWidth(), 
                    videoHeight / self.currentVideo:getHeight())
            else
                -- Draw loading animation in center
                local centerX = videoX + videoWidth / 2
                local centerY = videoY + videoHeight / 2
                
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.push()
                love.graphics.translate(centerX, centerY)
                love.graphics.rotate(self.loadingRotation)
                
                for i = 1, 8 do
                    local alpha = i/8 * math.pi * 2
                    local radius = 4 * (1 + math.sin(self.loadingRotation + i/2)/4)
                    love.graphics.circle("fill", math.cos(alpha)*30, math.sin(alpha)*30, radius)
                end
                love.graphics.pop()
                
                -- Loading text
                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.printf("Loading...", centerX - 100, centerY + 50, 200, "center")
            end
                
            -- Draw progress bar with safety checks
            if self.currentVideo then
                local isPlayingSuccess, isPlaying = pcall(function() return self.currentVideo:isPlaying() end)
                if isPlayingSuccess and isPlaying then
                    local success, duration = pcall(function() return self.currentVideo:getDuration() end)
                    if success and duration and duration > 0 then
                        local tellSuccess, currentTime = pcall(function() return self.currentVideo:tell() end)
                        if tellSuccess and currentTime then
                            local progress = currentTime / duration
                            love.graphics.setColor(1, 1, 1, 0.3)
                            love.graphics.rectangle("fill", videoX, videoY + videoHeight - 2, videoWidth, 2)
                            love.graphics.setColor(1, 1, 1, 0.8)
                            love.graphics.rectangle("fill", videoX, videoY + videoHeight - 2, videoWidth * progress, 2)
                        end
                    end
                end
            end

            -- Draw interaction buttons with new style
            local actionBarX = self.panel.x + self.panel.width - 70
            local actionBarY = videoY + videoHeight / 2
            local iconSpacing = self.config.icon_spacing
            local iconSize = 0.8 * self.config.icon_scale

            -- Like button with animation
            local likeScale = (reel.isLiked and 1.2 or 1.0) * self.iconScales.like
            love.graphics.setColor(reel.isLiked and self.config.accent_color or {1, 1, 1})
            drawHeartIcon(actionBarX + 20, actionBarY, iconSize * likeScale, reel.isLiked)
            love.graphics.print(self:formatNumber(reel.likes), 
                actionBarX + 5, actionBarY + 25)

            -- Comment button
            love.graphics.setColor(1, 1, 1)
            drawCommentIcon(actionBarX + 20, actionBarY + iconSpacing, iconSize * self.iconScales.comment)
            love.graphics.print(self:formatNumber(reel.comments), 
                actionBarX + 5, actionBarY + iconSpacing + 25)

            -- Share button
            love.graphics.setColor(1, 1, 1)
            drawShareIcon(actionBarX + 20, actionBarY + iconSpacing * 2, iconSize * self.iconScales.share)
            love.graphics.print(self:formatNumber(reel.shares), 
                actionBarX + 5, actionBarY + iconSpacing * 2 + 25)

            -- Video info overlay with improved style
            love.graphics.setColor(0, 0, 0, 0.7)
            local infoY = videoY + videoHeight - 140
            love.graphics.rectangle("fill", videoX, infoY, videoWidth - 70, 140)
            
            -- Add gradient overlay
            for i = 1, 20 do
                local alpha = (i - 1) / 19
                love.graphics.setColor(0, 0, 0, alpha * 0.7)
                love.graphics.rectangle("fill", videoX, infoY - 20 + i, videoWidth - 70, 1)
            end
            
            -- Info text with improved typography
            love.graphics.setColor(1, 1, 1)
            local titleFont = love.graphics.newFont("fonts/FiraCode.ttf", 24)
            local descFont = love.graphics.newFont("fonts/FiraCode.ttf", 16)
            
            love.graphics.setFont(titleFont)
            love.graphics.print("@" .. reel.title, videoX + 20, infoY + 20)
            
            love.graphics.setFont(descFont)
            love.graphics.print(reel.description, videoX + 20, infoY + 60)
            
            -- Music info with icon
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.circle("line", videoX + 20, infoY + 100, 8)
            love.graphics.circle("fill", videoX + 20, infoY + 100, 3)
            love.graphics.print(reel.music, videoX + 40, infoY + 95)
        end
    end

    love.graphics.setFont(default_font)
    
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
        
        -- Video play/pause on click with safety checks
        if x >= self.panel.x and x <= self.panel.x + self.panel.width then
            local videoHeight = self.panel.height * 0.8
            local videoY = self.panel.y + (self.panel.height - videoHeight) / 2
            if y >= videoY and y <= videoY + videoHeight then
                if self.currentVideo then
                    local isPlayingSuccess, isPlaying = pcall(function() return self.currentVideo:isPlaying() end)
                    if isPlayingSuccess then
                        if isPlaying then
                            pcall(function() self.currentVideo:pause() end)
                        else
                            pcall(function() self.currentVideo:play() end)
                        end
                        self.isPlaying = not self.isPlaying
                        return true
                    end
                end
            end
        end
        
        -- Like button detection (keep existing code)
        local videoHeight = self.panel.height * 0.8
        local videoY = self.panel.y + (self.panel.height - videoHeight) / 2
        local actionBarX = self.panel.x + self.panel.width - 60
        local actionBarY = videoY + videoHeight / 2

        -- Check icon clicks and trigger animations
        local function checkIconClick(x, y, centerX, centerY)
            local dx = x - centerX
            local dy = y - centerY
            return dx * dx + dy * dy <= 400
        end
        
        if checkIconClick(x, y, actionBarX + 20, actionBarY) then
            self.iconScales.like = 1.3
            self:toggleLike()
            return true
        elseif checkIconClick(x, y, actionBarX + 20, actionBarY + self.config.icon_spacing) then
            self.iconScales.comment = 1.3
            return true
        elseif checkIconClick(x, y, actionBarX + 20, actionBarY + self.config.icon_spacing * 2) then
            self.iconScales.share = 1.3
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
                local isPlayingSuccess, isPlaying = pcall(function() return self.currentVideo:isPlaying() end)
                if isPlayingSuccess then
                    if isPlaying then
                        pcall(function() self.currentVideo:pause() end)
                    else
                        pcall(function() self.currentVideo:play() end)
                    end
                    self.isPlaying = not self.isPlaying
                end
            end
        end
    end
end

return ReelsApp