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

	-- Draw background with gradient effect
	love.graphics.setColor(0.97, 0.97, 0.98)
	love.graphics.rectangle("fill", x, y, width, height)
	
	-- Calculate panel dimensions
	local leftPanelWidth = width * 0.4
	local rightPanelWidth = width * 0.6
	local padding = 15

	-- Draw left panel
	love.graphics.setColor(1, 1, 1, 0.95)
	love.graphics.rectangle("fill", x + padding, y + padding, leftPanelWidth - padding*2, height - padding*2, 10)
	
	-- Draw header with shadow
	love.graphics.setColor(0.2, 0.2, 0.2, 0.1)
	love.graphics.print("Available Missions", x + padding + 22, y + padding + 22)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.print("Available Missions", x + padding + 20, y + padding + 20)

	-- Draw missions list
	local missionHeight = 100
	local startY = y + padding + 60

	for i = 1 + self.scrollPosition, math.min(#self.missions, self.scrollPosition + self.maxMissionsVisible) do
		local mission = self.missions[i]
		local missionY = startY + (i - 1 - self.scrollPosition) * missionHeight

		-- Draw mission card with shadow
		love.graphics.setColor(0, 0, 0, 0.05)
		love.graphics.rectangle("fill", x + padding + 12, missionY + 2, leftPanelWidth - padding*4, missionHeight - 10, 8)

		-- Draw mission background
		if self.selectedMission == i then
			love.graphics.setColor(0.95, 0.97, 1)
		else
			love.graphics.setColor(1, 1, 1, 0.9)
		end
		love.graphics.rectangle("fill", x + padding + 10, missionY, leftPanelWidth - padding*4, missionHeight - 10, 8)

		-- Draw mission info
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print(mission.text, x + padding + 20, missionY + 15)
		love.graphics.setColor(0.5, 0.5, 0.5)
		love.graphics.print("Difficulty: " .. (mission.difficulty or "Normal"), x + padding + 20, missionY + 45)

		-- Draw select button with glow effect
		if self.selectedMission == i then
			love.graphics.setColor(0.4, 0.6, 1, 0.2)
			love.graphics.rectangle("fill", x + padding + 20, missionY + 65, 110, 25, 5)
		end
		love.graphics.setColor(0.4, 0.6, 1)
		love.graphics.rectangle("fill", x + padding + 15, missionY + 60, 100, 25, 5)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Select", x + padding + 35, missionY + 63)
	end

	-- Draw right panel if mission is selected
	if self.selectedMission then
		local mission = self.missions[self.selectedMission]
		local rightX = x + leftPanelWidth + padding

		-- Draw right panel background with shadow
		love.graphics.setColor(0, 0, 0, 0.05)
		love.graphics.rectangle("fill", rightX + 4, y + padding + 4, rightPanelWidth - padding*2, height - padding*2, 10)
		love.graphics.setColor(1, 1, 1, 0.95)
		love.graphics.rectangle("fill", rightX, y + padding, rightPanelWidth - padding*2, height - padding*2, 10)

		-- Draw mission details
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print("Mission Details", rightX + padding, y + padding + 20)
		love.graphics.print(mission.text, rightX + padding, y + padding + 60)
		
		-- Draw description
		love.graphics.setColor(0.4, 0.4, 0.4)
		love.graphics.printf(mission.description, rightX + padding, y + padding + 100, rightPanelWidth - padding*4)

		-- Draw tasks section
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.print("Tasks:", rightX + padding, y + padding + 180)
		for i, subtask in ipairs(mission.subtasks) do
			love.graphics.print("• " .. subtask, rightX + padding + 20, y + padding + 180 + i * 30)
		end

		-- Draw reward with enhanced visuals
		love.graphics.setColor(0.4, 0.6, 0.2)
		love.graphics.rectangle("fill", rightX + padding, y + height - 80, rightPanelWidth - padding*4, 40, 8)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Reward: " .. mission.reward, rightX + padding + 15, y + height - 70)
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

function MissionsApp:textinput(text)
	-- Handle any text input if needed
end

return MissionsApp