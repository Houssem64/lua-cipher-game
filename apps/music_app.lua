local MusicApp = {
    config = {
        button_radius = 20,  -- Radius of the toggle button
        panel_width = 400,   -- Width of the sliding panel
        slide_speed = 1000,  -- Speed of the sliding animation
        button_color = {0.1176, 0.84313, 0.3764},  -- Purple color for the toggle button
        panel_color = {1, 1, 1, 0.9},  -- Semi-transparent white for the panel
        text_color = {0, 0, 0},        -- Black text for the panel
    }
}
MusicApp.__index = MusicApp

function MusicApp:new()
    local obj = setmetatable({}, MusicApp)

    -- Merge provided config with defaults
    obj.config = setmetatable({}, {__index = MusicApp.config})

    -- Initialize state using virtual resolution
    obj.gameWidth = 1920
    obj.gameHeight = 1080

    -- Toggle button properties
    obj.button = {
        x = obj.gameWidth - 60,  -- Position from the right edge
        y = 180,  -- Position from the top
        radius = obj.config.button_radius
    }

    -- Sliding panel properties
    obj.panel = {
        x = obj.gameWidth,  -- Start off-screen
        target_x = obj.gameWidth - obj.config.panel_width,  -- Target position when open
        y = 0,  -- Align with the top of the screen
        width = obj.config.panel_width,
        height = obj.gameHeight,
        visible = false  -- Panel starts closed
    }

    -- Playlist and song data
    obj.playlist = {
        {title = "Song 1", artist = "Artist 1", albumArt = "album1.png", audio = "song1.mp3"},
        {title = "Song 2", artist = "Artist 2", albumArt = "album2.png", audio = "song2.mp3"},
        {title = "Song 3", artist = "Artist 3", albumArt = "album3.png", audio = "song3.mp3"}
    }
    obj.currentSongIndex = 1
    obj.isPlaying = false
    obj.volume = 0.5

    -- UI elements
    obj.backgroundColor = {0.1, 0.1, 0.1}  -- Dark background like Spotify
    obj.textColor = {1, 1, 1}  -- White text
    obj.buttonColor = {0.3, 0.3, 0.3}  -- Gray buttons
    obj.activeColor = {0.2, 0.6, 1}  -- Spotify-like blue for active items
    obj.padding = 10
    obj.buttonSize = 40

    -- Audio source for the current song
    obj.currentAudioSource = nil

    -- Load the first song
    obj:loadSong(obj.currentSongIndex)

    return obj
end

function MusicApp:loadSong(index)
    -- Stop the current song if playing
    if self.currentAudioSource then
        self.currentAudioSource:stop()
    end

    -- Load the new song
    local song = self.playlist[index]
    self.currentAudioSource = love.audio.newSource(song.audio, "stream")
    self.currentAudioSource:setVolume(self.volume)

    -- Play the song if the app is in playing state
    if self.isPlaying then
        self.currentAudioSource:play()
    end
end

function MusicApp:playPause()
    self.isPlaying = not self.isPlaying
    if self.isPlaying then
        self.currentAudioSource:play()
    else
        self.currentAudioSource:pause()
    end
end

function MusicApp:nextSong()
    self.currentSongIndex = (self.currentSongIndex % #self.playlist) + 1
    self:loadSong(self.currentSongIndex)
end

function MusicApp:previousSong()
    self.currentSongIndex = self.currentSongIndex - 1
    if self.currentSongIndex < 1 then
        self.currentSongIndex = #self.playlist
    end
    self:loadSong(self.currentSongIndex)
end

function MusicApp:update(dt)
    -- Update sliding panel position
    if self.panel.visible then
        self.panel.x = math.max(self.panel.target_x, self.panel.x - self.config.slide_speed * dt)
    else
        self.panel.x = math.min(self.gameWidth, self.panel.x + self.config.slide_speed * dt)
    end

    -- Update playback logic
    if self.isPlaying and self.currentAudioSource and not self.currentAudioSource:isPlaying() then
        self:nextSong()  -- Automatically play the next song when the current one ends
    end
end

function MusicApp:draw(x, y, width, height)
    -- Store the window dimensions for use in other methods
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    local default_font = love.graphics.getFont()
    local font = love.graphics.newFont("joty.otf", 18)  -- Spotify-like font size
    font:setFilter("nearest", "nearest")  -- Crisp text
    love.graphics.setFont(font)

    -- Draw background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw sliding panel
    if self.panel.x < self.gameWidth then
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle("fill", self.panel.x, self.panel.y, self.panel.width, self.panel.height)

        -- Draw playlist in the sliding panel
        love.graphics.setColor(unpack(self.config.text_color))
        love.graphics.print("Playlist", self.panel.x + 10, self.panel.y + 10)

        local playlistY = self.panel.y + 50
        for i, song in ipairs(self.playlist) do
            if i == self.currentSongIndex then
                love.graphics.setColor(self.activeColor)  -- Highlight the current song
            else
                love.graphics.setColor(self.textColor)
            end
            love.graphics.print(song.title, self.panel.x + 10, playlistY)
            playlistY = playlistY + 30
        end
    end

    -- Draw toggle button
    love.graphics.setColor(unpack(self.config.button_color))
    love.graphics.circle("fill", self.button.x + self.button.radius, self.button.y + self.button.radius, self.button.radius)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("M", self.button.x + 12, self.button.y + 10)

    -- Reset font
    love.graphics.setFont(default_font)
end

function MusicApp:mousepressed(x, y, button)
    -- Handle toggle button click
    local dx = x - (self.button.x + self.button.radius)
    local dy = y - (self.button.y + self.button.radius)
    if dx * dx + dy * dy <= self.button.radius * self.button.radius then
        self.panel.visible = not self.panel.visible
        return true
    end

    -- Handle playlist item clicks
    if self.panel.visible and x >= self.panel.x and x <= self.panel.x + self.panel.width then
        local playlistY = self.panel.y + 50
        for i, song in ipairs(self.playlist) do
            if y >= playlistY and y <= playlistY + 30 then
                self.currentSongIndex = i
                self:loadSong(i)
                break
            end
            playlistY = playlistY + 30
        end
    end

    -- Handle playback controls (if needed)
    -- (You can add this logic here if you want to handle clicks on play/pause, next, previous buttons)
end

function MusicApp:keypressed(key)
    -- Handle shortcut keys
    if key == "f1" then
        self:previousSong()
    elseif key == "f2" then
        self:playPause()
    elseif key == "f3" then
        self:nextSong()
    end
end

return MusicApp