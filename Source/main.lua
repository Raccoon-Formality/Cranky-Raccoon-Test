-- CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Libraries
import "scripts/libraries/AnimatedSprite"
import "scripts/libraries/LDtk"
function lerp(a,b,t) return a * (1-t) + b * t end

function math.clamp(x, min, max)
    if x < min then return min end
    if x > max then return max end
    return x
end


-- Game
import "scripts/sceneManager"

import "scripts/mainMenuScene"
import "scripts/GameScene"
import "scripts/player"
import "scripts/spike"
import "scripts/spikeball"
import "scripts/ability"
import "scripts/endLevel"

import "scripts/movingPlatform"

SCENE_MANAGER = SceneManager()

MainMenuScene()

local pd <const> = playdate
local gfx <const> = playdate.graphics

pd.display.setScale(2)
playdate.display.setRefreshRate(50)

function pd.update()
    playdate.graphics.clear(playdate.graphics.getBackgroundColor())
    gfx.sprite.update()
    pd.timer.updateTimers()
    pd.drawFPS(0,0)
end