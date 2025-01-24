local MusicApp = {
    config = {
        button_radius = 20,  -- Radius of the toggle button
        panel_width = 400,   -- Width of the sliding panel
        slide_speed = 1000,  -- Speed of the sliding animation
        button_color = {0.1176, 0.84313, 0.3764},  -- Green color for the toggle button
        panel_color = {0.1333, 0.1333, 0.1333, 1},  -- Dark background for the panel
        text_color = {1, 1, 1},  -- White text for the panel
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
        {title = "Song 1", artist = "Artist 1", albumArt = "album1.jpg", audio = "song1.mp3"},
        {title = "Song 2", artist = "Artist 2", albumArt = "album2.jpg", audio = "song2.mp3"},
        {title = "Song 3", artist = "Artist 3", albumArt = "album3.jpg", audio = "song3.mp3"}
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


    -- Draw sliding panel
    if self.panel.x < self.gameWidth then
        love.graphics.setColor(unpack(self.config.panel_color))
        love.graphics.rectangle("fill", self.panel.x, self.panel.y, self.panel.width, self.panel.height)

        -- Draw album art
        local albumArtSize = 150
        local albumArtX = self.panel.x + (self.panel.width - albumArtSize) / 2
        local albumArtY = self.panel.y + 20

        local albumArtPath = self.playlist[self.currentSongIndex].albumArt
        local albumArt = love.graphics.newImage(albumArtPath)
        love.graphics.setColor(1, 1, 1, 0.6)  -- Slightly transparent

        love.graphics.draw(albumArt, albumArtX, albumArtY, 0, albumArtSize / albumArt:getWidth(), albumArtSize / albumArt:getHeight())

        -- Draw volume bar (vertical)
        local volumeBarWidth = 10  -- Width of the volume bar
        local volumeBarHeight = albumArtSize  -- Height of the volume bar (matches album art height)
        local volumeBarX = albumArtX - volumeBarWidth - 20  -- Position to the left of the album art
        local volumeBarY = albumArtY

        -- Draw the volume bar background
        love.graphics.setColor(0.2, 0.2, 0.2)  -- Dark gray background
        love.graphics.rectangle("fill", volumeBarX, volumeBarY, volumeBarWidth, volumeBarHeight)

        -- Draw the current volume level
        love.graphics.setColor(0.2, 0.6, 1)  -- Spotify-like blue for the volume level
        local volumeLevelHeight = volumeBarHeight * self.volume
        love.graphics.rectangle("fill", volumeBarX, volumeBarY + (volumeBarHeight - volumeLevelHeight), volumeBarWidth, volumeLevelHeight)

        -- Draw the volume handle (draggable circle)
        local handleRadius = 8
        local handleX = volumeBarX + volumeBarWidth / 2
        local handleY = volumeBarY + (volumeBarHeight - volumeLevelHeight)
        love.graphics.setColor(1, 1, 1)  -- White handle
        love.graphics.circle("fill", handleX, handleY, handleRadius)

        -- Draw playback controls
        local controlsY = albumArtY + albumArtSize + 20
        local totalButtonsWidth = self.buttonSize * 3 + 20 * 2  -- Width of all buttons including spacing
        local playPauseX = self.panel.x + (self.panel.width - totalButtonsWidth) / 2 + 60

        -- Previous button
        local prevButtonX = playPauseX - self.buttonSize - 20
        local prevButtonY = controlsY
        local outlinePadding = 5  -- Padding around the button for the outline

        -- Draw outline for Previous button
        love.graphics.setColor(1, 1, 1)  -- White outline
        love.graphics.rectangle("line", prevButtonX - outlinePadding, prevButtonY - outlinePadding,
                               self.buttonSize + 2 * outlinePadding, self.buttonSize + 2 * outlinePadding)

        -- Draw Previous button
        love.graphics.setColor(0.3, 0.3, 0.3)  -- Gray color for the button
        love.graphics.polygon("fill", prevButtonX, prevButtonY + self.buttonSize / 2,
                              prevButtonX + self.buttonSize, prevButtonY,
                              prevButtonX + self.buttonSize, prevButtonY + self.buttonSize)

        -- Play/Pause button
        local playPauseButtonX = playPauseX
        local playPauseButtonY = controlsY

        -- Draw outline for Play/Pause button
        love.graphics.setColor(1, 1, 1)  -- White outline
        love.graphics.rectangle("line", playPauseButtonX - outlinePadding, playPauseButtonY - outlinePadding,
                               self.buttonSize + 2 * outlinePadding, self.buttonSize + 2 * outlinePadding)

        -- Draw Play/Pause button
        love.graphics.setColor(0.3, 0.3, 0.3)  -- Gray color for the button
        if self.isPlaying then
            love.graphics.rectangle("fill", playPauseButtonX, playPauseButtonY, self.buttonSize, self.buttonSize)
        else
            love.graphics.polygon("fill", playPauseButtonX, playPauseButtonY,
                                  playPauseButtonX + self.buttonSize, playPauseButtonY + self.buttonSize / 2,
                                  playPauseButtonX, playPauseButtonY + self.buttonSize)
        end

        -- Next button
        local nextButtonX = playPauseX + self.buttonSize + 20
        local nextButtonY = controlsY

        -- Draw outline for Next button
        love.graphics.setColor(1, 1, 1)  -- White outline
        love.graphics.rectangle("line", nextButtonX - outlinePadding, nextButtonY - outlinePadding,
                               self.buttonSize + 2 * outlinePadding, self.buttonSize + 2 * outlinePadding)

        -- Draw Next button
        love.graphics.setColor(0.3, 0.3, 0.3)  -- Gray color for the button
        love.graphics.polygon("fill", nextButtonX, nextButtonY,
                              nextButtonX + self.buttonSize, nextButtonY + self.buttonSize / 2,
                              nextButtonX, nextButtonY + self.buttonSize)

        -- Draw playlist
        love.graphics.setColor(unpack(self.config.text_color))
        love.graphics.print("Playlist", self.panel.x + 10, controlsY + self.buttonSize + 20)

        local playlistY = controlsY + self.buttonSize + 50
        for i, song in ipairs(self.playlist) do
            if i == self.currentSongIndex then
                love.graphics.setColor(self.activeColor)  -- Highlight the current song
            else
                love.graphics.setColor(self.textColor)
            end
            love.graphics.print(song.title, self.panel.x + 10, playlistY)
            love.graphics.print("|", self.panel.x + 150, playlistY)
            love.graphics.print(song.artist, self.panel.x+200 , playlistY)
            playlistY = playlistY + 30
        end
    end

    -- Draw toggle button
    love.graphics.setColor(unpack(self.config.button_color))
    love.graphics.circle("fill", self.button.x + self.button.radius, self.button.y + self.button.radius, self.button.radius)

    -- Draw music logo (vertical lines that go from small to big to small)
    local logoX = self.button.x + self.button.radius - 11  -- Center the logo horizontally
    local logoY = self.button.y + self.button.radius - 7  -- Center the logo vertically
    local lineWidth = 3  -- Width of each line
    local lineHeights = {5, 10, 15, 10, 5}  -- Heights of the lines (small to big to small)

    love.graphics.setColor(1, 1, 1)  -- White color for the logo
    for i, height in ipairs(lineHeights) do
        love.graphics.rectangle("fill", logoX + (i - 1) * (lineWidth + 2), logoY + (15 - height) / 2, lineWidth, height)
    end

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

    -- Handle volume bar interaction
    if self.panel.visible then
        local albumArtSize = 150
        local albumArtX = self.panel.x + (self.panel.width - albumArtSize) / 2
        local volumeBarX = albumArtX - 30  -- Position to the left of the album art
        local volumeBarY = self.panel.y + 20
        local volumeBarHeight = albumArtSize

        if x >= volumeBarX and x <= volumeBarX + 10 and y >= volumeBarY and y <= volumeBarY + volumeBarHeight then
            self.draggingVolume = true
            self:updateVolumeFromMouse(y)
        end
    end

    -- Handle playlist item clicks
    if self.panel.visible and x >= self.panel.x and x <= self.panel.x + self.panel.width then
        -- Calculate the starting Y position of the playlist
        local controlsY = self.panel.y + 20 + 150 + 20  -- Y position of playback controls
        local playlistStartY = controlsY + self.buttonSize + 50  -- Starting Y position of the playlist

        -- Check if the click is within the playlist area
        if y >= playlistStartY and y <= playlistStartY + (#self.playlist * 30) then
            -- Calculate which song was clicked
            local songIndex = math.floor((y - playlistStartY) / 30) + 1
            if songIndex >= 1 and songIndex <= #self.playlist then
                self.currentSongIndex = songIndex
                self:loadSong(songIndex)
            end
        end
    end

    -- Handle playback controls
    if self.panel.visible then
        local controlsY = self.panel.y + 20 + 150 + 20
        local playPauseX = self.panel.x + (self.panel.width - self.buttonSize * 3 - 20 * 2) / 2 + 60

        -- Check if previous button is clicked
        if x >= playPauseX - self.buttonSize - 20 and x <= playPauseX - 20 and
           y >= controlsY and y <= controlsY + self.buttonSize then
            self:previousSong()
        end

        -- Check if play/pause button is clicked
        if x >= playPauseX and x <= playPauseX + self.buttonSize and
           y >= controlsY and y <= controlsY + self.buttonSize then
            self:playPause()
        end

        -- Check if next button is clicked
        if x >= playPauseX + self.buttonSize + 20 and x <= playPauseX + self.buttonSize * 2 + 20 and
           y >= controlsY and y <= controlsY + self.buttonSize then
            self:nextSong()
        end
    end
end
function MusicApp:mousemoved(x, y, dx, dy)
    if self.draggingVolume then
        self:updateVolumeFromMouse(y)
    end
end

function MusicApp:updateVolumeFromMouse(y)
    local albumArtSize = 150
    local albumArtY = self.panel.y + 20
    local volumeBarHeight = albumArtSize

    -- Calculate volume based on mouse position
    local volumeY = math.max(albumArtY, math.min(albumArtY + volumeBarHeight, y))
    self.volume = 1 - ((volumeY - albumArtY) / volumeBarHeight)
    self.volume = math.max(0, math.min(1, self.volume))  -- Clamp between 0 and 1

    -- Update audio volume
    if self.currentAudioSource then
        self.currentAudioSource:setVolume(self.volume)
    end
end

function MusicApp:mousereleased(x, y, button)
    self.draggingVolume = false
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