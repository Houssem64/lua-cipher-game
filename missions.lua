-- missions.lua
local Missions = {
    config = {
        button_radius = 15,
        panel_width = 500,
        slide_speed = 1000,
        button_color = {0.6, 0.4, 1},
        panel_color = {0.95, 0.95, 0.98, 0.95},  -- Lighter background
        text_color = {0.2, 0.2, 0.2},
        panel_border_color = {0.8, 0.8, 0.85},
        panel_radius = 15,
        mission_height = 60,
        mission_padding = 15,
        hover_color = {0.97, 0.97, 1, 0.95},
        progress_bar_color = {0.6, 0.4, 1, 0.8},
        progress_bg_color = {0.9, 0.9, 0.9},
        completed_color = {0.4, 0.8, 0.4},
        header_size = 24,
        mission_size = 18,
        M_size = 18
    }
}
Missions.__index = Missions

function Missions.new(x, y, config)
    local self = setmetatable({}, Missions)
    
    -- Merge provided config with defaults
    self.config = setmetatable(config or {}, {__index = Missions.config})
    
    -- Initialize state using virtual resolution
    self.gameWidth = 1920
    self.gameHeight = 500

    -- Y offset for dynamic positioning
    self.y_offset = 300 or 0  -- Default to 0 if not provided
    
    -- Mission button properties
    self.button = {
        x = self.gameWidth - 300,  -- Position from right edge
        y = 5,  -- Below chat button
        width = 40,
        height = 40,
        radius = self.config.button_radius
    }
    
    -- Mission panel properties
    self.panel = {
        x = self.gameWidth,  -- Start off screen
        target_x = self.gameWidth - self.config.panel_width,
        y = self.y_offset,  -- Adjusted by y_offset
        width = self.config.panel_width,
        height = self.gameHeight,
        visible = false
    }
    
    -- Mission state
    self.missions = {}  -- Stores the list of missions
    
    -- Load saved mission progress
    local SaveSystem = require("modules/save_system")
    self.savedState = SaveSystem:load("mission_progress") or {}
    
    -- Load completion sound
    local success, result = pcall(function()
        local sound = love.audio.newSource("task_complete.wav", "static")
        print("Loading completion sound:", sound)  -- Debug print
        return sound
    end)
    if success then
        self.completion_sound = result
        print("Successfully loaded completion sound:", self.completion_sound)
        print("Successfully loaded completion sound")
    else
        print("Failed to load completion sound:", result)
        self.completion_sound = nil
    end




    -- Notification state
    self.notification = {
        active = false,
        progress = 0,
        x = self.gameWidth / 2,
        y = self.gameHeight / 2,
        target_x = self.gameWidth / 2,
        target_y = self.gameHeight / 2,
        scale = 0,
        alpha = 0,
        text = "",
        color = {0, 1, 0},  -- Lime green
        rotation = 0,
        outline_size = 3,
        particles = {
            count = 0,
            max = 20,
            list = {}  -- Will store active particles
        }
    }

    -- Rank display initialization
    self.rankDisplay = {
        x = self.gameWidth - 500,
        y = self.gameHeight - 500,
        width = 180,
        height = 40,
        alpha = 0.9
    }
    
    return self
end

function Missions:update(dt)
    -- Update mission panel position
    if self.panel.visible then
        self.panel.x = math.max(self.panel.target_x, 
            self.panel.x - self.config.slide_speed * dt)
    else
        self.panel.x = math.min(self.gameWidth, 
            self.panel.x + self.config.slide_speed * dt)
    end

    if self.notification.active then
        -- Update particles
        if self.notification.particles then
            for i = #self.notification.particles.list, 1, -1 do
                local particle = self.notification.particles.list[i]
                particle.x = particle.x + math.cos(particle.angle) * particle.speed * dt
                particle.y = particle.y + math.sin(particle.angle) * particle.speed * dt
                particle.life = particle.life - dt
                particle.size = particle.size * 0.95
                
                if particle.life <= 0 then
                    table.remove(self.notification.particles.list, i)
                end
            end
        end

        self.notification.progress = math.min(1, self.notification.progress + dt)
        local t = self.notification.progress
        
        -- Animation phases
        if t < 0.3 then
            -- Pop in with rotation
            self.notification.scale = math.sin(t * math.pi * 1.67) * 1.2
            self.notification.alpha = math.min(t * 3.33, 1)
            self.notification.rotation = math.sin(t * math.pi * 2) * 0.1
        elseif t < 0.7 then
            -- Hold with subtle floating motion
            self.notification.scale = 1.2 + math.sin(t * 10) * 0.05
            self.notification.alpha = 1
            self.notification.rotation = math.sin(t * 5) * 0.05
        else
            -- Fade out
            local fadeT = (t - 0.7) / 0.3
            self.notification.scale = 1.2 * (1 - fadeT)
            self.notification.alpha = 1 - fadeT
            self.notification.rotation = math.sin(t * 5) * 0.05 * (1 - fadeT)
        end
        
        if t >= 1.0 then
            self.notification.active = false
        end
    end

end


function Missions:draw()
    local default_font = love.graphics.getFont()
    local header_font = love.graphics.newFont("fonts/FiraCode.ttf", self.config.header_size)
    local mission_font = love.graphics.newFont("fonts/FiraCode.ttf", self.config.mission_size)
    local text_size = love.graphics.newFont("fonts/FiraCode.ttf", self.config.M_size)
    header_font:setFilter("nearest", "nearest")
    mission_font:setFilter("nearest", "nearest")

    -- Draw mission button with glow effect
    love.graphics.setColor(self.config.button_color[1], self.config.button_color[2], 
        self.config.button_color[3], 0.3)
    love.graphics.circle('fill', 
        self.button.x + self.button.radius, 
        self.button.y + self.button.radius, 
        self.button.radius + 4)
    
    love.graphics.setColor(unpack(self.config.button_color))
    love.graphics.circle('fill', 
        self.button.x + self.button.radius, 
        self.button.y + self.button.radius, 
        self.button.radius)
    
    -- Draw "M" text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(text_size)
    love.graphics.print("M", 
        self.button.x + 10, 
        self.button.y + 5)


    -- Draw mission panel
    if self.panel.x < self.gameWidth then
        -- Panel background with enhanced shadow effect
        love.graphics.setColor(0, 0, 0, 0.1)
        love.graphics.rectangle('fill', 
            self.panel.x + 4, 
            self.panel.y + 4, 
            self.panel.width, 
            self.panel.height,
            self.config.panel_radius)
            
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle('fill', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height,
            self.config.panel_radius)
            
        -- Panel border with glow effect
        love.graphics.setColor(self.config.panel_border_color[1], 
            self.config.panel_border_color[2], 
            self.config.panel_border_color[3], 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle('line', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height,
            self.config.panel_radius)
        love.graphics.setLineWidth(1)
        
        -- Header
        love.graphics.setFont(header_font)
        love.graphics.setColor(unpack(self.config.text_color))
        love.graphics.print("Missions", 
            self.panel.x + 20, 
            self.panel.y + 20)
        
        -- Draw missions list
        love.graphics.setFont(mission_font)
        local mission_y = self.panel.y + 80
        
        if #self.missions == 0 then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("No missions selected",
                self.panel.x + 20,
                self.panel.y + 80)
        else
            for i, mission in ipairs(self.missions) do

            local current_mission_height = self.config.mission_height
            
            -- Add height for description if present
            if mission.description and mission.description ~= "" then
                current_mission_height = current_mission_height + 25
            end
            
            -- Add height for subtasks if present
            if mission.subtasks and #mission.subtasks > 0 then
                current_mission_height = current_mission_height + (#mission.subtasks * 25) + 10
            end
            
            -- Update hover state
            local mouse_x = love.mouse.getX()
            local mouse_y = love.mouse.getY()
            mission.hover = self.panel.visible and 
                          mouse_y >= mission_y and 
                          mouse_y <= mission_y + current_mission_height and
                          mouse_x >= self.panel.x + 10 and 
                          mouse_x <= self.panel.x + self.panel.width - 10
            
            -- Enhanced mission background
            if mission.hover then
                love.graphics.setColor(0.95, 0.97, 1, 0.95)
            else
                love.graphics.setColor(1, 1, 1, 0.8)
            end
            
            -- Add subtle shadow
            love.graphics.setColor(0, 0, 0, 0.05)
            love.graphics.rectangle('fill',
                self.panel.x + 12,
                mission_y + 2,
                self.panel.width - 24,
                current_mission_height,
                10)

            -- Draw main mission background
            if mission.hover then
                love.graphics.setColor(0.95, 0.97, 1, 0.95)
            else
                love.graphics.setColor(1, 1, 1, 0.8)
            end
            love.graphics.rectangle('fill',
                self.panel.x + 10,
                mission_y,
                self.panel.width - 20,
                current_mission_height,
                10)
            
            -- Mission text first
            if mission.completed then
                love.graphics.setColor(unpack(self.config.completed_color))
            else
                love.graphics.setColor(unpack(self.config.text_color))
            end
            
            love.graphics.print(mission.text,
                self.panel.x + 25,
                mission_y + self.config.mission_padding)

            -- Draw description if present
            if mission.description and mission.description ~= "" then
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.print(mission.description,
                    self.panel.x + 25,
                    mission_y + self.config.mission_padding + 25)
            end

            -- Draw subtasks if any
            if mission.subtasks and #mission.subtasks > 0 then
                local subtaskY = mission_y + self.config.mission_padding + 50
                local subtaskHeight = 25
                local checkboxSize = 18
                
                -- Calculate completed subtasks
                local completedSubtasks = 0
                for _, subtask in ipairs(mission.subtasks) do
                    if subtask.completed then
                        completedSubtasks = completedSubtasks + 1
                    end
                end
                
                -- Update mission progress based on subtasks
                mission.progress = completedSubtasks / #mission.subtasks
                mission.subtaskProgress = mission.progress
                
                for _, subtask in ipairs(mission.subtasks) do
                    -- Draw checkbox
                    love.graphics.setColor(0.8, 0.8, 0.8)
                    love.graphics.rectangle('line', 
                        self.panel.x + 40, 
                        subtaskY, 
                        checkboxSize, 
                        checkboxSize,
                        3)  -- Rounded corners
                    
                    if subtask.completed then
                        love.graphics.setColor(unpack(self.config.completed_color))
                        love.graphics.rectangle('fill', 
                            self.panel.x + 42, 
                            subtaskY + 2, 
                            checkboxSize - 4, 
                            checkboxSize - 4,
                            2)  -- Rounded corners for fill
                        -- Draw subtask text in completed color
                        love.graphics.setColor(unpack(self.config.completed_color))
                    else
                        -- Draw subtask text in normal color
                        love.graphics.setColor(unpack(self.config.text_color))
                    end
                    
                    -- Draw subtask text
                    love.graphics.print(subtask.text,
                        self.panel.x + 65,
                        subtaskY + 2)
                    
                    subtaskY = subtaskY + subtaskHeight
                end
            else
                -- Regular progress bar for missions without subtasks
                love.graphics.setColor(unpack(self.config.progress_bg_color))
                love.graphics.rectangle('fill',
                    self.panel.x + 20,
                    mission_y + self.config.mission_height - 12,
                    self.panel.width - 40,
                    8,
                    4)
                    
                if mission.completed then
                    love.graphics.setColor(unpack(self.config.completed_color))
                    love.graphics.rectangle('fill',
                        self.panel.x + 20,
                        mission_y + self.config.mission_height - 12,
                        self.panel.width - 40,
                        8,
                        4)
                    love.graphics.setColor(1, 1, 1, 0.8)
                    love.graphics.circle('fill',
                        self.panel.x + self.panel.width - 35,
                        mission_y + self.config.mission_height - 8,
                        6)
                else
                    love.graphics.setColor(unpack(self.config.progress_bar_color))
                    local progress = mission.subtaskProgress or 0
                    local progressWidth = (self.panel.width - 40) * progress
                    love.graphics.rectangle('fill',
                        self.panel.x + 20,
                        mission_y + self.config.mission_height - 12,
                        progressWidth,
                        8,
                        4)
                    love.graphics.setColor(1, 1, 1, 0.9)
                    love.graphics.printf(math.floor(progress * 100) .. "%",
                        self.panel.x + 20,
                        mission_y + self.config.mission_height - 25,
                        self.panel.width - 40,
                        "right")
                end
            end
            
            -- Move to next mission position
            mission_y = mission_y + current_mission_height + 10
        end
        end
    end
    
    -- Reset color and font
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(default_font)
    
    -- Draw rank display
    if _G.missionsManager then
        local rank = _G.missionsManager:getCurrentRank()
        local progress = _G.missionsManager:getRankProgress()
        local elo = _G.missionsManager:getELO()
        
        -- Background
        love.graphics.setColor(0, 0, 0, self.rankDisplay.alpha * 0.7)
        love.graphics.rectangle('fill',
            self.rankDisplay.x,
            self.rankDisplay.y,
            self.rankDisplay.width,
            self.rankDisplay.height,
            10)
        
        -- Border
        love.graphics.setColor(0.6, 0.4, 1, self.rankDisplay.alpha)
        love.graphics.rectangle('line',
            self.rankDisplay.x,
            self.rankDisplay.y,
            self.rankDisplay.width,
            self.rankDisplay.height,
            10)
        
        -- Rank text
        love.graphics.setColor(1, 1, 1, self.rankDisplay.alpha)
        local rankFont = love.graphics.newFont(14)
        love.graphics.setFont(rankFont)
        love.graphics.print("Rank: " .. rank.name,
            self.rankDisplay.x + 10,
            self.rankDisplay.y + 5)
        
        -- ELO text
        local eloFont = love.graphics.newFont(12)
        love.graphics.setFont(eloFont)
        love.graphics.print("ELO: " .. elo,
            self.rankDisplay.x + 10,
            self.rankDisplay.y + 25)
        
--[[         -- Progress bar background
        love.graphics.setColor(0.3, 0.3, 0.3, self.rankDisplay.alpha)
        love.graphics.rectangle('fill',
            self.rankDisplay.x + 10,
            self.rankDisplay.y + 35,
            self.rankDisplay.width - 20,
            4,
            2)
        
        -- Progress bar fill
        love.graphics.setColor(0.6, 0.4, 1, self.rankDisplay.alpha)
        love.graphics.rectangle('fill',
            self.rankDisplay.x + 10,
            self.rankDisplay.y + 35,
            (self.rankDisplay.width - 20) * progress,
            4,
            2) ]]
    end

    -- Draw notification last to ensure it's on top
    if self.notification.active then
        -- Draw particles first
        if self.notification.particles then
            for _, particle in ipairs(self.notification.particles.list) do
                love.graphics.setColor(self.notification.color[1], 
                                     self.notification.color[2], 
                                     self.notification.color[3], 
                                     particle.life * self.notification.alpha)
                love.graphics.circle('fill', particle.x, particle.y, particle.size * self.notification.scale)
            end
        end
        
        -- Draw glow effect
        love.graphics.setColor(self.notification.color[1], 
                             self.notification.color[2], 
                             self.notification.color[3], 
                             self.notification.alpha * 0.2)  -- Glow effect
        love.graphics.circle('fill', self.notification.x, self.notification.y, 60 * self.notification.scale)
        
        -- Draw text with outline
        local font = love.graphics.newFont("fonts/FiraCode.ttf", 48)
        love.graphics.setFont(font)
        local text = "RANK UP!\n" .. self.notification.text
        local textWidth = font:getWidth(text)
        local textHeight = font:getHeight() * 2  -- Account for two lines
        
        -- Draw black outline
        love.graphics.setColor(0, 0, 0, self.notification.alpha)
        for i = 0, 360, 45 do  -- Draw outline in 8 directions
            local rad = math.rad(i)
            local ox = math.cos(rad) * self.notification.outline_size
            local oy = math.sin(rad) * self.notification.outline_size
            love.graphics.printf(text, 
                self.notification.x - textWidth/2 + ox,
                self.notification.y - textHeight/2 + oy,
                textWidth, "center", self.notification.rotation,
                self.notification.scale, self.notification.scale)
        end
        
        -- Draw main text in notification color
        love.graphics.setColor(self.notification.color[1], 
                             self.notification.color[2], 
                             self.notification.color[3], 
                             self.notification.alpha)
        love.graphics.printf(text, 
            self.notification.x - textWidth/2,
            self.notification.y - textHeight/2,
            textWidth, "center", self.notification.rotation,
            self.notification.scale, self.notification.scale)
    end


end



function Missions:mousepressed(x, y)
    -- Check if mission button was clicked
    local dx = x - (self.button.x + self.button.radius)
    local dy = y - (self.button.y + self.button.radius)
    if dx * dx + dy * dy <= self.button.radius * self.button.radius then
        self.panel.visible = not self.panel.visible
        print("Missions:mousepressed - Panel visibility toggled:", self.panel.visible)
        return true
    end
    return false
end

function Missions:resetNotification()
    self.notification = {
        active = false,
        progress = 0,
        x = self.gameWidth / 2,
        y = self.gameHeight / 2,
        target_x = self.gameWidth / 2,
        target_y = self.gameHeight / 2,
        scale = 0,
        alpha = 0,
        text = "",
        color = {0, 1, 0},  -- Lime green
        rotation = 0,
        outline_size = 3,
        particles = {
            count = 0,
            max = 20,
            list = {}  -- Will store active particles
        }
    }
end

function Missions:startNotification()
    -- Only start a new notification if one isn't already active
    if self.notification.active then
        print("Notification already active, waiting for completion")
        return
    end
    
    -- Force reset notification state before starting a new one
    self:resetNotification()
    
    -- Set up new notification
    self.notification = {
        active = true,
        progress = 0,
        x = self.gameWidth / 2,
        y = self.gameHeight / 2,
        target_x = self.gameWidth / 2,
        target_y = self.gameHeight / 2,
        scale = 0,
        alpha = 1,
        text = "Mission Complete!",
        color = {0.4, 0.8, 0.4},  -- Green color for mission completion
        rotation = 0,
        outline_size = 3,
        particles = {
            count = 0,
            max = 20,
            list = {}
        }
    }
    
    -- Create initial particles
    for i = 1, 20 do
        table.insert(self.notification.particles.list, {
            x = self.gameWidth / 2,
            y = self.gameHeight / 2,
            angle = math.random() * math.pi * 2,
            speed = math.random(100, 200),
            size = math.random(4, 8),
            life = 1.0
        })
    end
end

function Missions:resetMissions()
    -- Clear all missions
    self.missions = {}
    -- Reset notification state
    self:resetNotification()
    -- Keep panel visible
    self.panel.visible = true
    print("Missions:resetMissions - Panel visible:", self.panel.visible)
end

function Missions:addMission(mission)
    -- Remove any existing mission with the same ID
    for i = #self.missions, 1, -1 do
        if self.missions[i].id == mission.id then
            table.remove(self.missions, i)
            break
        end
    end

    -- Only apply saved state if the mission isn't explicitly marked as reset
    if self.savedState and not mission.reset then
        -- Apply mission completion
        mission.completed = mission.completed or 
                          (self.savedState.completed and self.savedState.completed[tostring(mission.id)]) or false
        
        -- Apply subtask completion
        if self.savedState.subtasks and self.savedState.subtasks[tostring(mission.id)] then
            for i, subtask in ipairs(mission.subtasks) do
                subtask.completed = subtask.completed or 
                                  self.savedState.subtasks[tostring(mission.id)][tostring(i)] or false
            end
        end
        
        -- Calculate progress
        local completedCount = 0
        for _, subtask in ipairs(mission.subtasks) do
            if subtask.completed then
                completedCount = completedCount + 1
            end
        end
        mission.progress = mission.progress or (completedCount / #mission.subtasks)
        mission.subtaskProgress = mission.subtaskProgress or mission.progress
    end

    -- Add the new mission
    local newMission = {
        id = mission.id,
        title = mission.text,
        text = mission.text,
        description = mission.description,
        subtasks = mission.subtasks,
        completed = mission.completed or false,
        progress = mission.progress or 0,
        subtaskProgress = mission.subtaskProgress or 0,
        hover = false,
        selected = mission.selected,  -- Keep the selected state
        reward = mission.reward,
        reset = mission.reset
    }
    
    -- Debug print
    print("Missions:addMission - Adding mission:", newMission.id, "selected:", newMission.selected)
    
    -- If this mission is selected, unselect all others
    if newMission.selected then
        print("Missions:addMission - Unselecting other missions")
        for _, m in ipairs(self.missions) do
            if m.selected then
                print("Missions:addMission - Unselecting mission:", m.id)
                m.selected = false
            end
        end
    end
    
    table.insert(self.missions, newMission)
    
    -- Ensure panel is visible when adding missions
    self.panel.visible = true
    print("Missions:addMission - Panel visible:", self.panel.visible)
    
    return newMission

end

-- Get mission by ID
function Missions:getMissionById(id)
    for _, mission in ipairs(self.missions) do
        if mission.id == id then
            return mission
        end
    end
    return nil
end

-- Update mission by ID
function Missions:updateMission(id, updatedMission)
    for i, mission in ipairs(self.missions) do
        if mission.id == id then
            self.missions[i] = updatedMission
            break
        end
    end
end

function Missions:completeMission(index)
    local mission = type(index) == "number" and self.missions[index] or nil
    if mission and not mission.completed then
        print("Completing mission: " .. mission.text)  -- Debug print
        
        -- Complete all subtasks if they exist
        if mission.subtasks then
            for _, subtask in ipairs(mission.subtasks) do
                subtask.completed = true
            end
        end
        
        -- Reset notification state before starting new one
        self:resetNotification()
        
        -- Update mission state
        mission.completed = true
        mission.progress = 1
        mission.subtaskProgress = 1
        
        -- Play completion sound
        if self.completion_sound then
            print("Playing completion sound")  -- Debug print
            self.completion_sound:stop()
            self.completion_sound:play()
        else
            print("No completion sound loaded")  -- Debug print
        end
        
        -- Start notification animation
        self:startNotification()
        
        -- Update saved state
        if _G.missionsManager then
            _G.missionsManager:saveMissionState()
        end
    end
end

function Missions:completeSubtask(missionId, subtaskIndex)
    local mission = self:getMissionById(missionId)
    if mission and mission.subtasks and mission.subtasks[subtaskIndex] then
        -- Only proceed if the subtask isn't already completed
        if not mission.subtasks[subtaskIndex].completed then
            -- Update mission progress
            mission.subtasks[subtaskIndex].completed = true
            
            -- Check if all subtasks are complete
            local allComplete = true
            local completedCount = 0
            for _, subtask in ipairs(mission.subtasks) do
                if subtask.completed then
                    completedCount = completedCount + 1
                else
                    allComplete = false
                end
            end
            
            -- Update progress
            mission.progress = completedCount / #mission.subtasks
            mission.subtaskProgress = mission.progress
            
            -- Play subtask completion sound
            if self.completion_sound and not mission.completed then
                local sound = self.completion_sound:clone()
                if sound then
                    sound:setPitch(1.2)
                    sound:setVolume(0.3)
                    sound:play()
                end
            end
            
            -- Complete mission if all subtasks are done and mission isn't already completed
            if allComplete and not mission.completed then
                -- Reset notification state before starting new one
                self:resetNotification()
                
                mission.completed = true
                mission.progress = 1
                mission.subtaskProgress = 1
                
                -- Play completion sound
                if self.completion_sound then
                    self.completion_sound:stop()
                    self.completion_sound:play()
                end
                
                -- Start notification animation
                self:startNotification()
            end

            
            -- Update saved state
            if _G.missionsManager then
                _G.missionsManager:saveMissionState()
            end
        end
    end
end




function Missions:startRankUpNotification(newRank)
    -- Reset notification state
    self:resetNotification()
    
    -- Set up rank up notification with new animation properties
    self.notification = {
        active = true,
        progress = 0,
        x = self.gameWidth / 2,  -- Start from center
        y = self.gameHeight / 2,
        target_x = self.gameWidth / 2,
        target_y = self.gameHeight / 2,
        scale = 0,
        alpha = 0,
        text = newRank,
        color = {0, 1, 0},  -- Lime green
        rotation = 0,
        outline_size = 3,
        particles = {
            count = 0,
            max = 20,
            list = {}  -- Will store active particles
        }
    }
    
    -- Create initial particles
    for i = 1, 20 do
        table.insert(self.notification.particles.list, {
            x = self.gameWidth / 2,
            y = self.gameHeight / 2,
            angle = math.random() * math.pi * 2,
            speed = math.random(100, 200),
            size = math.random(4, 8),
            life = 1.0
        })
    end
    
    -- Play completion sound with higher pitch for rank up
    if self.completion_sound then
        local sound = self.completion_sound:clone()
        if sound then
            sound:setPitch(1.5)
            sound:setVolume(0.4)
            sound:play()
        end
    end
end

function Missions:completeMissionById(missionId)
    local mission = self:getMissionById(missionId)
    if mission and not mission.completed then
        -- Complete all subtasks first if they exist
        if mission.subtasks then
            for _, subtask in ipairs(mission.subtasks) do
                subtask.completed = true
            end
        end
        
        -- Reset notification state before starting new one
        self:resetNotification()
        
        -- Update mission state
        mission.completed = true
        mission.progress = 1
        mission.subtaskProgress = 1
        
        -- Play completion sound only if mission wasn't completed before
        if self.completion_sound then
            self.completion_sound:stop()
            self.completion_sound:play()
        end
        
        -- Start notification animation
        self:startNotification()
        
        -- Update saved state
        if _G.missionsManager then
            _G.missionsManager:saveMissionState()
        end
    end
end


return Missions
