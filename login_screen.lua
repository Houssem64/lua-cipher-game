local LoginScreen = {
	startupSound = nil,
	username = "",
	password = "",
	selectedField = "username",
	errorMessage = "",
	active = false,
	font = nil,
	cursorBlink = 0,
	showCursor = true,
	onLoginSuccess = nil,
	loginButtonHovered = false,
	isCreateMode = false,
	confirmPassword = "",
	SaveSystem = require("modules/save_system")
}

function LoginScreen:new(onLoginSuccess)
	local instance = setmetatable({}, { __index = LoginScreen })
	instance.font = love.graphics.newFont("fonts/FiraCode.ttf", 20)
	instance.startupSound = love.audio.newSource("sounds/startup.wav", "static")
	instance.onLoginSuccess = onLoginSuccess
	return instance
end

function LoginScreen:tryLogin()
	if self.isCreateMode then
		if self.username == "" or self.password == "" then
			self.errorMessage = "Username and password cannot be empty"
			return
		end
		if self.password ~= self.confirmPassword then
			self.errorMessage = "Passwords do not match"
			return
		end
		
		-- Save the credentials
		local credentials = {
			username = self.username,
			password = self.password
		}
		if self.SaveSystem:save(credentials, "user_credentials") then
			self.active = false
			if self.onLoginSuccess then
				self.onLoginSuccess(self.username)
			end
		else
			self.errorMessage = "Failed to save credentials"
		end
	else
		-- Load saved credentials
		local savedCreds = self.SaveSystem:load("user_credentials")
		if not savedCreds then
			self.errorMessage = "Invalid credentials"
			return
		end
		
		if self.username == savedCreds.username and self.password == savedCreds.password then
			self.active = false
			if self.onLoginSuccess then
				self.onLoginSuccess(self.username)
			end
		else
			self.errorMessage = "Invalid credentials"
		end
	end
end

function LoginScreen:start()
	self.active = true
	self.username = ""
	self.password = ""
	self.confirmPassword = ""
	self.errorMessage = ""
	
	-- Check if user exists
	local savedCreds = self.SaveSystem:load("user_credentials")
	self.isCreateMode = not savedCreds
	
	if self.startupSound then
		self.startupSound:play()
	end
end


function LoginScreen:update(dt)
	if not self.active then return end
	
	-- Update cursor blink
	self.cursorBlink = self.cursorBlink + dt
	if self.cursorBlink >= 0.5 then
		self.cursorBlink = 0
		self.showCursor = not self.showCursor
	end
end

function LoginScreen:keypressed(key)
	if not self.active then return end

	if key == "tab" then
		if self.isCreateMode then
			if self.selectedField == "username" then
				self.selectedField = "password"
			elseif self.selectedField == "password" then
				self.selectedField = "confirm"
			else
				self.selectedField = "username"
			end
		else
			self.selectedField = self.selectedField == "username" and "password" or "username"
		end
	elseif key == "return" then
		if self.isCreateMode then
			if self.selectedField == "username" then
				self.selectedField = "password"
			elseif self.selectedField == "password" then
				self.selectedField = "confirm"
			else
				self:tryLogin()
			end
		else
			if self.selectedField == "username" then
				self.selectedField = "password"
			else
				self:tryLogin()
			end
		end
	elseif key == "backspace" then
		if self.selectedField == "username" then
			self.username = self.username:sub(1, -2)
		elseif self.selectedField == "password" then
			self.password = self.password:sub(1, -2)
		elseif self.selectedField == "confirm" then
			self.confirmPassword = self.confirmPassword:sub(1, -2)
		end
	end
end

function LoginScreen:textinput(text)
	if not self.active then return end
	
	if self.selectedField == "username" then
		self.username = self.username .. text
	elseif self.selectedField == "password" then
		self.password = self.password .. text
	elseif self.selectedField == "confirm" then
		self.confirmPassword = self.confirmPassword .. text
	end
end

function LoginScreen:draw()
	if not self.active then return end

	local prevFont = love.graphics.getFont()
	love.graphics.setFont(self.font)

	-- Draw dark background with gradient effect
	love.graphics.setColor(0.08, 0.08, 0.12, 1)
	love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	local centerX = love.graphics.getWidth() / 2
	local centerY = love.graphics.getHeight() / 2
	local boxWidth = 320
	local boxHeight = self.isCreateMode and 300 or 250
	local padding = 25

	-- Draw login box background with subtle shadow effect
	love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
	love.graphics.rectangle('fill', centerX - boxWidth/2 + 4, centerY - boxHeight/2 + 4, boxWidth, boxHeight)
	love.graphics.setColor(0.15, 0.15, 0.18, 1)
	love.graphics.rectangle('fill', centerX - boxWidth/2, centerY - boxHeight/2, boxWidth, boxHeight)

	-- Draw title with subtle highlight
	love.graphics.setColor(0.9, 0.9, 0.95, 1)
	local title = self.isCreateMode and "Create Account" or "Login"
	love.graphics.print(title, centerX - self.font:getWidth(title)/2, centerY - boxHeight/2 + padding)

	-- Draw fields with consistent spacing
	local fieldSpacing = 70
	local startY = centerY - 60

	-- Username field
	love.graphics.setColor(0.8, 0.8, 0.85, 1)
	love.graphics.print("Username:", centerX - boxWidth/2 + padding, startY)
	love.graphics.setColor(0.12, 0.12, 0.15, 1)
	love.graphics.rectangle('fill', centerX - boxWidth/2 + padding, startY + 25, boxWidth - padding*2, 32)
	love.graphics.setColor(1, 1, 1, 1)
	local usernameText = self.username .. (self.selectedField == "username" and self.showCursor and "_" or "")
	love.graphics.print(usernameText, centerX - boxWidth/2 + padding + 5, startY + 30)

	-- Password field
	love.graphics.setColor(0.8, 0.8, 0.85, 1)
	love.graphics.print("Password:", centerX - boxWidth/2 + padding, startY + fieldSpacing)
	love.graphics.setColor(0.12, 0.12, 0.15, 1)
	love.graphics.rectangle('fill', centerX - boxWidth/2 + padding, startY + fieldSpacing + 25, boxWidth - padding*2, 32)
	love.graphics.setColor(1, 1, 1, 1)
	local passwordDisplay = string.rep("*", #self.password) .. (self.selectedField == "password" and self.showCursor and "_" or "")
	love.graphics.print(passwordDisplay, centerX - boxWidth/2 + padding + 5, startY + fieldSpacing + 30)

	-- Confirm password field if in create mode
	if self.isCreateMode then
		love.graphics.setColor(0.8, 0.8, 0.85, 1)
		love.graphics.print("Confirm Password:", centerX - boxWidth/2 + padding, startY + fieldSpacing * 2)
		love.graphics.setColor(0.12, 0.12, 0.15, 1)
		love.graphics.rectangle('fill', centerX - boxWidth/2 + padding, startY + fieldSpacing * 2 + 25, boxWidth - padding*2, 32)
		love.graphics.setColor(1, 1, 1, 1)
		local confirmDisplay = string.rep("*", #self.confirmPassword) .. (self.selectedField == "confirm" and self.showCursor and "_" or "")
		love.graphics.print(confirmDisplay, centerX - boxWidth/2 + padding + 5, startY + fieldSpacing * 2 + 30)
	end

	-- Draw button with more space and better hover effect
	local buttonWidth = 120
	local buttonHeight = 35
	local buttonY = centerY + boxHeight/2 - buttonHeight - padding * 1.5 +25
	
	if self.loginButtonHovered then
		love.graphics.setColor(0.25, 0.55, 0.25, 1)
	else
		love.graphics.setColor(0.2, 0.45, 0.2, 1)
	end
	love.graphics.rectangle('fill', centerX - buttonWidth/2, buttonY, buttonWidth, buttonHeight, 4, 4)
	
	-- Button highlight effect
	if self.loginButtonHovered then
		love.graphics.setColor(0.3, 0.6, 0.3, 0.2)
		love.graphics.rectangle('fill', centerX - buttonWidth/2, buttonY, buttonWidth, buttonHeight, 4, 4)
	end
	
	love.graphics.setColor(1, 1, 1, 1)
	local buttonText = self.isCreateMode and "Create" or "Login"
	love.graphics.print(buttonText, 
		centerX - self.font:getWidth(buttonText)/2, 
		buttonY + buttonHeight/2 - self.font:getHeight()/2)

	-- Draw error message with fade effect
	if self.errorMessage ~= "" then
		love.graphics.setColor(1, 0.3, 0.3, 0.9)
		love.graphics.print(self.errorMessage, centerX - boxWidth/2 + padding, centerY + boxHeight/2 + 5)
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(prevFont)
end

function LoginScreen:mousepressed(x, y, button)
	if not self.active or button ~= 1 then return end

	local centerX = love.graphics.getWidth() / 2
	local centerY = love.graphics.getHeight() / 2
	local boxWidth = 320
	local boxHeight = self.isCreateMode and 300 or 250
	local padding = 25
	local fieldSpacing = 70
	local startY = centerY - 60

	-- Check username field click
	if x >= centerX - boxWidth/2 + padding and x <= centerX + boxWidth/2 - padding and
	   y >= startY + 25 and y <= startY + 57 then
		self.selectedField = "username"
		return
	end

	-- Check password field click
	if x >= centerX - boxWidth/2 + padding and x <= centerX + boxWidth/2 - padding and
	   y >= startY + fieldSpacing + 25 and y <= startY + fieldSpacing + 57 then
		self.selectedField = "password"
		return
	end

	-- Check confirm password field click in create mode
	if self.isCreateMode then
		if x >= centerX - boxWidth/2 + padding and x <= centerX + boxWidth/2 - padding and
		   y >= startY + fieldSpacing * 2 + 25 and y <= startY + fieldSpacing * 2 + 57 then
			self.selectedField = "confirm"
			return
		end
	end

	-- Check button click
	local buttonWidth = 120
	local buttonHeight = 35
	local buttonY = centerY + boxHeight/2 - buttonHeight - padding * 1.5+25
	
	if x >= centerX - buttonWidth/2 and x <= centerX + buttonWidth/2 and
	   y >= buttonY and y <= buttonY + buttonHeight then
		self:tryLogin()
	end
end

function LoginScreen:mousemoved(x, y)
	if not self.active then return end

	local centerX = love.graphics.getWidth() / 2
	local centerY = love.graphics.getHeight() / 2
	local boxHeight = self.isCreateMode and 300 or 250
	local padding = 25
	local buttonWidth = 120
	local buttonHeight = 35
	local buttonY = centerY + boxHeight/2 - buttonHeight - padding * 1.5+25

	-- Check if mouse is over login button
	self.loginButtonHovered = x >= centerX - buttonWidth/2 and x <= centerX + buttonWidth/2 and
							 y >= buttonY and y <= buttonY + buttonHeight
end

return LoginScreen