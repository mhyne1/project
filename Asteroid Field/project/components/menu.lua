local love = require "love"

local Button = require "components/button"

function Menu(game, player)
    local funcs = {
        quickGame = function()
            love.event.quit()
        end,
    }

    local buttons = {
        Button(resetGame, nil, nil, love.graphics.getWidth() / 3, 50, "New Game", "center", "h3", love.graphics.getWidth() / 3, love.graphics.getHeight() * 0.52),
        Button(funcs.quickGame, nil, nil, love.graphics.getWidth() / 3, 50, "Quit", "center", "h3", love.graphics.getWidth() / 3, love.graphics.getHeight() * 0.65)
    }

    return {
        focused = "",

        run = function(self, clicked)
            local mouse_x, mouse_y = love.mouse.getPosition()

            for name, button in pairs(buttons) do
                if button:checkHover(mouse_x, mouse_y, 10) then
                    if clicked then
                        button:click()
                    end

                    self.focused = name

                    button:setTextColor(0.8, 0.2, 0.2)
                else
                    button:setTextColor(1, 1, 1)
                end
            end
        end,

        draw = function(self)
            for _, button in pairs(buttons) do 
                button:draw()
            end
        end
    }
end

return Menu