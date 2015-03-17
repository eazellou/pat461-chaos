--basic structure declares two pages with different color backgrounds.

FreeAllRegions()
DPrint("")

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
r1.t = r1:Texture(32,32,32,255)
r1:EnableHorizontalScroll(true)
r1:Handle("OnHorizontalScroll", SwitchPage)
r1:Show()
r1:EnableInput(true)
r1:SetWidth(ScreenWidth())
r1:SetHeight(ScreenHeight())
r1:SetAnchor("BOTTOMLEFT",0,0)
r1:SetLayer("BACKGROUND")

smallHeight = ScreenHeight()/3 - 8
if smallHeight > ScreenWidth()/2 then
	smallHeight = ScreenWidth()/2
end

bigHeight = ScreenHeight()/2 - 6
if bigHeight > ScreenWidth()/2 then
	bigHeight = ScreenWidth()/2
end
bigRadius = bigHeight/2

dot1 = Region()
dot1.t = dot1:Texture(DocumentPath("Dot.png"))
dot1:Show() 
dot1.t:SetBlendMode("ALPHAKEY")
dot1:SetHeight(smallHeight)
dot1:SetWidth(dot1:Height())

dot2 = Region()
dot2.t = dot2:Texture(DocumentPath("Dot.png"))
dot2:Show() 
dot2.t:SetBlendMode("ALPHAKEY")
dot2:SetHeight(smallHeight)
dot2:SetWidth(dot2:Height())
dot2:SetAnchor("BOTTOMLEFT", 0, dot1:Height() + 12)

dot3 = Region()
dot3.t = dot3:Texture(DocumentPath("Dot.png"))
dot3:Show() 
dot3.t:SetBlendMode("ALPHAKEY")
dot3:SetHeight(smallHeight)
dot3:SetWidth(dot3:Height())
dot3:SetAnchor("BOTTOMLEFT", 0, dot1:Height() + dot2:Height() + 24)

dot5 = Region()
dot5.t = dot5:Texture(DocumentPath("Dot.png"))
dot5:Show() 
dot5.t:SetBlendMode("ALPHAKEY")
dot5:SetHeight(bigHeight)
dot5:SetWidth(dot5:Height())
dot5:SetAnchor("CENTER", ScreenWidth() - bigRadius, ScreenHeight()/2 - bigRadius - 6)

dot6 = Region()
dot6.t = dot6:Texture(DocumentPath("Dot.png"))
dot6:Show() 
dot6.t:SetBlendMode("ALPHAKEY")
dot6:SetHeight(bigHeight)
dot6:SetWidth(dot6:Height())
dot6:SetAnchor("CENTER", ScreenWidth() - bigRadius, ScreenHeight()/2 + bigRadius + 6)


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
		--DPrint("Max strength: " .. tostring(maxStrength))
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

SetPage(1)