local StoryMissions = require("story_missions")
local SaveSystem = require("modules.save_system")

local MissionsApp = {}
MissionsApp.__index = MissionsApp

function MissionsApp.new()
	local self = setmetatable({}, MissionsApp)
	self.missions = StoryMissions.getAllMissions()
	self.selectedMission = nil
	
	-- Add rank requirement display
	self.rankRequirementFont = love.graphics.newFont(16)
	self.viewedMission = nil  -- Add viewed mission tracking
	self.scrollPosition = 0
	self.maxMissionsVisible = 5
	self.resetButtonHovered = false
	self.nextButtonHovered = false
	self.prevButtonHovered = false
	
	-- Common layout variables
	self.padding = 30
	self.missionHeight = 180  -- Increased from 150 to fit rank and XP info
	self.startY = self.padding + 90  -- Increased to make room for pagination controls
	self.selectButtonWidth = 120
	self.selectButtonHeight = 35
	self.selectButtonX = self.padding + 15
	self.selectButtonY = 100
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

	-- Draw page numbers in boxes at the top
	local paginationY = y + self.padding + 50
	local currentPage = math.floor(self.scrollPosition / self.maxMissionsVisible) + 1
	local totalPages = math.ceil(#self.missions / self.maxMissionsVisible)
	local boxWidth = 30
	local boxHeight = 30
	local boxSpacing = 5
	local startX = x + self.padding + 20  -- Start from left side


	for i = 1, totalPages do
		if i == currentPage then
			love.graphics.setColor(0.4, 0.6, 1, 0.9) -- Highlight current page
		else
			love.graphics.setColor(0.6, 0.6, 0.6, 0.7)
		end
		
		-- Draw box
		love.graphics.rectangle("fill", startX + (i-1) * (boxWidth + boxSpacing), paginationY, boxWidth, boxHeight, 5)
		
		-- Draw page number
		love.graphics.setColor(1, 1, 1)
		local numberWidth = font:getWidth(tostring(i))
		local numberX = startX + (i-1) * (boxWidth + boxSpacing) + (boxWidth - numberWidth) / 2
		love.graphics.print(tostring(i), numberX, paginationY + 5)
	end

	-- Draw missions list
	local currentStartY = y + self.startY

	for i = 1 + self.scrollPosition, math.min(#self.missions, self.scrollPosition + self.maxMissionsVisible) do
		local mission = self.missions[i]
		local missionY = currentStartY + (i - 1 - self.scrollPosition) * self.missionHeight

		-- Check if mission is locked due to rank requirement
		local isLocked = false
		if mission.rank_required and _G.missionsManager then
			isLocked = not _G.missionsManager:checkRankRequirement(mission.rank_required)
		end

		-- Draw mission card with shadow
		love.graphics.setColor(0, 0, 0, 0.05)
		love.graphics.rectangle("fill", x + self.padding + 12, missionY + 2, leftPanelWidth - self.padding*4, self.missionHeight - 10, 8)

		-- Draw mission background with completion status or locked status
		if isLocked then
			love.graphics.setColor(0.8, 0.8, 0.8, 0.7) -- Gray out locked missions
		elseif self.selectedMission == i then
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
		if isLocked then
			love.graphics.setColor(0.5, 0.5, 0.5) -- Grayed out text for locked missions
		else
			love.graphics.setColor(0.2, 0.2, 0.2)
		end
		love.graphics.print(mission.text, x + self.padding + 20, missionY + 15)
		
		-- Draw difficulty rating with stars
		local difficulty = mission.difficulty or 2 -- Default to medium difficulty (2 stars)
		love.graphics.setColor(0.5, 0.5, 0.5)
		love.graphics.print("Difficulty: ", x + self.padding + 20, missionY + 45)
		
		-- Draw stars based on difficulty (1-5 scale)
		for star = 1, 5 do
			if star <= difficulty then
				love.graphics.setColor(1, 0.8, 0) -- Gold color for filled stars
			else
				love.graphics.setColor(0.7, 0.7, 0.7) -- Gray for empty stars
			end
			love.graphics.print("★", x + self.padding + 100 + (star-1)*20, missionY + 45)
		end

		-- Add rank requirement display
		if mission.rank_required then
			-- Check if player meets rank requirement
			local rankColor = {0.6, 0.4, 1} -- Default purple
			if isLocked then
				rankColor = {0.8, 0.2, 0.2} -- Red if requirement not met
			end
			love.graphics.setColor(unpack(rankColor))
			love.graphics.print("Required Rank: " .. mission.rank_required, x + self.padding + 20, missionY + 70)
			
			-- Draw lock icon for locked missions
			if isLocked then
				love.graphics.setColor(0.8, 0.2, 0.2)
				love.graphics.circle("fill", x + self.padding + leftPanelWidth - self.padding*2, missionY + 25, 15)
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("🔒", x + self.padding + leftPanelWidth - self.padding*2 - 8, missionY + 15)
				love.graphics.setColor(0.8, 0.2, 0.2)
				love.graphics.print("LOCKED", x + self.padding + leftPanelWidth - self.padding*6, missionY + 15)
			end
		end

		-- Also add ELO reward display
		if type(mission.reward) == "table" and mission.reward.elo then
			love.graphics.setColor(0.4, 0.6, 0.2)
			love.graphics.print("+" .. mission.reward.elo .. " ELO", x + leftPanelWidth - self.padding*6, missionY + 70)
		end
		
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

		-- Draw select button with glow effect - disable for locked missions
		if isLocked then
			love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Gray out button for locked missions
			love.graphics.rectangle("fill", x + self.selectButtonX, missionY + self.selectButtonY, self.selectButtonWidth, self.selectButtonHeight, 5)
			love.graphics.setColor(1, 1, 1, 0.5)
			love.graphics.print("Locked", x + self.selectButtonX + 20, missionY + self.selectButtonY + 3)
		elseif self.selectedMission == i then
			love.graphics.setColor(0.2, 0.8, 0.2) -- Green color for selected
			love.graphics.rectangle("fill", x + self.selectButtonX, missionY + self.selectButtonY, self.selectButtonWidth, self.selectButtonHeight, 5)
			love.graphics.setColor(1, 1, 1)
			love.graphics.print("Selected", x + self.selectButtonX + 15, missionY + self.selectButtonY + 3)
		else
			love.graphics.setColor(0.4, 0.6, 1)
			love.graphics.rectangle("fill", x + self.selectButtonX, missionY + self.selectButtonY, self.selectButtonWidth, self.selectButtonHeight, 5)
			love.graphics.setColor(1, 1, 1)
			love.graphics.print("Select", x + self.selectButtonX + 20, missionY + self.selectButtonY + 3)
		end
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

		-- Draw rank requirement if present
		if mission.rank_required then
			love.graphics.setColor(0.6, 0.4, 1)
			love.graphics.setFont(self.rankRequirementFont)
			love.graphics.print("Required Rank: " .. mission.rank_required, rightX + self.padding, y + self.padding + 150)
			
			-- Check if player meets rank requirement
			if _G.missionsManager and not _G.missionsManager:checkRankRequirement(mission.rank_required) then
				love.graphics.setColor(0.8, 0.2, 0.2)
				love.graphics.print("You need to reach this rank to start this mission", rightX + self.padding, y + self.padding + 170)
			end
			love.graphics.setFont(font) -- Reset font
		end

		-- Draw tasks section
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print("Tasks:", rightX + self.padding, y + self.padding + 180)
		for i, subtask in ipairs(mission.subtasks) do
			-- Handle subtask whether it's a string or an object
			local subtaskText = type(subtask) == "string" and subtask or subtask.text
			love.graphics.print("• " .. subtaskText, rightX + self.padding + 20, y + self.padding + 180 + i * 30)
		end

		-- Draw reward with enhanced visuals
		if mission.reward then
			-- Draw reward background
			love.graphics.setColor(0.4, 0.6, 0.2)
			love.graphics.rectangle("fill", rightX + self.padding, y + height - 80, rightPanelWidth - self.padding*4, 40, 8)
			love.graphics.setColor(1, 1, 1)
			
			-- Draw badge reward
			if type(mission.reward) == "table" then
				love.graphics.print("Rewards:", rightX + self.padding + 15, y + height - 70)
				love.graphics.print(mission.reward.badge, rightX + self.padding + 100, y + height - 70)
				love.graphics.print("+" .. mission.reward.elo .. " ELO", rightX + rightPanelWidth - self.padding*6, y + height - 70)
			else
				-- Fallback for old reward format
				love.graphics.print("Reward: " .. mission.reward, rightX + self.padding + 15, y + height - 70)
			end
		end
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
		-- Check pagination number clicks
		local resetButtonWidth = 100
		local resetButtonHeight = 30
		local leftPanelWidth = love.graphics.getWidth() * 0.4
		local paginationY = self.padding + 50
		local boxWidth = 30
		local boxHeight = 30
		local boxSpacing = 5
		local startX = baseX + self.padding + 20
		local totalPages = math.ceil(#self.missions / self.maxMissionsVisible)

		-- Check if clicked on a page number
		if relativeY >= paginationY and relativeY <= paginationY + boxHeight then
			for i = 1, totalPages do
				local boxX = startX + (i-1) * (boxWidth + boxSpacing)
				if relativeX >= boxX and relativeX <= boxX + boxWidth then
					self.scrollPosition = (i-1) * self.maxMissionsVisible
					return
				end
			end
		end


		-- Check reset button click
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
				local mission = self.missions[clickedIndex]
				-- First show the mission details in right panel
				self.viewedMission = clickedIndex
				
				-- Then check if click was on the select button
				local buttonY = missionStartY + (clickedIndex - 1 - self.scrollPosition) * self.missionHeight + self.selectButtonY
				if relativeY >= buttonY and relativeY <= buttonY + self.selectButtonHeight and 
				   relativeX >= self.selectButtonX and relativeX <= self.selectButtonX + self.selectButtonWidth then
					if mission.rank_required and _G.missionsManager and 
					   not _G.missionsManager:checkRankRequirement(mission.rank_required) then
						-- Don't allow selection if rank requirement not met
						-- Add a visual or sound feedback to indicate locked mission
						if self.completion_sound then
							local sound = self.completion_sound:clone()
							if sound then
								sound:setPitch(0.5) -- Lower pitch for error sound
								sound:setVolume(0.3)
								sound:play()
							end
						end
						return
					end
					
					-- Toggle selection
					if self.selectedMission == clickedIndex then
						self:selectMission(nil)  -- Deselect if already selected
					else
						self:selectMission(clickedIndex)
					end
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
		local completedCount = 0
		for i = 1, #mission.subtasks do
			if self.completedSubtasks[missionIndex][i] then
				completedCount = completedCount + 1
			else
				allComplete = false
			end
		end
		
		-- Update progress
		mission.progress = completedCount / #mission.subtasks
		mission.subtaskProgress = mission.progress
		
		-- If all subtasks are complete, mark mission as complete
		if allComplete and not self.completedMissions[missionIndex] then
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

function MissionsApp:getMissionIndexById(id)
	for i, mission in ipairs(self.missions) do
		if mission.id == id then
			return i
		end
	end
	return nil
end

function MissionsApp:selectMission(indexOrId)
	local index = type(indexOrId) == "number" and indexOrId or self:getMissionIndexById(indexOrId)
	if not index then return end

	local mission = self.missions[index]
	
	-- Check rank requirement
	if mission.rank_required and _G.missionsManager then
		if not _G.missionsManager:checkRankRequirement(mission.rank_required) then
			-- Don't allow selection if rank requirement not met
			return
		end
	end

	self.selectedMission = index
	self.viewedMission = nil  -- Clear viewed mission when selecting
	
	-- Clear previous missions in display
	if _G.missions then
		_G.missions.missions = {}
		_G.missions.panel.visible = true  -- Keep panel visible
		
		-- Format subtasks with current completion state
		local formattedSubtasks = {}
		for i, subtask in ipairs(mission.subtasks) do
			table.insert(formattedSubtasks, {
				text = type(subtask) == "string" and subtask or subtask.text,
				completed = self.completedSubtasks[index] and self.completedSubtasks[index][i] or false
			})
		end
		
		-- Add updated mission with selected state
		local newMission = {
			id = mission.id,
			text = mission.text,
			description = mission.description,
			subtasks = formattedSubtasks,
			completed = self.completedMissions[index] or false,
			progress = self:getMissionProgress(index),
			subtaskProgress = self:getMissionProgress(index),
			selected = true,  -- Ensure this is set
			reward = mission.reward,
			rank_required = mission.rank_required
		}
		_G.missions:addMission(newMission)
	end

	-- Update mission state in missions manager
	if _G.missionsManager then
		_G.missionsManager.lastSelectedMissionIndex = index
		_G.missionsManager.lastSelectedMissionId = mission.id
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
	local leftPanelWidth = love.graphics.getWidth() * 0.4
	
	-- Update reset button hover state
	local resetButtonWidth = 100
	local resetButtonHeight = 30
	local resetButtonX = self.padding + 20
	local resetButtonY = height - resetButtonHeight - self.padding*2
	
	self.resetButtonHovered = relativeX >= resetButtonX and relativeX <= resetButtonX + resetButtonWidth and
							 relativeY >= resetButtonY and relativeY <= resetButtonY + resetButtonHeight

	-- No need for pagination button hover states since we removed the buttons

end

function MissionsApp:resetProgress()
	-- Clear local state
	self.completedMissions = {}
	self.completedSubtasks = {}
	
	-- Clear saved progress by saving empty state
	SaveSystem:save({
		completed = {},
		subtasks = {},
		elo = 0  -- Reset to base ELO of 0
	}, "mission_progress")
	
	-- Reset missions manager
	if _G.missionsManager then
		_G.missionsManager:resetAllMissions()
		-- Reset ELO and rank
		_G.missionsManager.elo = 0
		_G.missionsManager.currentRank = _G.missionsManager.ranks and _G.missionsManager.ranks[1] or nil
	end
	
	-- Reset missions display
	if _G.missions then
		_G.missions.missions = {}
		_G.missions.savedState = {
			completed = {},
			subtasks = {},
			elo = 0
		}
		-- Keep panel visible to show "No missions selected"
		_G.missions.panel.visible = true
	end
	
	-- Clear selection
	self.selectedMission = nil
end


function MissionsApp:resetMissions()
	-- Reload missions from StoryMissions
	self.missions = StoryMissions.getAllMissions()
	-- Reset selection and view state
	self.selectedMission = nil
	self.viewedMission = nil
	-- Reset scroll position
	self.scrollPosition = 0
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
		subtasks = {},
		elo = _G.missionsManager and _G.missionsManager:getELO() or 0
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
	
	SaveSystem:save(progress, "mission_progress")
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