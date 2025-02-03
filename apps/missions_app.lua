local StoryMissions = require("story_missions")

local MissionsApp = {}
MissionsApp.__index = MissionsApp

function MissionsApp.new()
	local self = setmetatable({}, MissionsApp)
	self.missions = StoryMissions.getAllMissions()
	self.selectedMission = nil
	self.scrollPosition = 0
	self.maxMissionsVisible = 8
	self.completedMissions = {}
	self.resetButtonHovered = false
	
	-- Common layout variables
	self.padding = 30
	self.missionHeight = 150
	self.startY = self.padding + 60
	self.selectButtonWidth = 120
	self.selectButtonHeight = 35
	self.selectButtonX = self.padding + 15
	self.selectButtonY = 90  -- Y offset for the select button
	self.selectButtonPadding = 5
	
	return self
end

function MissionsApp:draw(x, y, width, height)
	-- Set up font
	local default_font = love.graphics.getFont()
	local font = love.graphics.newFont("fonts/FiraCode.ttf", 21)
	font:setFilter("nearest", "nearest")
	love.graphics.setFont(font)

	-- Draw background with gradient effect
	love.graphics.setColor(0.97, 0.97, 0.98)
	love.graphics.rectangle("fill", x, y, width, height)
	
	-- Calculate panel dimensions
	local leftPanelWidth = width * 0.4
	local rightPanelWidth = width * 0.6
	-- Draw left panel
	love.graphics.setColor(1, 1, 1, 0.95)
	love.graphics.rectangle("fill", x + self.padding, y + self.padding, leftPanelWidth - self.padding*2, height - self.padding*2, 10)
	
	-- Draw header with completion stats and reset button
	love.graphics.setColor(0.2, 0.2, 0.2, 0.1)
	love.graphics.print("Available Missions", x + self.padding + 22, y + self.padding + 22)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.print("Available Missions", x + self.padding + 20, y + self.padding + 20)
	
	-- Show completion percentage
	local completedCount = 0
	for _, _ in pairs(self.completedMissions) do completedCount = completedCount + 1 end
	local completionPercent = math.floor((completedCount / #self.missions) * 100)
	love.graphics.setColor(0.4, 0.6, 0.2)
	love.graphics.print(completionPercent .. "% Complete", x + leftPanelWidth - self.padding*6, y + self.padding + 20)
	
	-- Draw reset button
	local resetButtonWidth = 100
	local resetButtonHeight = 30
	local resetButtonX = x + self.padding + 20
	local resetButtonY = y + height - resetButtonHeight - self.padding*2
	
	-- Draw reset button with hover effect
	if self.resetButtonHovered then
		love.graphics.setColor(0.9, 0.3, 0.3, 0.9)
	else
		love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
	end
	love.graphics.rectangle("fill", resetButtonX, resetButtonY, resetButtonWidth, resetButtonHeight, 5)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Reset All", resetButtonX + 15, resetButtonY + 5)

	-- Draw missions list
	local currentStartY = y + self.startY


	for i = 1 + self.scrollPosition, math.min(#self.missions, self.scrollPosition + self.maxMissionsVisible) do
		local mission = self.missions[i]
		local missionY = currentStartY + (i - 1 - self.scrollPosition) * self.missionHeight

		-- Draw mission card with shadow
		love.graphics.setColor(0, 0, 0, 0.05)
		love.graphics.rectangle("fill", x + self.padding + 12, missionY + 2, leftPanelWidth - self.padding*4, self.missionHeight - 10, 8)

		-- Draw mission background
		if self.selectedMission == i then
			love.graphics.setColor(0.95, 0.97, 1)
		else
			love.graphics.setColor(1, 1, 1, 0.9)
		end
		love.graphics.rectangle("fill", x + self.padding + 10, missionY, leftPanelWidth - self.padding*4, self.missionHeight - 10, 8)

		-- Draw mission info
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print(mission.text, x + self.padding + 20, missionY + 15)
		love.graphics.setColor(0.5, 0.5, 0.5)
		love.graphics.print("Difficulty: " .. (mission.difficulty or "Normal"), x + self.padding + 20, missionY + 45)
		
		-- Draw mission completion status
		if self.completedMissions[i] then
			-- Draw completion badge
			love.graphics.setColor(0.2, 0.8, 0.2)
			love.graphics.circle("fill", x + self.padding + leftPanelWidth - self.padding*2, missionY + 25, 15)
			love.graphics.setColor(1, 1, 1)
			love.graphics.print("✓", x + self.padding + leftPanelWidth - self.padding*2 - 8, missionY + 15)
			
			-- Draw "COMPLETED" text
			love.graphics.setColor(0.2, 0.8, 0.2)
			love.graphics.print("COMPLETED", x + self.padding + leftPanelWidth - self.padding*6, missionY + 15)
		end

		-- Draw select button with glow effect
		if self.selectedMission == i then
			love.graphics.setColor(0.4, 0.6, 1, 0.2)
			love.graphics.rectangle("fill", x + self.padding + 20, missionY + self.selectButtonY + 5, self.selectButtonWidth + 10, self.selectButtonHeight, 5)
		end
		love.graphics.setColor(0.4, 0.6, 1)
		love.graphics.rectangle("fill", x + self.selectButtonX, missionY + self.selectButtonY, self.selectButtonWidth, self.selectButtonHeight, 5)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Select", x + self.selectButtonX + 20, missionY + self.selectButtonY + 3)
	end

	-- Draw right panel if mission is selected
	if self.selectedMission then
		local mission = self.missions[self.selectedMission]
		local rightX = x + leftPanelWidth + self.padding

		-- Draw right panel background with shadow
		love.graphics.setColor(0, 0, 0, 0.05)
		love.graphics.rectangle("fill", rightX + 4, y + self.padding + 4, rightPanelWidth - self.padding*2, height - self.padding*2, 10)
		love.graphics.setColor(1, 1, 1, 0.95)
		love.graphics.rectangle("fill", rightX, y + self.padding, rightPanelWidth - self.padding*2, height - self.padding*2, 10)

		-- Draw mission details
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print("Mission Details", rightX + self.padding, y + self.padding + 20)
		love.graphics.print(mission.text, rightX + self.padding, y + self.padding + 60)
		
		-- Draw description
		love.graphics.setColor(0.4, 0.4, 0.4)
		love.graphics.printf(mission.description, rightX + self.padding, y + self.padding + 100, rightPanelWidth - self.padding*4)

		-- Draw tasks section
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print("Tasks:", rightX + self.padding, y + self.padding + 180)
		for i, subtask in ipairs(mission.subtasks) do
			love.graphics.print("• " .. subtask, rightX + self.padding + 20, y + self.padding + 180 + i * 30)
		end

		-- Draw reward with enhanced visuals
		love.graphics.setColor(0.4, 0.6, 0.2)
		love.graphics.rectangle("fill", rightX + self.padding, y + height - 80, rightPanelWidth - self.padding*4, 40, 8)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Reward: " .. mission.reward, rightX + self.padding + 15, y + height - 70)
	end

	-- Reset font
	love.graphics.setFont(default_font)
end

function MissionsApp:mousepressed(x, y, button, baseX, baseY)
	if not baseX or not baseY then return end
	
	-- Adjust coordinates relative to the app's position
	local relativeX = x
	local relativeY = y
	local height = love.graphics.getHeight()
	
	if button == 1 then
		-- Check reset button click
		local resetButtonWidth = 100
		local resetButtonHeight = 30
		local resetButtonX = self.padding + 20
		local resetButtonY = height - resetButtonHeight - self.padding*2
		
		if relativeX >= resetButtonX and relativeX <= resetButtonX + resetButtonWidth and
		   relativeY >= resetButtonY and relativeY <= resetButtonY + resetButtonHeight then
			self:resetProgress()
			return
		end

		-- Calculate mission selection
		local missionStartY = self.startY
		local clickedY = relativeY - missionStartY
		local clickedIndex = math.floor(clickedY / self.missionHeight) + self.scrollPosition + 1

		if clickedIndex > 0 and clickedIndex <= #self.missions then
			-- Check if click was on the select button
			local buttonY = missionStartY + (clickedIndex - 1 - self.scrollPosition) * self.missionHeight + self.selectButtonY
			if relativeY >= buttonY and relativeY <= buttonY + self.selectButtonHeight and 
			   relativeX >= self.selectButtonX and relativeX <= self.selectButtonX + self.selectButtonWidth then
				self:selectMission(clickedIndex)
			else
				self.selectedMission = clickedIndex
				
				-- Check for subtask checkbox clicks in right panel
				if self.selectedMission then
					local mission = self.missions[self.selectedMission]
					local leftPanelWidth = love.graphics.getWidth() * 0.4
					local rightPanelStart = leftPanelWidth + self.padding
					
					-- Only check for checkbox clicks if we're in the right panel area
					if relativeX > rightPanelStart then
						local checkboxX = relativeX - rightPanelStart
						
						-- Check each subtask's checkbox
						for i = 1, #mission.subtasks do
							local checkboxY = self.padding + 180 + i * 30
							-- Check if click is within checkbox area (increased clickable area)
							if relativeY >= checkboxY - 10 and relativeY <= checkboxY + 25 and
							   checkboxX >= self.padding + 15 and checkboxX <= self.padding + 50 then
								self:toggleSubtaskComplete(self.selectedMission, i)
								break
							end
						end
					end
				end
			end
		end
	elseif button == 2 then  -- Right click to toggle completion
		local clickedY = relativeY - self.startY
		local clickedIndex = math.floor(clickedY / self.missionHeight) + self.scrollPosition + 1
		
		if clickedIndex > 0 and clickedIndex <= #self.missions then
			self:toggleMissionComplete(clickedIndex)
		end
	end
end


function MissionsApp:toggleSubtaskComplete(missionIndex, subtaskIndex)
	local mission = self.missions[missionIndex]
	if mission and mission.subtasks[subtaskIndex] then
		-- Toggle completion in missions manager
		if _G.missionsManager then
			_G.missionsManager:toggleSubtaskComplete(mission.id, subtaskIndex)
		end
		
		-- Toggle completion in missions display
		if _G.missions then
			_G.missions:completeSubtask(mission.id, subtaskIndex)
		end
	end
end

function MissionsApp:toggleMissionComplete(missionIndex)
	local mission = self.missions[missionIndex]
	if mission then
		if self.completedMissions[missionIndex] then
			self.completedMissions[missionIndex] = nil
			
			-- Reset in missions manager
			if _G.missionsManager then
				_G.missionsManager:resetMission(mission.id)
			end
		else
			self.completedMissions[missionIndex] = true
			
			-- Complete in missions manager
			if _G.missionsManager then
				_G.missionsManager:completeMission(mission.id)
			end
		end
	end
end

function MissionsApp:selectMission(index)
	self.selectedMission = index
	local mission = self.missions[index]
	
	-- Format subtasks for missions display
	local formattedSubtasks = {}
	for _, subtaskText in ipairs(mission.subtasks) do
		table.insert(formattedSubtasks, {
			text = subtaskText,
			completed = false
		})
	end
	
	-- Clear previous missions in display before adding new one
	if _G.missions then
		_G.missions.missions = {}
	end
	
	-- Sync with missions manager
	if _G.missionsManager then
		_G.missionsManager:addMission(mission)
	end
	
	-- Sync with missions display
	if _G.missions then
		_G.missions:addMission({
			id = mission.id,
			text = mission.text,
			description = mission.description,
			subtasks = formattedSubtasks,
			completed = false,
			progress = 0,
			subtaskProgress = 0,
			selected = true,
			reward = mission.reward
		})
	end
end

function MissionsApp:wheelmoved(x, y)
	self.scrollPosition = math.max(0, math.min(
		self.scrollPosition - y,
		#self.missions - self.maxMissionsVisible
	))
end

function MissionsApp:keypressed(key)
	-- Handle any key presses if needed
end

function MissionsApp:mousemoved(x, y, baseX, baseY)
	if not baseX or not baseY then return end
	
	-- Adjust coordinates relative to the app's position
	local relativeX = x
	local relativeY = y
	local height = love.graphics.getHeight()
	
	-- Update reset button hover state
	local resetButtonWidth = 100
	local resetButtonHeight = 30
	local resetButtonX = self.padding + 20
	local resetButtonY = height - resetButtonHeight - self.padding*2
	
	self.resetButtonHovered = relativeX >= resetButtonX and relativeX <= resetButtonX + resetButtonWidth and
							 relativeY >= resetButtonY and relativeY <= resetButtonY + resetButtonHeight
end

function MissionsApp:resetProgress()
	-- Clear completed missions
	self.completedMissions = {}
	
	-- Reset missions in global missions manager
	if _G.missionsManager then
		_G.missionsManager:resetAllMissions()
	end
	
	-- Reset display in missions panel
	if _G.missions then
		_G.missions.missions = {}
		if self.selectedMission then
			self:selectMission(self.selectedMission)
		end
	end
end

function MissionsApp:textinput(text)
	-- Handle any text input if needed
end

return MissionsApp