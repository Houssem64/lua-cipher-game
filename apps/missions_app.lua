local StoryMissions = require("story_missions")
local SaveSystem = require("modules.save_system")

local MissionsApp = {}
MissionsApp.__index = MissionsApp

function MissionsApp.new()
	local self = setmetatable({}, MissionsApp)
	self.missions = StoryMissions.getAllMissions()
	self.selectedMission = nil
	self.viewedMission = nil  -- Add viewed mission tracking
	self.scrollPosition = 0
	self.maxMissionsVisible = 8
	self.resetButtonHovered = false
	
	-- Common layout variables
	self.padding = 30
	self.missionHeight = 150
	self.startY = self.padding + 60
	self.selectButtonWidth = 120
	self.selectButtonHeight = 35
	self.selectButtonX = self.padding + 15
	self.selectButtonY = 90
	self.selectButtonPadding = 5
	
	-- Load completion sound
	local success, result = pcall(function()
		return love.audio.newSource("task_complete.wav", "static")
	end)
	if success then
		self.completion_sound = result
	end
	
	-- Load saved mission progress
	local savedProgress = SaveSystem:load("mission_progress") or {}
	self.completedMissions = {}
	self.completedSubtasks = {}
	
	-- Convert string indices back to numbers for completed missions
	if savedProgress.completed then
		for strIndex, completed in pairs(savedProgress.completed) do
			if completed then
				self.completedMissions[tonumber(strIndex)] = true
			end
		end
	end
	
	-- Convert string indices back to numbers for subtasks
	if savedProgress.subtasks then
		for strMissionIndex, subtasks in pairs(savedProgress.subtasks) do
			local missionIndex = tonumber(strMissionIndex)
			self.completedSubtasks[missionIndex] = {}
			for strSubtaskIndex, completed in pairs(subtasks) do
				if completed then
					self.completedSubtasks[missionIndex][tonumber(strSubtaskIndex)] = true
				end
			end
		end
	end
	
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

		-- Draw mission background with completion status
		if self.selectedMission == i then
			love.graphics.setColor(0.95, 0.97, 1)
		elseif self.viewedMission == i then
			love.graphics.setColor(0.9, 0.9, 1, 0.9)  -- Light blue tint for viewed
		elseif self.completedMissions[i] then
			love.graphics.setColor(0.9, 1, 0.9, 0.9)  -- Green tint for completed
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

	-- Draw right panel if mission is selected or viewed
	if self.selectedMission or self.viewedMission then
		local mission = self.missions[self.selectedMission or self.viewedMission]
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
			-- Handle subtask whether it's a string or an object
			local subtaskText = type(subtask) == "string" and subtask or subtask.text
			love.graphics.print("• " .. subtaskText, rightX + self.padding + 20, y + self.padding + 180 + i * 30)
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
	
	-- Check if click is in missions area
	local missionStartY = self.startY
	local missionEndY = missionStartY + (math.min(#self.missions, self.maxMissionsVisible) * self.missionHeight)
	local inMissionsArea = relativeY >= missionStartY and relativeY <= missionEndY
	
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

		if inMissionsArea then
			-- Calculate mission index
			local clickedY = relativeY - missionStartY
			local clickedIndex = math.floor(clickedY / self.missionHeight) + self.scrollPosition + 1

			if clickedIndex > 0 and clickedIndex <= #self.missions then
				-- Check if click was on the select button
				local buttonY = missionStartY + (clickedIndex - 1 - self.scrollPosition) * self.missionHeight + self.selectButtonY
				if relativeY >= buttonY and relativeY <= buttonY + self.selectButtonHeight and 
				   relativeX >= self.selectButtonX and relativeX <= self.selectButtonX + self.selectButtonWidth then
					-- Toggle selection
					if self.selectedMission == clickedIndex then
						self:selectMission(nil)  -- Deselect if already selected
					else
						self:selectMission(clickedIndex)
					end
				else
					-- Just view the mission without selecting it
					self.viewedMission = clickedIndex
				end
			else
				-- Clear viewed mission if clicked in missions area but not on a mission
				self.viewedMission = nil
			end
		else
			-- Clear viewed mission if clicked outside missions area
			self.viewedMission = nil
		end

		-- Check for subtask checkbox clicks in right panel
		if self.selectedMission then
			local mission = self.missions[self.selectedMission]
			local leftPanelWidth = love.graphics.getWidth() * 0.4
			local rightPanelStart = leftPanelWidth + self.padding
			
			if relativeX > rightPanelStart then
				local checkboxX = relativeX - rightPanelStart
				
				for i = 1, #mission.subtasks do
					local checkboxY = self.padding + 180 + i * 30
					if relativeY >= checkboxY - 10 and relativeY <= checkboxY + 25 and
					   checkboxX >= self.padding + 15 and checkboxX <= self.padding + 50 then
						self:toggleSubtaskComplete(self.selectedMission, i)
						break
					end
				end
			end
		end
	elseif button == 2 then  -- Right click to toggle completion
		if inMissionsArea then
			local clickedY = relativeY - self.startY
			local clickedIndex = math.floor(clickedY / self.missionHeight) + self.scrollPosition + 1
			
			if clickedIndex > 0 and clickedIndex <= #self.missions then
				self:toggleMissionComplete(clickedIndex)
			end
		end
	end
end


function MissionsApp:toggleSubtaskComplete(missionIndex, subtaskIndex)
	local mission = self.missions[missionIndex]
	if mission and mission.subtasks[subtaskIndex] then
		-- Initialize subtasks array if it doesn't exist
		if not self.completedSubtasks[missionIndex] then
			self.completedSubtasks[missionIndex] = {}
		end
		
		-- Toggle completion state
		self.completedSubtasks[missionIndex][subtaskIndex] = not self.completedSubtasks[missionIndex][subtaskIndex]
		
		-- Toggle completion in missions manager
		if _G.missionsManager then
			_G.missionsManager:toggleSubtaskComplete(mission.id, subtaskIndex)
		end
		
		-- Toggle completion in missions display
		if _G.missions then
			_G.missions:completeSubtask(mission.id, subtaskIndex)
		end
		
		-- Check if all subtasks are complete
		local allComplete = true
		for i = 1, #mission.subtasks do
			if not self.completedSubtasks[missionIndex][i] then
				allComplete = false
				break
			end
		end
		
		-- If all subtasks are complete, mark mission as complete
		if allComplete then
			self.completedMissions[missionIndex] = true
			
			-- Play completion sound
			if self.completion_sound then
				self.completion_sound:stop()
				self.completion_sound:play()
			end
		end
		
		-- Save progress
		self:saveMissionProgress()
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
	self.viewedMission = nil  -- Clear viewed mission when selecting
	
	-- Clear previous missions in display
	if _G.missions then
		_G.missions.missions = {}
		
		if index then
			local mission = self.missions[index]
			-- Format subtasks with current completion state
			local formattedSubtasks = self:getFormattedSubtasks(mission.id)
			
			-- Add updated mission
			_G.missions:addMission({
				id = mission.id,
				text = mission.text,
				description = mission.description,
				subtasks = formattedSubtasks,
				completed = self.completedMissions[index] or false,
				progress = self:getMissionProgress(index),
				subtaskProgress = self:getMissionProgress(index),
				selected = true,
				reward = mission.reward
			})
		end
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
	-- Clear local state
	self.completedMissions = {}
	self.completedSubtasks = {}
	
	-- Clear saved progress by saving empty state
	SaveSystem:save({
		completed = {},
		subtasks = {}
	}, "mission_progress")
	
	-- Reset missions manager
	if _G.missionsManager then
		_G.missionsManager:resetAllMissions()
	end
	
	-- Reset missions display
	if _G.missions then
		-- Clear existing missions
		_G.missions.missions = {}
		-- Clear saved state in missions
		_G.missions.savedState = {
			completed = {},
			subtasks = {}
		}
		
		-- Re-add all missions with reset state
		for _, mission in ipairs(self.missions) do
			-- Format subtasks as objects with text and completed properties
			local formattedSubtasks = {}
			for _, subtask in ipairs(mission.subtasks) do
				-- Handle subtask whether it's a string or an object
				local subtaskText = type(subtask) == "string" and subtask or subtask.text
				table.insert(formattedSubtasks, {
					text = subtaskText,
					completed = false
				})
			end
			
			_G.missions:addMission({
				id = mission.id,
				text = mission.text,
				description = mission.description,
				subtasks = formattedSubtasks,
				completed = false,
				progress = 0,
				subtaskProgress = 0,
				selected = mission.id == self.selectedMission,
				reward = mission.reward,
				reset = true  -- Mark as reset to prevent loading saved state
			})
		end
	end
	
	-- Force redraw

	self.selectedMission = nil
end

function MissionsApp:getFormattedSubtasks(missionId)
	local mission = nil
	for _, m in ipairs(self.missions) do
		if m.id == missionId then
			mission = m
			break
		end
	end
	
	if not mission then return {} end
	
	local formattedSubtasks = {}
	for i, subtask in ipairs(mission.subtasks) do
		-- Handle subtask whether it's a string or an object
		local subtaskText = type(subtask) == "string" and subtask or subtask.text
		table.insert(formattedSubtasks, {
			text = subtaskText,
			completed = self.completedSubtasks[missionId] and self.completedSubtasks[missionId][i] or false
		})
	end
	return formattedSubtasks
end

function MissionsApp:saveMissionProgress()
	local progress = {
		completed = {},
		subtasks = {}
	}
	
	-- Save completed missions
	for index, completed in pairs(self.completedMissions) do
		progress.completed[tostring(index)] = completed
	end
	
	-- Save completed subtasks
	for missionIndex, subtasks in pairs(self.completedSubtasks) do
		progress.subtasks[tostring(missionIndex)] = {}
		for subtaskIndex, completed in pairs(subtasks) do
			progress.subtasks[tostring(missionIndex)][tostring(subtaskIndex)] = completed
		end
	end
	
	SaveSystem:save("mission_progress", progress)
end

function MissionsApp:getMissionProgress(index)
	local mission = self.missions[index]
	local completedCount = 0
	if self.completedSubtasks[index] then
		for i = 1, #mission.subtasks do
			if self.completedSubtasks[index][i] then
				completedCount = completedCount + 1
			end
		end
	end
	return completedCount / #mission.subtasks
end

function MissionsApp:textinput(text)
	-- Handle any text input if needed
end

return MissionsApp