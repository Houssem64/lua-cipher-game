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
    self.y_offset = 250 or 0  -- Default to 0 if not provided
    
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
        -- Panel background with rounded corners
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle('fill', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height,
            self.config.panel_radius)
            
        -- Panel border
        love.graphics.setColor(unpack(self.config.panel_border_color))
        love.graphics.rectangle('line', 
            self.panel.x, 
            self.panel.y, 
            self.panel.width, 
            self.panel.height,
            self.config.panel_radius)
        
        -- Header
        love.graphics.setFont(header_font)
        love.graphics.setColor(unpack(self.config.text_color))
        love.graphics.print("Missions", 
            self.panel.x + 20, 
            self.panel.y + 20)
        
        -- Draw missions list
        love.graphics.setFont(mission_font)
        local mission_y = self.panel.y + 80
        
        for i, mission in ipairs(self.missions) do
            -- Mission background (with hover effect)
            local hover = love.mouse.getY() >= mission_y and 
                         love.mouse.getY() <= mission_y + self.config.mission_height
            
            if hover then
                love.graphics.setColor(unpack(self.config.hover_color))
            else
                love.graphics.setColor(1, 1, 1, 0.5)
            end
            
            love.graphics.rectangle('fill',
                self.panel.x + 10,
                mission_y,
                self.panel.width - 20,
                self.config.mission_height,
                8)
            
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
                
                for i, subtask in ipairs(mission.subtasks) do
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
                    end
                    
                    -- Draw subtask text
                    love.graphics.setColor(0.7, 0.7, 0.7)
                    love.graphics.print(subtask,
                        self.panel.x + 65,
                        subtaskY + 2)
                    
                    subtaskY = subtaskY + subtaskHeight
                end
                
                -- Update mission height to accommodate subtasks
                mission_y = subtaskY + 10
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
                
                mission_y = mission_y + self.config.mission_height + 10
            end
            
           
                
            mission_y = mission_y + self.config.mission_height + 10
        end
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(default_font)
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

function Missions:addMission(mission)
    -- Add mission with its ID
    table.insert(self.missions, {
        id = mission.id,
        text = mission.text,
        description = mission.description,
        subtasks = mission.subtasks,
        completed = mission.completed,
        progress = mission.progress or 0,
        subtaskProgress = mission.subtaskProgress or 0
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
    if self.missions[index] then
        self.missions[index].completed = true
    end
end

return Missions
