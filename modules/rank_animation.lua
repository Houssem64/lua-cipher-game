local RankAnimation = {}

local RANDOM_CHARS = "!@#$%^&*()_+-=[]{}|;:,.<>?/~`"

function RankAnimation:new()
	local obj = {
		active = false,
		text = "",
		revealed_text = "",
		cursor_pos = 1,
		time_per_char = 0.08,
		time_since_last_char = 0,
		cursor_char = "",
		cursor_time = 0,
		cursor_blink_rate = 0.05,
		background_alpha = 0,
		text_alpha = 0,
		fade_in_time = 0.5,    -- 0.5s fade in
		hold_time = 3.0,       -- 3.0s hold (including text reveal)
		fade_out_time = 0.5,   -- 0.5s fade out
		total_time = 0,
		scale = 0.8,
		char_scale = 1.0,
		rank_up_sound = nil
	}
	
	-- Load rank up sound
	local success, result = pcall(function()
		return love.audio.newSource("sounds/rankup.mp3", "static")
	end)
	if success then
		obj.rank_up_sound = result
		print("Successfully loaded rank up sound")
	else
		print("Failed to load rank up sound:", result)
	end
	
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function RankAnimation:start(text)
	self.active = true
	self.text = text
	self.revealed_text = ""
	self.cursor_pos = 1
	self.time_since_last_char = 0
	self.cursor_char = self:getRandomChar()
	self.cursor_time = 0
	self.background_alpha = 0
	self.text_alpha = 0
	self.total_time = 0
	self.scale = 0.8  -- Initialize scale
	
	-- Play rank up sound
	if self.rank_up_sound then
		self.rank_up_sound:stop()  -- Stop if already playing
		self.rank_up_sound:setVolume(0.5)  -- Set volume to 50%
		self.rank_up_sound:play()
	end
end

function RankAnimation:getRandomChar()
	-- Return just one random character
	local index = math.random(1, #RANDOM_CHARS)
	return string.sub(RANDOM_CHARS, index, index)
end

function RankAnimation:update(dt)
	if not self.active then return end
	
	self.total_time = self.total_time + dt
	
	if self.total_time < self.fade_in_time then
		local progress = self.total_time / self.fade_in_time
		self.background_alpha = progress
		self.text_alpha = progress
		self.scale = 0.8 + (0.2 * progress)
	elseif self.cursor_pos <= #self.text then
		self.time_since_last_char = self.time_since_last_char + dt
		if self.time_since_last_char >= self.time_per_char then
			-- Add one character at a time with scale effect
			self.revealed_text = string.sub(self.text, 1, self.cursor_pos)
			self.cursor_pos = self.cursor_pos + 1
			self.time_since_last_char = 0
			self.char_scale = 1.2  -- Pop effect when revealing new character
			
			-- Play a softer sound effect for each character reveal
			if self.rank_up_sound then
				local char_sound = self.rank_up_sound:clone()
				if char_sound then
					char_sound:setVolume(0.1)
					char_sound:setPitch(1.5)
					char_sound:play()
				end
			end
			
			-- Get new random cursor character
			self.cursor_char = self:getRandomChar()
		end
		
		-- Smooth out character scale
		self.char_scale = self.char_scale + (1.0 - self.char_scale) * dt * 10
		
		-- Update cursor blink
		self.cursor_time = self.cursor_time + dt
		if self.cursor_time >= self.cursor_blink_rate then
			self.cursor_char = self:getRandomChar()
			self.cursor_time = 0
		end
	elseif self.total_time < self.fade_in_time + self.hold_time then
		self.background_alpha = 1
		self.text_alpha = 1
		self.scale = 1 + math.sin(self.total_time * 3) * 0.05
	elseif self.total_time < 4.0 then  -- Ensure total duration is exactly 4 seconds
		local fade_progress = (self.total_time - (self.fade_in_time + self.hold_time)) / self.fade_out_time
		self.background_alpha = 1 - fade_progress
		self.text_alpha = 1 - fade_progress
		self.scale = 1 + (0.2 * fade_progress)
	else
		self.active = false
	end
end

function RankAnimation:keypressed(key)
	-- Allow dismissing the animation with any key press
	if self.active and self.cursor_pos > #self.text then
		self.active = false
		return true
	end
	return false
end

function RankAnimation:draw()
	if not self.active then return end
	
	-- Create a dark overlay with pulsing effect
	local pulseAlpha = self.background_alpha * (0.85 + math.sin(love.timer.getTime() * 4) * 0.05)
	love.graphics.setColor(0, 0, 0, pulseAlpha)
	love.graphics.rectangle('fill', 0, 0, 1920, 1080)
	
	-- Draw animated particles in background
	if not self.particles then
		self.particles = {}
		for i = 1, 50 do
			table.insert(self.particles, {
				x = math.random(0, 1920),
				y = math.random(0, 1080),
				size = math.random(2, 8),
				speed = math.random(20, 100),
				angle = math.random() * math.pi * 2,
				color = {
					r = 0.2 + math.random() * 0.4,
					g = 0.6 + math.random() * 0.4,
					b = 0.2 + math.random() * 0.2,
					a = math.random() * 0.5
				}
			})
		end
	end
	
	-- Update and draw particles
	for _, particle in ipairs(self.particles) do
		-- Update position
		particle.x = particle.x + math.cos(particle.angle) * particle.speed * 0.01
		particle.y = particle.y + math.sin(particle.angle) * particle.speed * 0.01
		
		-- Wrap around screen
		if particle.x < 0 then particle.x = 1920 end
		if particle.x > 1920 then particle.x = 0 end
		if particle.y < 0 then particle.y = 1080 end
		if particle.y > 1080 then particle.y = 0 end
		
		-- Draw particle with pulsing effect
		local pulse = 0.7 + math.sin(love.timer.getTime() * 3 + particle.x * 0.01) * 0.3
		love.graphics.setColor(
			particle.color.r, 
			particle.color.g, 
			particle.color.b, 
			particle.color.a * self.text_alpha * pulse
		)
		love.graphics.circle('fill', particle.x, particle.y, particle.size * pulse)
	end
	
	local font = love.graphics.newFont("fonts/FiraCode.ttf", 48)
	love.graphics.setFont(font)
	
	local display_text = self.revealed_text
	if self.cursor_pos <= #self.text then
		display_text = display_text .. self.cursor_char
	end
	
	local text_width = font:getWidth(display_text)
	local text_height = font:getHeight()
	
	-- Save current transform
	love.graphics.push()
	
	-- Move to center, scale, then move back
	love.graphics.translate(960, 540)
	love.graphics.scale(self.scale, self.scale)
	love.graphics.translate(-960, -540)
	
	-- Draw animated ring around text
	local ringRadius = 150 + math.sin(love.timer.getTime() * 3) * 10
	local segments = 36
	for i = 1, segments do
		local angle = (i / segments) * math.pi * 2
		local nextAngle = ((i + 1) / segments) * math.pi * 2
		
		local x1 = 960 + math.cos(angle + love.timer.getTime()) * ringRadius
		local y1 = 540 + math.sin(angle + love.timer.getTime()) * ringRadius
		local x2 = 960 + math.cos(nextAngle + love.timer.getTime()) * ringRadius
		local y2 = 540 + math.sin(nextAngle + love.timer.getTime()) * ringRadius
		
		love.graphics.setColor(0.4, 0.8, 0.2, self.text_alpha * 0.5 * (0.5 + math.sin(angle * 3 + love.timer.getTime() * 2) * 0.5))
		love.graphics.setLineWidth(3)
		love.graphics.line(x1, y1, x2, y2)
	end
	love.graphics.setLineWidth(1)
	
	-- Draw glow effect
	love.graphics.setColor(0.4, 0.8, 0.2, self.text_alpha * 0.3)
	for i = 1, 3 do
		local glow_size = i * 2
		love.graphics.print(display_text,
			960 - text_width/2 - glow_size,
			540 - text_height/2)
		love.graphics.print(display_text,
			960 - text_width/2 + glow_size,
			540 - text_height/2)
		love.graphics.print(display_text,
			960 - text_width/2,
			540 - text_height/2 - glow_size)
		love.graphics.print(display_text,
			960 - text_width/2,
			540 - text_height/2 + glow_size)
	end
	
	-- Draw text outline
	love.graphics.setColor(0, 0, 0, self.text_alpha)
	for dx = -2, 2 do
		for dy = -2, 2 do
			love.graphics.print(display_text,
				960 - text_width/2 + dx,
				540 - text_height/2 + dy)
		end
	end
	
	-- Draw main text with color cycling
	local r = 0.4 + math.sin(love.timer.getTime() * 1.5) * 0.1
	local g = 1.0
	local b = 0.2 + math.cos(love.timer.getTime() * 1.5) * 0.1
	love.graphics.setColor(r, g, b, self.text_alpha)
	love.graphics.print(display_text,
		960 - text_width/2,
		540 - text_height/2)
	
	-- Draw sparkles around text when fully revealed
	if self.cursor_pos > #self.text then
		for i = 1, 8 do
			local angle = love.timer.getTime() * 2 + (i / 8) * math.pi * 2
			local distance = 80 + math.sin(love.timer.getTime() * 3 + i) * 20
			local x = 960 + math.cos(angle) * distance
			local y = 540 + math.sin(angle) * distance
			local size = 4 + math.sin(love.timer.getTime() * 5 + i * 0.5) * 2
			
			love.graphics.setColor(1, 1, 0.5, self.text_alpha * (0.5 + math.sin(love.timer.getTime() * 3 + i) * 0.5))
			love.graphics.circle('fill', x, y, size)
			
			-- Draw star shape
			for j = 1, 4 do
				local rayAngle = angle + (j / 4) * math.pi * 2
				local rayLength = size * 2
				love.graphics.line(
					x, y,
					x + math.cos(rayAngle) * rayLength,
					y + math.sin(rayAngle) * rayLength
				)
			end
		end
	end
	
	-- Restore previous transform
	love.graphics.pop()

	-- Draw "Press any key to continue" text when animation is complete
	if self.cursor_pos > #self.text and self.total_time > 2.0 then
		local continueFont = love.graphics.newFont("fonts/FiraCode.ttf", 24)
		love.graphics.setFont(continueFont)
		local continueText = "Press any key to continue"
		local continueWidth = continueFont:getWidth(continueText)
		
		-- Pulsing effect
		local pulse = 0.7 + math.sin(love.timer.getTime() * 2) * 0.3
		love.graphics.setColor(1, 1, 1, self.text_alpha * pulse)
		love.graphics.print(continueText, 
			960 - continueWidth/2,
			650)
	end
end

return RankAnimation