--basic structure declares two pages with different color backgrounds.

FreeAllRegions()

r = nil
local currentpage = 0
lastTime = Time()
--page 1 is harmony, page 2 is chaos
function SwitchPage(self)
	if Time() > (lastTime + 1) then
		if currentpage == 2 then
			currentpage = 1
			SetPage(currentpage)
		else
			currentpage = 2
			SetPage(currentpage)
		end
		lastTime = Time()
	end
end

SetPage(1)
currentpage = 1
--harmony
r1 = Region()
r1.t = r1:Texture(0,128,255,255) --sky blue
r1:EnableHorizontalScroll(true)
r1:Handle("OnHorizontalScroll", SwitchPage)
r1:Show()
r1:EnableInput(true)
r1:SetWidth(ScreenWidth())
r1:SetHeight(ScreenHeight())
r1:SetAnchor("BOTTOMLEFT",0,0)
r1:SetLayer("BACKGROUND")

halfWidth = ScreenWidth() / 2
halfHeight = ScreenHeight() / 2

function accelStrength( x,y,z )
	return (math.abs(x) + math.abs(y) + math.abs(z)) / 3
end

function randomWithStrength(widthOrHeight, strength)
	return widthOrHeight + math.random(-widthOrHeight, widthOrHeight) * (strength / MAXSTRENGTHPOSSIBLE)
end

debouncer = 0
initialStrength = 0
maxStrength = 0
MAXSTRENGTHPOSSIBLE = 0.75
function chaosMovement(region, x, y, z)
	if debouncer == 0 then
		initialStrength = accelStrength(x,y,z)
	end
	debouncer = debouncer + 1
	if debouncer ~= 2 then
		return
	end
	debouncer = 0

	local changeInStrength = math.abs(accelStrength(x,y,z) - initialStrength)

	if changeInStrength > maxStrength then
		maxStrength = changeInStrength
		DPrint("Max strength: " .. tostring(maxStrength))
	end

	if changeInStrength > MAXSTRENGTHPOSSIBLE then
		changeInStrength = MAXSTRENGTHPOSSIBLE
	end

	middleCircle:SetAnchor("TOP", randomWithStrength(halfWidth, changeInStrength), randomWithStrength(halfHeight, changeInStrength) + 50)
end

SetPage(2)
currentpage = 2
--chaos
r2 = Region()
r2.t = r2:Texture(32,32,32,255) --dark gray
r2:EnableHorizontalScroll(true)
r2:Handle("OnHorizontalScroll", SwitchPage)
r2:Show()
r2:EnableInput(true)
r2:SetWidth(ScreenWidth())
r2:SetHeight(ScreenHeight())
r2:SetAnchor("BOTTOMLEFT",0,0)
r2:SetLayer("BACKGROUND")
r2:Handle("OnAccelerate", chaosMovement)

middleCircle = Region()
middleCircle.t = middleCircle:Texture(255, 0, 0, 255)
middleCircle:Show()
middleCircle:EnableInput(true)
middleCircle:SetWidth(50)
middleCircle:SetHeight(50)
middleCircle:SetAnchor("TOP", halfWidth, halfHeight)
