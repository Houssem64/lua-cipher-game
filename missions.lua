-- missions.lua
local Missions = {
    config = {
        button_radius = 20,
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
        x = self.gameWidth - 60,  -- Position from right edge
        y = 120,  -- Below chat button
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
        return love.audio.newSource("task_complete.wav", "static")
    end)
    if success then
        self.completion_sound = result
        print("Successfully loaded completion sound")
    else
        print("Failed to load completion sound:", result)
        self.completion_sound = nil
    end



    -- Notification state
    self.notification = {
        active = false,
        progress = 0,
        x = 0,
        y = 0,
        target_x = 0,
        target_y = 0,
        scale = 0,
        alpha = 0,
        text = ""
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

    -- Update notification animation
    if self.notification.active then
        print("Notification state:", string.format(
            "progress=%.2f, x=%.2f, y=%.2f, scale=%.2f, alpha=%.2f",
            self.notification.progress,
            self.notification.x,
            self.notification.y,
            self.notification.scale,
            self.notification.alpha
        ))
        
        self.notification.progress = self.notification.progress + dt * 1.5 -- Slower animation
        
        -- Animate position with easing
        local t = math.min(1, self.notification.progress)
        t = t * t * (3 - 2 * t) -- Smooth step interpolation
        self.notification.x = self.button.x + self.button.radius + (self.notification.target_x - (self.button.x + self.button.radius)) * t
        self.notification.y = self.button.y + self.button.radius + (self.notification.target_y - (self.button.y + self.button.radius)) * t
        
        -- Animate scale and alpha with smoother curves
        self.notification.scale = math.sin(t * math.pi) * 1.5
        self.notification.alpha = math.cos(t * math.pi / 2)
        
        -- End animation
        if self.notification.progress >= 1 then
            print("Notification animation complete")
            self.notification.active = false
        end
    end
end

function Missions:draw()
    local default_font = love.graphics.getFont()
    local header_font = love.graphics.newFont("joty.otf", self.config.header_size)
    local mission_font = love.graphics.newFont("joty.otf", self.config.mission_size)
    local text_size = love.graphics.newFont("joty.otf", self.config.M_size)
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
        self.button.x + 12, 
        self.button.y + 10)


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
    
    -- Draw notification last to ensure it's on top
    if self.notification.active then
        -- Draw glow effect
        love.graphics.setColor(self.config.completed_color[1], 
                             self.config.completed_color[2], 
                             self.config.completed_color[3], 
                             self.notification.alpha * 0.3)
        love.graphics.circle('fill', self.notification.x, self.notification.y, 40 * self.notification.scale)
        
        -- Draw checkmark with color
        love.graphics.setColor(self.config.completed_color[1], 
                             self.config.completed_color[2], 
                             self.config.completed_color[3], 
                             self.notification.alpha)
        
        -- Save current transform
        love.graphics.push()
        
        -- Set transform for checkmark
        love.graphics.translate(self.notification.x, self.notification.y)
        love.graphics.scale(self.notification.scale, self.notification.scale)
        
        -- Draw checkmark
        local size = 30
        love.graphics.setLineWidth(4)
        love.graphics.line(-size/2, 0, -size/6, size/2)
        love.graphics.line(-size/6, size/2, size/2, -size/2)
        
        -- Restore transform
        love.graphics.pop()
        love.graphics.setLineWidth(1)
        
        -- Draw completion text
        local font = love.graphics.newFont(24)
        love.graphics.setFont(font)
        local textWidth = font:getWidth(self.notification.text)
        love.graphics.print(self.notification.text, 
            self.notification.x - textWidth/2,
            self.notification.y + 40 * self.notification.scale,
            0, self.notification.scale, self.notification.scale)
    end

end



function Missions:mousepressed(x, y)
    -- Check if mission button was clicked
    local dx = x - (self.button.x + self.button.radius)
    local dy = y - (self.button.y + self.button.radius)
    if dx * dx + dy * dy <= self.button.radius * self.button.radius then
        self.panel.visible = not self.panel.visible
        return true
    end
    return false
end


function Missions:resetMissions()
    -- Clear all missions
    self.missions = {}
    -- Reset notification state
    self.notification = {
        active = false,
        progress = 0,
        x = 0,
        y = 0,
        target_x = 0,
        target_y = 0,
        scale = 0,
        alpha = 0,
        text = ""
    }
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
    table.insert(self.missions, {
        id = mission.id,
        title = mission.text,
        text = mission.text,
        description = mission.description,
        subtasks = mission.subtasks,
        completed = mission.completed or false,
        progress = mission.progress or 0,
        subtaskProgress = mission.subtaskProgress or 0,
        hover = false,
        selected = mission.selected or false,
        reward = mission.reward,
        reset = mission.reset
    })

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
    if mission then
        print("Completing mission: " .. mission.text)  -- Debug print
        mission.completed = true
        
        -- Play completion sound
        if self.completion_sound then
            print("Playing completion sound")  -- Debug print
            self.completion_sound:stop()
            self.completion_sound:play()
        else
            print("No completion sound loaded")  -- Debug print
        end
        
        -- Start notification animation
        print("Starting notification animation")  -- Debug print
        self.notification.active = true
        self.notification.progress = 0
        self.notification.x = self.button.x + self.button.radius
        self.notification.y = self.button.y + self.button.radius
        self.notification.target_x = self.gameWidth / 2
        self.notification.target_y = self.gameHeight / 3
        self.notification.scale = 0
        self.notification.alpha = 1
        self.notification.text = "Mission Complete!"
    end
end

function Missions:completeSubtask(missionId, subtaskIndex)
    local mission = self:getMissionById(missionId)
    if mission and mission.subtasks and mission.subtasks[subtaskIndex] then
        -- Play task completion sound
        if self.completion_sound then
            local sound = self.completion_sound:clone()
            if sound then
                sound:setPitch(1.2)
                sound:setVolume(0.5)
                sound:play()
            end
        end
        
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
        
        -- Complete mission if all subtasks are done
        if allComplete then
            self:completeMissionById(missionId)
        end
        
        -- Update saved state
        if _G.missionsManager then
            _G.missionsManager:saveMissionState()
        end
    end
end


function Missions:completeMissionById(missionId)
    local mission = self:getMissionById(missionId)
    if mission and not mission.completed then
        -- Complete all subtasks first
        for _, subtask in ipairs(mission.subtasks) do
            subtask.completed = true
        end
        
        -- Update mission state
        mission.completed = true
        mission.progress = 1
        mission.subtaskProgress = 1
        
        -- Play completion sound
        if self.completion_sound then
            self.completion_sound:stop()
            self.completion_sound:play()
        end
        
        -- Start notification animation
        self.notification.active = true
        self.notification.progress = 0
        self.notification.x = self.button.x + self.button.radius
        self.notification.y = self.button.y + self.button.radius
        self.notification.target_x = self.gameWidth / 2
        self.notification.target_y = self.gameHeight / 3
        self.notification.scale = 0
        self.notification.alpha = 1
        self.notification.text = "Mission Complete!"
        
        -- Update saved state
        if _G.missionsManager then
            _G.missionsManager:saveMissionState()
        end

    end
end

return Missions
