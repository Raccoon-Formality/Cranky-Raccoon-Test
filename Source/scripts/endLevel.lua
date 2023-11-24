local gfx <const> = playdate.graphics

class("EndLevel").extends(gfx.sprite)

function EndLevel:init(x, y, entity)

    local endLevelImage = gfx.image.new("images/dumpster")
    self:setZIndex(Z_INDEXES.EndLevel)
    self:setImage(endLevelImage)
    --self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.EndLevel)
    self:setCollideRect(0, 0, self:getSize())
end

function EndLevel:pickUp()
    currentLevel += 1
    SCENE_MANAGER:switchScene(GameScene, LEVEL_LIST[currentLevel][2])
end