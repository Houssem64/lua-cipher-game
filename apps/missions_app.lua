local StoryMissions = require("story_missions")

local MissionsApp = {}
MissionsApp.__index = MissionsApp

function MissionsApp.new()
	local self = setmetatable({}, MissionsApp)
	self.missions = StoryMissions.getAllMissions()
	self.selectedMission = nil
	self.scrollPosition = 0
	self.maxMissionsVisible = 8
	return self
end

function MissionsApp:draw(x, y, width, height)
	-- Set up font
	local default_font = love.graphics.getFont()
	local font = love.graphics.newFont("fonts/FiraCode.ttf", 21)
	font:setFilter("nearest", "nearest")
	love.graphics.setFont(font)

	-- Draw background
	love.graphics.setColor(0.95, 0.95, 0.95)
	love.graphics.rectangle("fill", x, y, width, height)

	-- Calculate panel dimensions
	local leftPanelWidth = width * 0.4
	local rightPanelWidth = width * 0.6
	local padding = 10

	-- Draw left panel (missions list)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.print("Available Missions", x + padding, y + padding)

	local missionHeight = 100
	local startY = y + 50

	for i = 1 + self.scrollPosition, math.min(#self.missions, self.scrollPosition + self.maxMissionsVisible) do
		local mission = self.missions[i]
		local missionY = startY + (i - 1 - self.scrollPosition) * missionHeight

		-- Draw mission background
		if self.selectedMission == i then
			love.graphics.setColor(0.9, 0.95, 1)
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.rectangle("fill", x + padding, missionY, leftPanelWidth - padding*2, missionHeight - padding)

		-- Draw mission info
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print(mission.text, x + padding*2, missionY + padding)
		love.graphics.setColor(0.5, 0.5, 0.5)
		love.graphics.print("Difficulty: " .. (mission.difficulty or "Normal"), x + padding*2, missionY + padding + 30)
		
		-- Draw select button
		if self.selectedMission == i then
			love.graphics.setColor(0.3, 0.6, 1)
		else
			love.graphics.setColor(0.4, 0.7, 1)
		end
		love.graphics.rectangle("fill", x + padding*2, missionY + padding + 55, 100, 25)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Select", x + padding*2 + 20, missionY + padding + 58)
	end

	-- Draw right panel (mission details)
	if self.selectedMission then
		local mission = self.missions[self.selectedMission]
		local rightX = x + leftPanelWidth + padding

		-- Background
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("fill", rightX, y + padding, rightPanelWidth - padding*2, height - padding*2)

		-- Mission details
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print("Mission Details", rightX + padding, y + padding*2)
		love.graphics.print(mission.text, rightX + padding, y + padding*2 + 40)
		
		-- Description
		love.graphics.setColor(0.4, 0.4, 0.4)
		love.graphics.printf(mission.description, rightX + padding, y + padding*2 + 80, rightPanelWidth - padding*4)

		-- Subtasks
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print("Tasks:", rightX + padding, y + padding*2 + 160)
		for i, subtask in ipairs(mission.subtasks) do
			love.graphics.print("• " .. subtask, rightX + padding, y + padding*2 + 160 + i * 30)
		end

		-- Reward
		love.graphics.setColor(0.4, 0.6, 0.2)
		love.graphics.print("Reward: " .. mission.reward, rightX + padding, y + height - 60)
	end

	-- Reset font
	love.graphics.setFont(default_font)
end

function MissionsApp:mousepressed(x, y, button)
	if button == 1 then
		local startY = 60
		local missionHeight = 100
		local relativeY = y - startY
		local clickedIndex = math.floor(relativeY / missionHeight) + self.scrollPosition + 1

		if clickedIndex > 0 and clickedIndex <= #self.missions then
			-- Check if click was on the select button
			local buttonY = startY + (clickedIndex - 1 - self.scrollPosition) * missionHeight + 65
			if y >= buttonY and y <= buttonY + 25 and x >= 20 and x <= 120 then
				self:selectMission(clickedIndex)
			else
				self.selectedMission = clickedIndex
			end
		end
	end
end

function MissionsApp:selectMission(index)
	local mission = self.missions[index]
	
	-- Format subtasks for missions display
	local formattedSubtasks = {}
	for _, subtaskText in ipairs(mission.subtasks) do
		table.insert(formattedSubtasks, {
			text = subtaskText,
			completed = false
		})
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
			subtaskProgress = 0
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

function MissionsApp:textinput(text)
	-- Handle any text input if needed
end

return MissionsApp