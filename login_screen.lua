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

	-- Draw dark background
	love.graphics.setColor(0.1, 0.1, 0.1, 1)
	love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	local centerX = love.graphics.getWidth() / 2
	local centerY = love.graphics.getHeight() / 2
	local boxWidth = 300
	local boxHeight = self.isCreateMode and 250 or 200
	local padding = 20

	-- Draw login box background
	love.graphics.setColor(0.2, 0.2, 0.2, 1)
	love.graphics.rectangle('fill', centerX - boxWidth/2, centerY - boxHeight/2, boxWidth, boxHeight)

	-- Draw title
	love.graphics.setColor(0.8, 0.8, 0.8, 1)
	local title = self.isCreateMode and "Create Account" or "Login"
	love.graphics.print(title, centerX - self.font:getWidth(title)/2, centerY - boxHeight/2 + padding)

	-- Draw username field
	love.graphics.setColor(0.8, 0.8, 0.8, 1)
	love.graphics.print("Username:", centerX - boxWidth/2 + padding, centerY - 50)
	love.graphics.setColor(0.15, 0.15, 0.15, 1)
	love.graphics.rectangle('fill', centerX - boxWidth/2 + padding, centerY - 25, boxWidth - padding*2, 30)
	love.graphics.setColor(1, 1, 1, 1)
	local usernameText = self.username .. (self.selectedField == "username" and self.showCursor and "_" or "")
	love.graphics.print(usernameText, centerX - boxWidth/2 + padding + 5, centerY - 20)

	-- Draw password field
	love.graphics.setColor(0.8, 0.8, 0.8, 1)
	love.graphics.print("Password:", centerX - boxWidth/2 + padding, centerY + 10)
	love.graphics.setColor(0.15, 0.15, 0.15, 1)
	love.graphics.rectangle('fill', centerX - boxWidth/2 + padding, centerY + 35, boxWidth - padding*2, 30)
	love.graphics.setColor(1, 1, 1, 1)
	local passwordDisplay = string.rep("*", #self.password) .. (self.selectedField == "password" and self.showCursor and "_" or "")
	love.graphics.print(passwordDisplay, centerX - boxWidth/2 + padding + 5, centerY + 40)

	-- Draw confirm password field if in create mode
	if self.isCreateMode then
		love.graphics.setColor(0.8, 0.8, 0.8, 1)
		love.graphics.print("Confirm:", centerX - boxWidth/2 + padding, centerY + 70)
		love.graphics.setColor(0.15, 0.15, 0.15, 1)
		love.graphics.rectangle('fill', centerX - boxWidth/2 + padding, centerY + 95, boxWidth - padding*2, 30)
		love.graphics.setColor(1, 1, 1, 1)
		local confirmDisplay = string.rep("*", #self.confirmPassword) .. (self.selectedField == "confirm" and self.showCursor and "_" or "")
		love.graphics.print(confirmDisplay, centerX - boxWidth/2 + padding + 5, centerY + 100)
	end

	-- Draw button
	local buttonY = centerY + boxHeight/2 - 35
	if self.loginButtonHovered then
		love.graphics.setColor(0.3, 0.6, 0.3, 1)
	else
		love.graphics.setColor(0.2, 0.5, 0.2, 1)
	end
	love.graphics.rectangle('fill', centerX - 50, buttonY, 100, 30)
	love.graphics.setColor(1, 1, 1, 1)
	local buttonText = self.isCreateMode and "Create" or "Login"
	love.graphics.print(buttonText, 
		centerX - self.font:getWidth(buttonText)/2, 
		buttonY + 15 - self.font:getHeight()/2)

	-- Draw error message if any
	if self.errorMessage ~= "" then
		love.graphics.setColor(1, 0.3, 0.3, 1)
		love.graphics.print(self.errorMessage, centerX - boxWidth/2 + padding, centerY + boxHeight/2 + 10)
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(prevFont)
end

function LoginScreen:mousepressed(x, y, button)
	if not self.active or button ~= 1 then return end

	local centerX = love.graphics.getWidth() / 2
	local centerY = love.graphics.getHeight() / 2
	local boxWidth = 300
	local boxHeight = 200
	local padding = 20

	-- Check username field click
	local usernameY = centerY - 25
	if x >= centerX - boxWidth/2 + padding and x <= centerX + boxWidth/2 - padding and
	   y >= usernameY and y <= usernameY + 30 then
		self.selectedField = "username"
		return
	end

	-- Check password field click
	local passwordY = centerY + 35
	if x >= centerX - boxWidth/2 + padding and x <= centerX + boxWidth/2 - padding and
	   y >= passwordY and y <= passwordY + 30 then
		self.selectedField = "password"
		return
	end

	-- Check login button click
	local buttonY = centerY + boxHeight/2 - 35
	if x >= centerX - 50 and x <= centerX + 50 and
	   y >= buttonY and y <= buttonY + 30 then
		self:tryLogin()
	end
end

function LoginScreen:mousemoved(x, y)
	if not self.active then return end

	local centerX = love.graphics.getWidth() / 2
	local centerY = love.graphics.getHeight() / 2
	local boxHeight = 200
	local buttonY = centerY + boxHeight/2 - 35

	-- Check if mouse is over login button
	self.loginButtonHovered = x >= centerX - 50 and x <= centerX + 50 and
							 y >= buttonY and y <= buttonY + 30
end

return LoginScreen