local RankAnimation = {}

local RANDOM_CHARS = "!@#$%^&*()_+-=[]{}|;:,.<>?/~`"

function RankAnimation:new()
	local obj = {
		active = false,
		text = "",
		revealed_text = "",
		cursor_pos = 1,
		time_per_char = 0.08,  -- Slightly faster
		time_since_last_char = 0,
		cursor_char = "",
		cursor_time = 0,
		cursor_blink_rate = 0.05,
		background_alpha = 0,
		text_alpha = 0,
		fade_in_time = 0.4,    -- Longer fade in
		hold_time = 2.5,       -- Longer hold
		fade_out_time = 0.7,   -- Longer fade out
		total_time = 0
	}
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
end

function RankAnimation:getRandomChar()
	return string.sub(RANDOM_CHARS, math.random(1, #RANDOM_CHARS), math.random(1, #RANDOM_CHARS))
end

function RankAnimation:update(dt)
	if not self.active then return end
	
	self.total_time = self.total_time + dt
	
	-- Fade in background
	if self.total_time < self.fade_in_time then
		self.background_alpha = self.total_time / self.fade_in_time
		self.text_alpha = self.background_alpha
	-- Reveal text
	elseif self.cursor_pos <= #self.text then
		self.time_since_last_char = self.time_since_last_char + dt
		if self.time_since_last_char >= self.time_per_char then
			self.revealed_text = string.sub(self.text, 1, self.cursor_pos)
			self.cursor_pos = self.cursor_pos + 1
			self.time_since_last_char = 0
		end
		
		-- Update cursor
		self.cursor_time = self.cursor_time + dt
		if self.cursor_time >= self.cursor_blink_rate then
			self.cursor_char = self:getRandomChar()
			self.cursor_time = 0
		end
	-- Hold complete text
	elseif self.total_time < self.fade_in_time + self.hold_time then
		self.background_alpha = 1
		self.text_alpha = 1
	-- Fade out
	elseif self.total_time < self.fade_in_time + self.hold_time + self.fade_out_time then
		local fade_progress = (self.total_time - (self.fade_in_time + self.hold_time)) / self.fade_out_time
		self.background_alpha = 1 - fade_progress
		self.text_alpha = 1 - fade_progress
	else
		self.active = false
	end
end

function RankAnimation:draw()
	if not self.active then return end
	
	-- Draw black background
	love.graphics.setColor(0, 0, 0, self.background_alpha * 0.85)
	love.graphics.rectangle('fill', 0, 0, 1920, 1080)
	
	-- Draw text with smaller font
	local font = love.graphics.newFont("fonts/FiraCode.ttf", 48)  -- Reduced from 72
	love.graphics.setFont(font)
	
	local display_text = self.revealed_text
	if self.cursor_pos <= #self.text then
		display_text = display_text .. self.cursor_char
	end
	
	local text_width = font:getWidth(display_text)
	local text_height = font:getHeight()
	
	-- Draw text outline
	love.graphics.setColor(0, 0, 0, self.text_alpha)
	for dx = -2, 2 do
		for dy = -2, 2 do
			love.graphics.print(display_text,
				960 - text_width/2 + dx,
				540 - text_height/2 + dy)
		end
	end
	
	-- Draw text in a brighter green
	love.graphics.setColor(0.4, 1, 0.2, self.text_alpha)
	love.graphics.print(display_text,
		960 - text_width/2,
		540 - text_height/2)
end

return RankAnimation