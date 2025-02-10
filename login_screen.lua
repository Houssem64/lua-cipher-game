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
	securityQuestion = "",
	securityAnswer = "",
	SaveSystem = require("modules/save_system")
}

function LoginScreen:drawAvatar(x, y, size)
    -- Draw circular background
    love.graphics.setColor(0.2, 0.2, 0.25, 1)
    love.graphics.circle('fill', x, y, size/2)
    
    -- Draw head
    love.graphics.setColor(0.8, 0.8, 0.85, 1)
    love.graphics.circle('fill', x, y - size/8, size/4)
    
    -- Draw body
    love.graphics.setColor(0.8, 0.8, 0.85, 1)
    love.graphics.circle('fill', x, y + size/4, size/3)
end

function LoginScreen:new(onLoginSuccess)
	local instance = setmetatable({}, { __index = LoginScreen })
	instance.username = ""
	instance.password = ""
	instance.selectedField = "username"
	instance.errorMessage = ""
	instance.active = false
	instance.cursorBlink = 0
	instance.showCursor = true
	instance.loginButtonHovered = false
	instance.isCreateMode = false
	instance.confirmPassword = ""
	instance.securityQuestion = ""
	instance.securityAnswer = ""
	instance.SaveSystem = require("modules/save_system")
	
	instance.font = love.graphics.newFont("fonts/FiraCode.ttf", 20)
	instance.startupSound = love.audio.newSource("sounds/startup.wav", "static")
	instance.onLoginSuccess = onLoginSuccess
	
	return instance
end


function LoginScreen:tryLogin()
	-- Clear any previous error message
	self.errorMessage = ""

	-- Validate empty fields first
	if self.username == "" or self.password == "" then
		self.errorMessage = "Username and password are required"
		return
	end

	if self.isCreateMode then
		if self.securityQuestion == "" or self.securityAnswer == "" then
			self.errorMessage = "All fields must be filled"
			return
		end
		if self.password ~= self.confirmPassword then
			self.errorMessage = "Passwords do not match"
			return
		end
		
		-- Save the credentials with security question
		local credentials = {
			username = self.username,
			password = self.password,
			security_question = self.securityQuestion,
			security_answer = self.securityAnswer
		}
		if self.SaveSystem:save(credentials, "user_credentials") then
			self.active = false
			if self.onLoginSuccess then
				self.onLoginSuccess(self.username)
			end
		else
			self.errorMessage = "Failed to save credentials"
		end
	elseif self.isResetMode then
		local savedCreds = self.SaveSystem:load("user_credentials")
		if not savedCreds then
			self.errorMessage = "No account found"
			return
		end
		
		if not savedCreds.security_answer then
			self.errorMessage = "Account data is corrupted"
			return
		end

		if self.resetAnswer:lower() == savedCreds.security_answer:lower() then
			if self.password == "" then
				self.errorMessage = "New password cannot be empty"
				return
			end
			if self.password ~= self.confirmPassword then
				self.errorMessage = "Passwords do not match"
				return
			end
			
			-- Update credentials with new password
			savedCreds.password = self.password
			if self.SaveSystem:save(savedCreds, "user_credentials") then
				self.isResetMode = false
				self.errorMessage = "Password reset successful"
				self.password = ""
				self.confirmPassword = ""
				self.resetAnswer = ""
			else
				self.errorMessage = "Failed to save new password"
			end
		else
			self.errorMessage = "Incorrect security answer"
		end
	else
		-- Normal login logic
		local savedCreds = self.SaveSystem:load("user_credentials")
		if not savedCreds then
			self.errorMessage = "No account exists. Please create one"
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
	self.securityQuestion = ""
	self.securityAnswer = ""
	
	-- Check if user exists
	local savedCreds = self.SaveSystem:load("user_credentials")
	self.isCreateMode = not savedCreds
	
	if self.startupSound then
		self.startupSound:play()
	end
end


function LoginScreen:keypressed(key)
	if not self.active then return end

	if key == "escape" and self.isResetMode then
		self.isResetMode = false
		self.password = ""
		self.confirmPassword = ""
		self.resetAnswer = ""
		return
	end

	if key == "tab" then
		if self.isCreateMode then
			if self.selectedField == "username" then
				self.selectedField = "password"
			elseif self.selectedField == "password" then
				self.selectedField = "confirm"
			elseif self.selectedField == "confirm" then
				self.selectedField = "question"
			elseif self.selectedField == "question" then
				self.selectedField = "answer"
			else
				self.selectedField = "username"
			end
		elseif self.isResetMode then
			if self.selectedField == "resetAnswer" then
				self.selectedField = "password"
			elseif self.selectedField == "password" then
				self.selectedField = "confirm"
			else
				self.selectedField = "resetAnswer"
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
			elseif self.selectedField == "confirm" then
				self.selectedField = "question"
			elseif self.selectedField == "question" then
				self.selectedField = "answer"
			else
				self:tryLogin()
			end
		elseif self.isResetMode then
			if self.selectedField == "resetAnswer" then
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
		elseif self.selectedField == "question" then
			self.securityQuestion = self.securityQuestion:sub(1, -2)
		elseif self.selectedField == "answer" then
			self.securityAnswer = self.securityAnswer:sub(1, -2)
		elseif self.selectedField == "resetAnswer" then
			self.resetAnswer = self.resetAnswer:sub(1, -2)
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
	elseif self.selectedField == "question" then
		self.securityQuestion = self.securityQuestion .. text
	elseif self.selectedField == "answer" then
		self.securityAnswer = self.securityAnswer .. text
	elseif self.selectedField == "resetAnswer" then
		self.resetAnswer = self.resetAnswer .. text
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

function LoginScreen:draw()
	if not self.active then return end

	local prevFont = love.graphics.getFont()
	love.graphics.setFont(self.font)

	-- Draw dark background
	love.graphics.setColor(0.08, 0.08, 0.12, 1)
	love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	local centerX = love.graphics.getWidth() / 2
	local centerY = love.graphics.getHeight() / 2
	local boxWidth = 320
	local boxHeight = self.isCreateMode and 300 or 200
	local padding = 25
	local fieldSpacing = 70
	local startY = centerY - 60




	-- Draw login box background with subtle shadow
	love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
	love.graphics.rectangle('fill', centerX - boxWidth/2 + 4, centerY - boxHeight/2 + 4, boxWidth, boxHeight)
	love.graphics.setColor(0.15, 0.15, 0.18, 1)
	love.graphics.rectangle('fill', centerX - boxWidth/2, centerY - boxHeight/2, boxWidth, boxHeight)

	-- Draw title
	love.graphics.setColor(0.9, 0.9, 0.95, 1)
	local title = self.isCreateMode and "Create Account" or "Login"
	love.graphics.print(title, centerX - self.font:getWidth(title)/2, centerY - boxHeight/2 + padding)

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

	-- Draw login/create button
	local buttonWidth = 120
	local buttonHeight = 35
	local buttonY = centerY + boxHeight/2 - buttonHeight - padding * 1.5

	if self.loginButtonHovered then
		love.graphics.setColor(0.25, 0.55, 0.25, 1)
	else
		love.graphics.setColor(0.2, 0.45, 0.2, 1)
	end
	love.graphics.rectangle('fill', centerX - buttonWidth/2, buttonY, buttonWidth, buttonHeight, 4, 4)

	-- Button text
	love.graphics.setColor(1, 1, 1, 1)
	local buttonText = self.isCreateMode and "Create" or "Login"
	love.graphics.print(buttonText, 
		centerX - self.font:getWidth(buttonText)/2, 
		buttonY + buttonHeight/2 - self.font:getHeight()/2)

	-- Draw error message
	if self.errorMessage and self.errorMessage ~= "" then
		love.graphics.setColor(1, 0.3, 0.3, 0.9)
		local errorX = centerX - boxWidth/2 + padding
		local errorY = centerY + boxHeight/2 + 5
		if self.font then
			love.graphics.print(self.errorMessage, errorX, errorY)
		end
	end

	-- Draw saved credentials box if user exists and not in create mode
	local savedCreds = self.SaveSystem:load("user_credentials")
	if savedCreds and not self.isCreateMode then
		local avatarSize = 80
		local avatarY = centerY + boxHeight/2 + 60
		
		-- Draw avatar
		self:drawAvatar(centerX, avatarY, avatarSize)
		
		-- Draw saved username with subtle glow
		love.graphics.setColor(1, 1, 1, 1)
		local savedUsername = savedCreds.username
		love.graphics.print(savedUsername, 
			centerX - self.font:getWidth(savedUsername)/2,
			avatarY + avatarSize/2 + 10)
	end

	love.graphics.setColor(1, 1, 1, 1)
	if prevFont then
		love.graphics.setFont(prevFont)
	end
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

	-- Check avatar click
	local savedCreds = self.SaveSystem:load("user_credentials")
	if savedCreds and not self.isCreateMode then
		local avatarSize = 80
		local avatarY = centerY + boxHeight/2 + 60
		
		-- Check if click is within avatar circle
		local dx = x - centerX
		local dy = y - avatarY
		if (dx * dx + dy * dy) <= (avatarSize/2) * (avatarSize/2) then
			self.username = savedCreds.username
			self.password = savedCreds.password
			self:tryLogin()
			return
		end
	end

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
	if self.isCreateMode and x >= centerX - boxWidth/2 + padding and x <= centerX + boxWidth/2 - padding and
	   y >= startY + fieldSpacing * 2 + 25 and y <= startY + fieldSpacing * 2 + 57 then
		self.selectedField = "confirm"
		return
	end

	-- Check security question field click in create mode
	if self.isCreateMode and x >= centerX - boxWidth/2 + padding and x <= centerX + boxWidth/2 - padding and
	   y >= startY + fieldSpacing * 3 + 25 and y <= startY + fieldSpacing * 3 + 57 then
		self.selectedField = "question"
		return
	end

	-- Check security answer field click in create mode
	if self.isCreateMode and x >= centerX - boxWidth/2 + padding and x <= centerX + boxWidth/2 - padding and
	   y >= startY + fieldSpacing * 4 + 25 and y <= startY + fieldSpacing * 4 + 57 then
		self.selectedField = "answer"
		return
	end

	-- Check reset answer field click in reset mode
	if self.isResetMode and x >= centerX - boxWidth/2 + padding and x <= centerX + boxWidth/2 - padding and
	   y >= startY + fieldSpacing + 25 and y <= startY + fieldSpacing + 57 then
		self.selectedField = "resetAnswer"
		return
	end

	-- Check reset password text click
	if not self.isCreateMode and not self.isResetMode then
		local resetText = "Forgot Password?"
		if resetText and self.font then
			local resetTextWidth = self.font:getWidth(resetText)
			if x >= centerX - resetTextWidth/2 and x <= centerX + resetTextWidth/2 and
			   y >= centerY + boxHeight/2 + 20 and y <= centerY + boxHeight/2 + 40 then
				self.isResetMode = true
				self.password = ""
				self.confirmPassword = ""
				self.resetAnswer = ""
				self.selectedField = "resetAnswer"
				self.errorMessage = ""
				return
			end
		end
	end

	-- Check button click
	local buttonWidth = 120
	local buttonHeight = 35
	local buttonY = centerY + boxHeight/2 - buttonHeight - padding * 1.5 + 25
	
	if x >= centerX - buttonWidth/2 and x <= centerX + buttonWidth/2 and
	   y >= buttonY and y <= buttonY + buttonHeight then
		self:tryLogin()
	end






end

function LoginScreen:mousemoved(x, y)
	if not self.active then return end

	local centerX = love.graphics.getWidth() / 2
	local centerY = love.graphics.getHeight() / 2
	local boxWidth = 320
	local boxHeight = self.isCreateMode and 300 or 250
	local padding = 25
	local buttonWidth = 120
	local buttonHeight = 35
	local buttonY = centerY + boxHeight/2 - buttonHeight - padding * 1.5 + 25


	-- Check if mouse is over login button
	self.loginButtonHovered = x >= centerX - buttonWidth/2 and x <= centerX + buttonWidth/2 and
							 y >= buttonY and y <= buttonY + buttonHeight



end

return LoginScreen