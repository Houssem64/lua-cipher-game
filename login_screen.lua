local LoginScreen = {
	startupSound = nil,
	username = "",
	password = "",
	selectedField = "username", -- "username" or "password"
	errorMessage = "",
	active = false,
	font = nil,
	cursorBlink = 0,
	showCursor = true,
	onLoginSuccess = nil, -- Callback for successful login
	loginButtonHovered = false
}

function LoginScreen:new(onLoginSuccess)
	local instance = setmetatable({}, { __index = LoginScreen })
	instance.font = love.graphics.newFont("fonts/FiraCode.ttf", 20)
	instance.startupSound = love.audio.newSource("sounds/startup.wav", "static")
	instance.onLoginSuccess = onLoginSuccess
	return instance
end

-- Add login validation function
function LoginScreen:tryLogin()
	-- Simple validation for demo (you can add more complex validation)
	if self.username == "" then
		self.errorMessage = "Username cannot be empty"
		return
	end
	if self.password == "" then
		self.errorMessage = "Password cannot be empty"
		return
	end
	
	-- For demo purposes, accept any non-empty username/password
	self.active = false
	if self.onLoginSuccess then
		self.onLoginSuccess(self.username)
	end
end

function LoginScreen:start()
	self.active = true
	self.username = ""
	self.password = ""
	self.errorMessage = ""
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
		self.selectedField = self.selectedField == "username" and "password" or "username"
	elseif key == "return" then
		if self.selectedField == "username" then
			self.selectedField = "password"
		else
			self:tryLogin()
		end
	elseif key == "backspace" then
		if self.selectedField == "username" then
			self.username = self.username:sub(1, -2)
		else
			self.password = self.password:sub(1, -2)
		end
	end
end

function LoginScreen:textinput(text)
	if not self.active then return end
	
	if self.selectedField == "username" then
		self.username = self.username .. text
	else
		self.password = self.password .. text
	end
end

function LoginScreen:draw()
	if not self.active then return end

	-- Save current graphics state
	local prevFont = love.graphics.getFont()
	love.graphics.setFont(self.font)

	-- Draw dark background
	love.graphics.setColor(0.1, 0.1, 0.1, 1)
	love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	-- Draw login form
	local centerX = love.graphics.getWidth() / 2
	local centerY = love.graphics.getHeight() / 2
	local boxWidth = 300
	local boxHeight = 200
	local padding = 20

	-- Draw login box background
	love.graphics.setColor(0.2, 0.2, 0.2, 1)
	love.graphics.rectangle('fill', centerX - boxWidth/2, centerY - boxHeight/2, boxWidth, boxHeight)

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

	-- Draw login button
	local buttonY = centerY + boxHeight/2 - 35
	if self.loginButtonHovered then
		love.graphics.setColor(0.3, 0.6, 0.3, 1)
	else
		love.graphics.setColor(0.2, 0.5, 0.2, 1)
	end
	love.graphics.rectangle('fill', centerX - 50, buttonY, 100, 30)
	love.graphics.setColor(1, 1, 1, 1)
	local loginText = "Login"
	love.graphics.print(loginText, 
		centerX - self.font:getWidth(loginText)/2, 
		buttonY + 15 - self.font:getHeight()/2)

	-- Draw error message if any
	if self.errorMessage ~= "" then
		love.graphics.setColor(1, 0.3, 0.3, 1)
		love.graphics.print(self.errorMessage, centerX - boxWidth/2 + padding, centerY + boxHeight/2 + 10)
	end

	-- Restore graphics state
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