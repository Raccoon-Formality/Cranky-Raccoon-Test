import "GameScene"

local pd <const> = playdate
local gfx <const> = playdate.graphics

class('MainMenuScene').extends(gfx.sprite)

function MainMenuScene:init()

    self.unlockedLevels = {}
    for i=1, #LEVEL_LIST do
        if LEVEL_LIST[i][3] then
            table.insert(self.unlockedLevels,{LEVEL_LIST[i][1],i})
        end
    end
    currentLevel = 1
    self.levelSelectLength = #self.unlockedLevels
    
    gfx.setBackgroundColor(gfx.kColorWhite)
    -- local text = "Game Over"
    local MainMenuImage = gfx.image.new(gfx.getTextSize("*cranky raccoon*"))
    gfx.pushContext(MainMenuImage)
        gfx.drawText("*cranky raccoon*", 0, 0)
    gfx.popContext()
    local MainMenuSprite = gfx.sprite.new(MainMenuImage)
    MainMenuSprite:moveTo(100, 60)
    MainMenuSprite:add()

    

    local LevelSelectImage = gfx.image.new(gfx.getTextSize(self.unlockedLevels[1][1]))
    gfx.pushContext(LevelSelectImage)
        gfx.drawText(self.unlockedLevels[1][1], 0, 0)
    gfx.popContext()
    self.LevelSelectSprite = gfx.sprite.new(LevelSelectImage)
    self.LevelSelectSprite:moveTo(100, 85)
    self.LevelSelectSprite:add()

    self:add()
end

function MainMenuScene:update()
    if pd.buttonJustPressed(pd.kButtonA) then
        SCENE_MANAGER:switchScene(GameScene, LEVEL_LIST[self.unlockedLevels[currentLevel][2]][2])
    end

    if pd.buttonJustPressed(pd.kButtonUp) then
        currentLevel -= 1
        if currentLevel < 1 then
            currentLevel = self.levelSelectLength
        end
        local LevelSelectImage = gfx.image.new(gfx.getTextSize(self.unlockedLevels[currentLevel][1]))
        gfx.pushContext(LevelSelectImage)
            gfx.drawText(self.unlockedLevels[currentLevel][1], 0, 0)
        gfx.popContext()
        self.LevelSelectSprite:setImage(LevelSelectImage)
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        currentLevel += 1
        if currentLevel > self.levelSelectLength then
            currentLevel = 1
        end
        local LevelSelectImage = gfx.image.new(gfx.getTextSize(self.unlockedLevels[currentLevel][1]))
        gfx.pushContext(LevelSelectImage)
            gfx.drawText(self.unlockedLevels[currentLevel][1], 0, 0)
        gfx.popContext()
        self.LevelSelectSprite:setImage(LevelSelectImage)
    end
end