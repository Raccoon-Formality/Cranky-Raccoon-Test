local pd <const> = playdate
local gfx <const> = playdate.graphics

local movingPlatformImage <const> = gfx.image.new(50,10,gfx.kColorWhite)

class("MovingPlatform").extends(gfx.sprite)

function MovingPlatform:init(x, y, entity)
    self:setZIndex(Z_INDEXES.MovingPlatform)
    self:setImage(movingPlatformImage)
    --self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.MovingPlatform)
    self:setCollideRect(0, 0, 50, 10)

    local fields = entity.fields
    self.type = fields.type
    self.size = fields.size
    self.isVertical = fields.isVertical
    self.startNum = fields.startNum

    if self.type == "Circle" then
        self.startNum = math.rad(fields.startNum)
    end

    
    self.moveToX = self.x
    self.moveToY = self.y
    self.startX = x
    self.startY = y
    self.counter = self.startNum

    self.playerCollided = false
    self.player = nil
    self.playerRelativeX = nil
    self.playerRelativeY = nil

    self.isCurrect = false

    self.holdTime = 0
    self.holdX = 0
    self.holdY = 0
    self.holdAmount = 4

    -- line
    if self.type == "Line" and self.isVertical then
        self.lineSprite = gfx.sprite.new(gfx.image.new(4,self.size*2,gfx.kColorWhite):fadedImage(0.2,gfx.image.kDitherTypeBayer2x2))
        self.lineSprite:setZIndex(Z_INDEXES.MovingPlatform - 1)
        self.lineSprite:moveTo(self.startX, self.startY)
        self.lineSprite:add()
    elseif self.type == "Line" and not self.isVertical then
        self.lineSprite = gfx.sprite.new(gfx.image.new(self.size*2,4,gfx.kColorWhite):fadedImage(0.2,gfx.image.kDitherTypeBayer2x2))
        self.lineSprite:setZIndex(Z_INDEXES.MovingPlatform - 1)
        self.lineSprite:moveTo(self.startX, self.startY)
        self.lineSprite:add()
    elseif self.type == "Circle" then
        self.circleImage = gfx.image.new(self.size*2 + 8, self.size*2 + 8,gfx.kColorClear):fadedImage(0.2,gfx.image.kDitherTypeBayer2x2)
        gfx.pushContext(self.circleImage)
            gfx.setLineWidth(4)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawCircleAtPoint(self.size + 4,self.size + 4,self.size)
        gfx.popContext()
        self.circleImage = self.circleImage:fadedImage(0.2,gfx.image.kDitherTypeBayer2x2)
        self.circleSprite = gfx.sprite.new(self.circleImage)
        self.circleSprite:setZIndex(Z_INDEXES.MovingPlatform - 1)
        self.circleSprite:moveTo(self.startX, self.startY)
        self.circleSprite:add()
    end
end

function MovingPlatform:collisionResponse(other)
    if other:getTag() == TAGS.Player then
        return gfx.sprite.kCollisionTypeSlide
    end
    return gfx.sprite.kCollisionTypeOverlap
end

function MovingPlatform:update()
    self.counter += pd.getCrankChange() / 100

    
    if self.type == "Line" and self.isVertical then
        --gfx.setColor(gfx.kColorWhite)
        --gfx.drawLine(self.startX,self.startY-self.size,self.startX,self.startY+self.size)
        self.moveToY = self.size * math.sin(self.counter)
        self.tempX = self.x
        self.tempY = self.y
        self:moveTo(self.x, self.startY + self.moveToY)
        self.xVelocity = self.x - self.tempX
        self.yVelocity = self.y - self.tempY
        if self.playerCollided and self == self.player.lastMovingPlatform then
            self.player:moveTo(self.x + self.playerRelativeX, self.startY + self.moveToY + self.playerRelativeY)
        end
    elseif self.type == "Line" and not self.isVertical then
        --gfx.setColor(gfx.kColorWhite)
        --gfx.drawLine(self.startX-self.size,self.startY,self.startX+self.size,self.startY)
        self.moveToX = self.size * math.sin(self.counter)
        self.tempX = self.x
        self.tempY = self.y
        self:moveTo(self.startX + self.moveToX, self.y)
        self.xVelocity = self.x - self.tempX
        if self.xVelocity ~= 0 then
            self.yVelocity = -1.0
        else
            self.yVelocity = 0
        end
        if self.playerCollided and self == self.player.lastMovingPlatform then
            self.player:moveTo(self.startX + self.moveToX + self.playerRelativeX, self.y + self.playerRelativeY)
        end
    elseif self.type == "Circle" then
        --gfx.setColor(gfx.kColorWhite)
        --gfx.drawLine(self.startX-self.size,self.startY,self.startX+self.size,self.startY)
        self.moveToX = self.size * math.cos(self.counter)
        self.moveToY = self.size * math.sin(self.counter)
        self.tempX = self.x
        self.tempY = self.y
        self:moveTo(self.startX + self.moveToX, self.startY + self.moveToY)
        self.xVelocity = self.x - self.tempX
        self.yVelocity = self.y - self.tempY
        if self.playerCollided and self == self.player.lastMovingPlatform then
            self.player:moveTo(self.startX + self.moveToX + self.playerRelativeX, self.startY + self.moveToY + self.playerRelativeY)
        end
    end

    if self.xVelocity ~= 0 or self.yVelocity ~= 0 then
        self.holdTime = self.holdAmount
        if math.abs(self.xVelocity) > math.abs(self.holdX) then
            self.holdX = self.xVelocity
        end
        if (self.holdX > 0 and self.xVelocity < 0) or (self.holdX < 0 and self.xVelocity > 0)then
            self.holdX = self.xVelocity
        end
        if self.yVelocity < self.holdY then
            self.holdY = self.yVelocity
        end
    else
        self.holdTime -= 1
    end

    if self.holdTime <= 0 then
        self.holdX = 0
        self.holdY = 0
    end

    --[[
    local hitWall = false
    for i=1,length do
        local collision = collisions[i]
        if collision.other:getTag() ~= TAGS.Player then
            hitWall = true
        end
    end
    ]]--
    --[[
    if hitWall then 
        self.xVelocity *= -1
        self.yVelocity *= -1
    end
    ]]--
end