local love = require "love"

local Text = require "components/text"
local Menu = require "components/menu"

-- Configuration
local width_screen = 500
local height_screen = 1050
local PLAYER_SPEED = 300
local SHOOT_SPEED = 400
local ENNEMI_SPEED = 300
local gameOverTimerMax = 3  --Time of game over menu

local fonts = {
    medium = {
        font = love.graphics.newFont(16),
        size = 16
    },
    large = {
        font = love.graphics.newFont(24),
        size = 24
    },
    massive = {
        font = love.graphics.newFont(60),
        size = 60
    }
}

-- Game State
local gameState = "menu"  -- gamestate "menu", "gameover", "play"
local gameOverTimer = 0

-- Window Creation
function love.load()
    mouse_x, mouse_y = 0, 0

    love.window.setMode(width_screen, height_screen)
    love.window.setTitle("Asteroid Field")

    ship = love.graphics.newImage("sprites/ship.png")
    asteroid = love.graphics.newImage("sprites/asteroid.png") 
    background = love.graphics.newImage("sprites/background.png")
    menu_background = love.graphics.newImage("sprites/menu_background.png")
    civil_ship = love.graphics.newImage("sprites/civil_ship.png")
    shield_bonus_img = love.graphics.newImage("sprites/shield_bonus.png")
    
    score = 0

    sounds = {}
    sounds.music_menu = love.audio.newSource("sounds/menu_music.ogg", "stream")
    sounds.music_game = love.audio.newSource("sounds/game_music.ogg", "stream")
    sounds.music_game_over = love.audio.newSource("sounds/game_over.ogg", "stream")
    sounds.select = love.audio.newSource("sounds/option_select.ogg", "static")
    sounds.lazer = love.audio.newSource("sounds/laser.ogg", "static")

    sounds.music_menu:setVolume(0.05)
    sounds.music_game:setVolume(0.03)
    sounds.music_game_over:setVolume(0.05)

    menu = Menu()
end

-- Player creation
local player = {
    x = width_screen / 2,
    y = height_screen - 50,
    width = 50,
    height = 50,
    shootTimer = 0,
    visible = true,
}

-- shoots creation
local shoots = {}

-- Ennemi creation
local ennemis = {}

-- Civil creation
local civils = {}

-- Reinitialising game
function resetGame()
    player.x = width_screen / 2
    player.y = height_screen - 50
    player.shootTimer = 0
    player.visible = true
    shoots = {}
    ennemis = {}
    civils = {}
    gameState = "running"
    score = 0
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        if gameState == "menu" then
            clickedMouse = true
            sounds.select:play()
        end
    end
end

-- Update Game
function love.update(dt)
    if gameState == "running" then
        -- Player movement
        love.audio.stop(sounds.music_menu)
        sounds.music_game:play()
        if player.visible then
            if love.keyboard.isDown("left") then
                player.x = player.x - PLAYER_SPEED * dt
            elseif love.keyboard.isDown("right") then
                player.x = player.x + PLAYER_SPEED * dt
            end

            -- Restrict Player movement at the screen 
            if player.x < 0 then
                player.x = 0
            elseif player.x + player.width > width_screen then
                player.x = width_screen - player.width
            end

            -- Player Shoot
            player.shootTimer = player.shootTimer - dt 
            if player.shootTimer < 0 then
                if love.keyboard.isDown("space") then
                    local shoot = {
                        x = player.x + player.width / 2,
                        y = player.y,
                        width = 5,
                        height = 20
                    }
                    
                    table.insert(shoots, shoot)
                    player.shootTimer = 0.2
                    sounds.lazer:play()
                end
            end
        end

        -- Shoot moving
            for i, shoot in ipairs(shoots) do
                shoot.y = shoot.y - SHOOT_SPEED * dt
                if shoot.y < 0 then
                    table.remove(shoots, i)
                end
            end

        -- Ennemi generation
        if math.random() < 0.01 then
            local ennemi = {
                x = math.random(0, width_screen - 50),
                y = -50,
                width = 90,
                height = 75
            }
            table.insert(ennemis, ennemi)
        end

        -- Civil generation
        if math.random() < 0.001 then
            local civil = {
                x = math.random(0, width_screen - 50),
                y = -50,
                width = 90,
                height = 60
            }
            table.insert(civils, civil)
        end

        -- Ennemi deplacement
        for i, ennemi in ipairs(ennemis) do
            ennemi.y = ennemi.y + ENNEMI_SPEED * dt
            if ennemi.y > height_screen then
                table.remove(ennemis, i)
            end

            -- Collision between ennemi and player
            if player.visible and checkCollision(player, ennemi) then
                player.visible = false
                gameState = "gameover"
                gameOverTimer = gameOverTimerMax
            end
        end

        -- Civil deplacement 
        for i, civil in ipairs(civils) do
            civil.y = civil.y + ENNEMI_SPEED * dt
            if civil.y > height_screen then
                table.remove(civils, i)
            end

            -- Collision between player and civil
            if player.visible and checkCollision(player, civil) then
                player.visible = false
                gameState = "gameover"
                gameOverTimer = gameOverTimerMax
            end
        end

        -- Collision between ennemis and shoots     
        for i, ennemi in ipairs(ennemis) do
            for j, shoot in ipairs(shoots) do
                if checkCollision(ennemi, shoot) then
                    table.remove(ennemis, i)
                    table.remove(shoots, j)
                    score = score + 1
                end
            end
        end

        -- Collision between civil and shoots
        for i, civil in ipairs(civils) do
            for j, shoot in ipairs(shoots) do
                if checkCollision(civil, shoot) then
                    table.remove(civils, i)
                    table.remove(shoots, j)
                    gameState = "gameover"
                    gameOverTimer = gameOverTimerMax
                end
            end
        end

        -- Collision between civil and asteroid
        for i, civil in ipairs(civils) do
            for j, ennemi in pairs(ennemis) do
                if checkCollision(civil, ennemi) then
                    table.remove(civils, i)
                    table.remove(ennemis, j)
                end
            end
        end

    elseif gameState == "gameover" then
        love.audio.stop(sounds.music_game)
        sounds.music_game_over:play()
        gameOverTimer = gameOverTimer - dt
        if gameOverTimer < 0 then
            gameState = "menu"
        end
    elseif gameState == "menu" then
        love.audio.stop(sounds.music_game_over)
        sounds.music_menu:play()
        if love.keyboard.isDown("return") then
            resetGame()
        end
        menu:run(clickedMouse)
        
        clickedMouse = false
    end
end

-- Draw game
function love.draw()
    if gameState == "running" then
        love.graphics.draw(background, 0, 0)
        Text(
                "SCORE: " .. score,
                -20,
                10,
                "h4",
                false,
                false,
                love.graphics.getWidth(),
                "right",
                1
            ):draw()

        -- Draw shoots
        for _, shoot in ipairs(shoots) do
            love.graphics.rectangle("fill", shoot.x, shoot.y, shoot.width, shoot.height)
        end

        -- Draw ennemis
        for _, ennemi in ipairs(ennemis) do
            love.graphics.draw(asteroid, ennemi.x, ennemi.y)
        end

        -- Draw civils
        for _, civil in pairs(civils) do
            love.graphics.draw(civil_ship, civil.x, civil.y)
        end

        -- Draw Player
        if player.visible then
            love.graphics.draw(ship, player.x, player.y) 
        end

    elseif gameState == "gameover" then
        love.graphics.draw(background, 0, 0)
        love.graphics.printf("Game Over", fonts.massive.font, 0, love.graphics.getHeight() / 2 - fonts.massive.size, love.graphics.getWidth(), "center")
    elseif gameState == "menu" then
        love.graphics.draw(background, 0, 0)
        love.graphics.setColor(1, 0, 1)
        love.graphics.printf("Asteroid Field", fonts.massive.font, 0, love.graphics.getHeight() / 3 - fonts.massive.size, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
        menu:draw()
    end
end

-- detection between 2 rectangular objects
function checkCollision(objet1, objet2)
    return objet1.x < objet2.x + objet2.width and
           objet2.x < objet1.x + objet1.width and
           objet1.y < objet2.y + objet2.height and
           objet2.y < objet1.y + objet1.height
end