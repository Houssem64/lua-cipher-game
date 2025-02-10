local BootSequence = {
	bootSound = nil,
	skipButtonHovered = false,
	skipButtonWidth = 80,
	skipButtonHeight = 30,
	messages = {
		"[  OK  ] Reached target Local File Systems",
		"[  OK  ] Started udev Kernel Device Manager",
		"[  OK  ] Started User Manager for UID 1000",
		"[  OK  ] Mounted /boot filesystem",
		"[  OK  ] Started Network Manager Script Dispatcher Service",
		"[  OK  ] Started LOVE OS System Initialization",
		"[  OK  ] Started Game Resource Manager",
		"[  OK  ] Started System Security Services",
		"[  OK  ] Started Memory Management Service",
		"[  OK  ] Started Hardware Detection Service",
		"[  OK  ] Started Audio Subsystem",
		"[  OK  ] Started Input Device Manager",
		"[  OK  ] Started Graphics Driver Service",
		"[  OK  ] Started Window Management System",
		"[  OK  ] Started Desktop Environment",
		"[  OK  ] Reached target Graphical Interface",
		"[  OK  ] Started LOVE OS Display Manager",
		"[  OK  ] System is ready",
	},
	ascii_art = [[
	╔══════════════════════════════════════╗
	║    _     ___  _   _ _____ ___  ___   ║
	║   | |   / _ \| | | | ____/ _ \/ __|  ║
	║   | |  | | | | | | |  _|| | | \__ \  ║
	║   | |__| |_| | |_| | |__| |_| |___/  ║
	║   |____|\___/ \___/|_____\___/\____| ║
	║                                      ║
	║            OS v1.0.0                 ║
	╚══════════════════════════════════════╝
	]],
	current_message = 1,
	timer = 0,
	message_delay = 0.5,
	progress = 0,
	active = false,
	fade_alpha = 0,
	completed = false,
	terminal_font = nil,
	onComplete = nil
}

function BootSequence:new(onComplete)
	local instance = setmetatable({}, { __index = BootSequence })
	instance.terminal_font = love.graphics.newFont("fonts/FiraCode.ttf", 16)
	instance.onComplete = onComplete
	instance.bootSound = love.audio.newSource("sounds/bootupsequance.mp3", "stream")
	return instance
end

function BootSequence:start()
	self.active = true
	self.completed = false
	self.current_message = 1
	self.timer = 0
	self.progress = 0
	self.fade_alpha = 0
	if self.bootSound then
		self.bootSound:play()
	end
end

function BootSequence:update(dt)
	if not self.active then return end

	self.timer = self.timer + dt
	
	-- Update fade in/out
	if self.completed then
		self.fade_alpha = math.min(1, self.fade_alpha + dt)
		if self.fade_alpha >= 1 and self.onComplete then
			self.active = false
			if self.bootSound then
				self.bootSound:stop()
			end
			self.onComplete()
		end
	else
		-- Progress bar animation
		self.progress = math.min(1, self.progress + dt * 0.2)
		
		-- Message display timing
		if self.timer >= self.message_delay then
			self.timer = 0
			self.current_message = self.current_message + 1
			
			-- Check if sequence is complete
			if self.current_message > #self.messages then
				self.completed = true
			end
		end
	end
end

function BootSequence:draw()
	if not self.active then return end

	-- Save current graphics state
	local prevFont = love.graphics.getFont()
	love.graphics.setFont(self.terminal_font)

	-- Draw black background
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	-- Draw ASCII art
	love.graphics.setColor(0.2, 0.8, 0.2)
	local art_y = 50
	for line in self.ascii_art:gmatch("[^\n]+") do
		love.graphics.print(line, love.graphics.getWidth()/2 - self.terminal_font:getWidth(line)/2, art_y)
		art_y = art_y + self.terminal_font:getHeight()
	end

	-- Draw messages
	love.graphics.setColor(0.8, 0.8, 0.8)
	local message_y = art_y + 50
	for i = 1, math.min(self.current_message, #self.messages) do
		love.graphics.print(self.messages[i], 50, message_y)
		message_y = message_y + self.terminal_font:getHeight() * 1.5
	end

	-- Draw progress bar
	local bar_width = love.graphics.getWidth() - 100
	local bar_height = 20
	local bar_x = 50
	local bar_y = love.graphics.getHeight() - 100

	-- Progress bar background
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle('fill', bar_x, bar_y, bar_width, bar_height)
	
	-- Progress bar fill
	love.graphics.setColor(0.2, 0.8, 0.2)
	love.graphics.rectangle('fill', bar_x, bar_y, bar_width * self.progress, bar_height)

	-- Progress percentage
	love.graphics.setColor(1, 1, 1)
	local percent = math.floor(self.progress * 100)
	local percent_text = string.format("Loading... %d%%", percent)
	love.graphics.print(percent_text, 
		bar_x + bar_width/2 - self.terminal_font:getWidth(percent_text)/2,
		bar_y + bar_height/2 - self.terminal_font:getHeight()/2)

	-- Fade out overlay
	if self.completed then
		love.graphics.setColor(0, 0, 0, self.fade_alpha)
		love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	end

	-- Draw skip button
	local skipX = love.graphics.getWidth() - self.skipButtonWidth - 20
	local skipY = 20
	
	if self.skipButtonHovered then
		love.graphics.setColor(0.3, 0.9, 0.3)
	else
		love.graphics.setColor(0.2, 0.8, 0.2)
	end
	
	love.graphics.rectangle('fill', skipX, skipY, self.skipButtonWidth, self.skipButtonHeight, 4, 4)
	love.graphics.setColor(0, 0, 0)
	local skipText = "Skip"
	love.graphics.print(skipText, 
		skipX + self.skipButtonWidth/2 - self.terminal_font:getWidth(skipText)/2,
		skipY + self.skipButtonHeight/2 - self.terminal_font:getHeight()/2)

	-- Restore graphics state
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(prevFont)
end

function BootSequence:mousepressed(x, y, button)
	if not self.active or button ~= 1 then return end
	
	local skipX = love.graphics.getWidth() - self.skipButtonWidth - 20
	local skipY = 20
	
	if x >= skipX and x <= skipX + self.skipButtonWidth and
	   y >= skipY and y <= skipY + self.skipButtonHeight then
		-- Stop boot sound
		if self.bootSound then
			self.bootSound:stop()
		end
		
		-- Set boot sequence as completed
		self.completed = true
		self.active = false
		
		-- Call onComplete callback if it exists
		if self.onComplete then
			self.onComplete()
		end
	end
end

function BootSequence:mousemoved(x, y)
	if not self.active then return end
	
	local skipX = love.graphics.getWidth() - self.skipButtonWidth - 20
	local skipY = 20
	
	self.skipButtonHovered = x >= skipX and x <= skipX + self.skipButtonWidth and
							y >= skipY and y <= skipY + self.skipButtonHeight
end

return BootSequence