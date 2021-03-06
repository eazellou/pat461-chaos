--basic structure declares two pages with different color backgrounds.

DEBUG_MODE = false

-- Initial Frees
SetPage(1)
FreeAllRegions()
SetPage(2)
FreeAllRegions()
SetPage(1)
FreeAllFlowboxes()
DPrint("")

function DocumentPath(path)
    return SystemPath(path)
end

-- Utility Functions
function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function newDPrint(message)
    if not displayApp and DEBUG_MODE then
        DPrint(message)
    end
end

--page 1 is harmony, page 2 is chaos
function SimpleSwitchPage(self)
    if Page() == 1 and not displayApp then
        SetPage(2)
        switchedToMode("chaos")
        updateSounds()
    else
        SetPage(1)
        switchedToMode("harmony")
        updateSounds()
    end
end

-- Networking Functions
function serviceConnected(region, hostName)
    newDPrint("Connected: " .. hostName)
    netServices[hostName] = hostName
end

function serviceDisconnected(region, hostName)
    newDPrint("Disconnected: " .. hostName)
    netServices[hostName] = nil
end

function receivedMessage(region, chaosOrHarmony)
    messageInfo = chaosOrHarmony:split(":")

    if messageInfo[1] == "harmony" and chaosDevices[messageInfo[2]] ~= nil then
        chaosDevices[messageInfo[2]] = nil
        numChaosDevices = numChaosDevices - 1
    elseif messageInfo[1] == "chaos" and chaosDevices[messageInfo[2]] == nil then
        chaosDevices[messageInfo[2]] = messageInfo[2]
        numChaosDevices = numChaosDevices + 1
    elseif messageInfo[1] == "firstPlayer" then
        firstPlayersIP = messageInfo[2]
    elseif messageInfo[1] == "notePlayed" then
        if dots[messageInfo[3]] == nil or firstPlayersIP == nil or messageInfo[2] ~= firstPlayersIP then
            return
        end

        timerShrink(dots[messageInfo[3]])
    else
        return
    end

    newDPrint(messageInfo[2] .. " switched to " .. messageInfo[1])

    newDPrint("chaos: "..numChaosDevices)

    adjustProgressBar()
end

function switchedToMode(mode)
    if displayApp then
        if chaosDevices["I"] ~= nil then
            receivedMessage(nil, "harmony:I")
        end

        return
    end

    receivedMessage(nil, mode .. ":I")

    for key,vhost in pairs(netServices) do
--        newDPrint("switch "..(key or "nil"))
        if vhost ~= nil then
            newDPrint("Sending " .. mode .. " to " .. vhost)
            SendOSCMessage(vhost, NET_PORT, "/urMus/text", mode .. ":" .. myIP)
        end
    end
--    newDPrint("switch2")
end

function updateSounds()
    -- HARMONY SOUNDS
    if Page() == 1 then
        --FreeAllFlowboxes()
        dac.In:RemovePull(cmap.Out)

        if displayApp then
            return
        end

        for i=1,5 do
            pushStarts[i].Out:SetPush(samplers[i].Pos)
            pushLoop[i].Out:SetPush(samplers[i].Loop)
            pushSample[i].Out:SetPush(samplers[i].Sample)
            pushAmp[i].Out:SetPush(samplers[i].Amp)

            pushLoop[i]:Push(0)
            pushStarts[i]:Push(1)
            pushAmp[i]:Push(.5)

            dac.In:SetPull(samplers[i].Out)
        end
    end
    -- CHAOS SOUNDS
    if Page() == 2 then
        for i=1,5 do
            dac.In:RemovePull(samplers[i].Out)
        end

        if displayApp then
            return
        end

        accel.X:SetPush(cmap.Freq)
        accel.Y:SetPush(cmap.NonL)
        dac.In:SetPull(cmap.Out) -- chaos!!!
    end
end

-- Harmony View Functions
function shrinkme(self, elapsed)
    local width = self:Width()
    local height = self:Height()
    width = width - elapsed * SHRINK_SPEED
    height = height - elapsed * SHRINK_SPEED
    if width <= 0 or height <= 0 then
        self:SetWidth(0)
        self:SetHeight(0)
        self:Handle("OnUpdate", nil)
        dad = self:Parent()
        dad:EnableInput(not displayApp)
        dad:Handle("OnTouchDown",timerShrink)
    else
        self:SetWidth(width)
        self:SetHeight(height)
    end
end

function timerShrink(this)
    if not displayApp then
        pushStarts[this.id]:Push(-1)
    end

    this:EnableInput(false)

    kid = this:Children()
    kid:SetHeight(this:Height())
    kid:SetWidth(this:Width())
    kid:Handle("OnUpdate",shrinkme)

    if firstPlayer then
        for key,vhost in pairs(netServices) do
            if vhost ~= nil then
                SendOSCMessage(vhost, NET_PORT, "/urMus/text", "notePlayed" .. ":" .. myIP .. ":" .. tostring(this.id))
            end
        end
    end
end

-- Chaos View Functions
function adjustProgressBar()
    local percentageOfPeople = numChaosDevices / MAX_NUM_PEOPLE
    currwidth = percentageOfPeople * bar1:Width()
    progress1:SetWidth(currwidth)
    currwidth = percentageOfPeople * bar2:Width()
    progress2:SetWidth(currwidth)
end
function accelStrength( x,y,z )
    return (math.abs(x) + math.abs(y) + math.abs(z)) / 3
end

function randomWithStrength(widthOrHeight, strength)
    return widthOrHeight + math.random(-widthOrHeight, widthOrHeight) * (strength / MAXSTRENGTHPOSSIBLE)
end

function chaosMovement(region, x, y, z)
    local strength = accelStrength(x,y,z)
    local changeInStrength = math.abs(strength - previousStrength)

    if changeInStrength > maxStrength then
        maxStrength = changeInStrength
        --newDPrint("Max strength: " .. tostring(maxStrength))
    end

    if changeInStrength > MAXSTRENGTHPOSSIBLE then
        changeInStrength = MAXSTRENGTHPOSSIBLE
    end

    globalChangeVar = changeInStrength*10

    middleCircle:SetAnchor("TOP", randomWithStrength(halfWidth, changeInStrength), randomWithStrength(halfHeight, changeInStrength) + 50)

    previousStrength = strength
end

function updateDisplayChaos()
    if not displayApp then
        return
    end

    local changeInStrength = (numChaosDevices / MAX_NUM_PEOPLE) * MAXSTRENGTHPOSSIBLE
    middleCircleDisplay:SetAnchor("TOP", randomWithStrength(halfWidth, changeInStrength), randomWithStrength(halfHeight, changeInStrength) + 50)
end

function displayAppChange()
    if firstPlayer then
        return
    end

    if not displayApp then
        DPrint("")
    end

    dot1:EnableInput(displayApp)
    dot2:EnableInput(displayApp)
    dot3:EnableInput(displayApp)
    dot5:EnableInput(displayApp)
    dot6:EnableInput(displayApp)

    displayApp = not displayApp

    if displayApp then
        displayButton1.t = displayButton1:Texture(150,0,150,255)
        displayButton2.t = displayButton2:Texture(150,0,150,255)

        bar2:Show()
        progress2:Show()
        middleCircleDisplay:Show()

        firstPlayerButton1:Hide()
        firstPlayerButton2:Hide()

        SimpleSwitchPage(nil)

    else
        displayButton1.t = displayButton1:Texture(255,255,255,255)
        displayButton2.t = displayButton2:Texture(255,255,255,255)

        bar2:Hide()
        progress2:Hide()
        middleCircleDisplay:Hide()

        firstPlayerButton1:Show()
        firstPlayerButton2:Show()
    end

    updateSounds()

    if Page() == 1 then
        switchedToMode("harmony")
    else
        switchedToMode("chaos")
    end
end

function firstPlayerChange()
    if displayApp then
        return
    end

    firstPlayer = not firstPlayer

    if firstPlayer then
        firstPlayerButton1.t = firstPlayerButton1:Texture(0,255,0,255)
        firstPlayerButton2.t = firstPlayerButton2:Texture(0,255,0,255)

        for key,vhost in pairs(netServices) do
            if vhost ~= nil then
                SendOSCMessage(vhost, NET_PORT, "/urMus/text", "firstPlayer" .. ":" .. myIP)
            end
        end

        displayButton1:Hide()
        displayButton2:Hide()
    else
        firstPlayerButton1.t = firstPlayerButton1:Texture(255,255,255,255)
        firstPlayerButton2.t = firstPlayerButton2:Texture(255,255,255,255)

        displayButton1:Show()
        displayButton2:Show()
    end
end

-- Constants

-- Does this app contribute or just show off
displayApp = false

-- Who was the first player
firstPlayer = false
firstPlayersIP = nil

-- Network
NET_PORT = 8888

MAX_NUM_PEOPLE = 10

numChaosDevices = 0
chaosDevices = {}
netServices = {}

-- Sound
pushStarts = {}
samplers = {}
pushLoop = {}
pushAmp = {}
pushSample = {}
dac = FBDac
accel = FBAccel
cmap = FlowBox(FBCMap)

for i = 1,5 do
    samplers[i] = FlowBox(FBSample)
    pushStarts[i] = FlowBox(FBPush)
    pushLoop[i] = FlowBox(FBPush)
    pushSample[i] = FlowBox(FBPush)
    pushAmp[i] = FlowBox(FBPush)
end

samplers[1]:AddFile(DocumentPath("AbMono.wav"))
samplers[2]:AddFile(DocumentPath("BbMono.wav"))
samplers[3]:AddFile(DocumentPath("CMono.wav"))
samplers[4]:AddFile(DocumentPath("Ab10Mono.wav"))
samplers[5]:AddFile(DocumentPath("G10Mono.wav"))

-- Size Stuff
halfWidth = ScreenWidth() / 2
halfHeight = ScreenHeight() / 2

smallHeight = ScreenHeight()/3 - 8
if smallHeight > ScreenWidth()/2 then
    smallHeight = ScreenWidth()/2
end

bigHeight = ScreenHeight()/2 - 6
if bigHeight > ScreenWidth()/2 then
    bigHeight = ScreenWidth()/2
end
bigRadius = bigHeight/2
smRad = smallHeight/2

SHRINK_SPEED = 17

-- Chaos View Constants

barwidth = 300
currwidth = 0
globalChangeVar = 0

debouncer = 0
previousStrength = 0
maxStrength = 0
MAXSTRENGTHPOSSIBLE = 0.75

-- Time
lastTime = Time()

-- View setup

--harmony
SetPage(1)

r1 = Region()
r1.t = r1:Texture(0,0,0,255)
r1:EnableHorizontalScroll(true)
r1:Handle("OnDoubleTap", SimpleSwitchPage)
r1:Handle("OnUpdate", updateDisplayChaos)
r1:Show()
r1:EnableInput(true)
r1:SetWidth(ScreenWidth())
r1:SetHeight(ScreenHeight())
r1:SetAnchor("BOTTOMLEFT",0,0)
r1:SetLayer("BACKGROUND")

displayButton1 = Region()
displayButton1.t = displayButton1:Texture(255,255,255,255)
displayButton1:SetAnchor("TOPRIGHT", r1, "TOPRIGHT", 0, 0)
displayButton1:EnableInput(true)
displayButton1:SetHeight(20)
displayButton1:SetWidth(40)
displayButton1:Handle("OnTouchUp", displayAppChange)
displayButton1:Show()

firstPlayerButton1 = Region()
firstPlayerButton1.t = firstPlayerButton1:Texture(255,255,255,255)
firstPlayerButton1:SetAnchor("TOPLEFT", r1, "TOPLEFT", 0, 0)
firstPlayerButton1:EnableInput(true)
firstPlayerButton1:SetHeight(20)
firstPlayerButton1:SetWidth(40)
firstPlayerButton1:Handle("OnTouchUp", firstPlayerChange)
firstPlayerButton1:Show()

middleCircleDisplay = Region()
middleCircleDisplay.t = middleCircleDisplay:Texture("2000px-Disc_Plain_red.svg.png")
middleCircleDisplay:EnableInput(true)
middleCircleDisplay:SetWidth(50)
middleCircleDisplay:SetHeight(50)
middleCircleDisplay:SetAnchor("TOP", halfWidth, halfHeight)

bar2 = Region()
bar2.t = bar2:Texture(60,45,70,255)
bar2:SetAnchor("BOTTOMLEFT", r1, "BOTTOMLEFT")
bar2:SetHeight(20)
bar2:SetWidth(ScreenWidth())

progress2 = Region()
progress2.t = progress2:Texture(150,0,150,255)
progress2:SetAnchor("BOTTOMLEFT", r1, "BOTTOMLEFT")
progress2:SetHeight(20)
progress2:SetWidth(currwidth)

dot1 = Region()
dot1.t = dot1:Texture(DocumentPath("Dot.png"))
dot1:Show()
dot1.id = 1
dot1.t:SetBlendMode("ALPHAKEY")
dot1:SetHeight(smallHeight)
dot1:SetWidth(dot1:Height())
dot1:SetAnchor("CENTER", smRad, halfHeight - smallHeight - 12)

time1 = Region()
time1.t = time1:Texture(DocumentPath("darkdot.png"))
time1:Show()
time1.t:SetBlendMode("ALPHAKEY")
time1:SetHeight(0)
time1:SetWidth(0)
time1:SetAnchor("CENTER",dot1,"CENTER")
time1:SetParent(dot1)

dot2 = Region()
dot2.t = dot2:Texture(DocumentPath("Dot.png"))
dot2:Show()
dot2.id = 2
dot2.t:SetBlendMode("ALPHAKEY")
dot2:SetHeight(smallHeight)
dot2:SetWidth(dot2:Height())
dot2:SetAnchor("CENTER", smRad, halfHeight)

time2 = Region()
time2.t = time2:Texture(DocumentPath("darkdot.png"))
time2:Show()
time2.t:SetBlendMode("ALPHAKEY")
time2:SetHeight(0)
time2:SetWidth(0)
time2:SetAnchor("CENTER",dot2,"CENTER")
time2:SetParent(dot2)

dot3 = Region()
dot3.t = dot3:Texture(DocumentPath("Dot.png"))
dot3:Show()
dot3.id = 3
dot3.t:SetBlendMode("ALPHAKEY")
dot3:SetHeight(smallHeight)
dot3:SetWidth(dot3:Height())
dot3:SetAnchor("CENTER", smRad, halfHeight + smallHeight + 12)

time3 = Region()
time3.t = time3:Texture(DocumentPath("darkdot.png"))
time3:Show()
time3.t:SetBlendMode("ALPHAKEY")
time3:SetHeight(0)
time3:SetWidth(0)
time3:SetAnchor("CENTER",dot3,"CENTER")
time3:SetParent(dot3)

dot5 = Region()
dot5.t = dot5:Texture(DocumentPath("Dot.png"))
dot5:Show()
dot5.id = 4
dot5.t:SetBlendMode("ALPHAKEY")
dot5:SetHeight(bigHeight)
dot5:SetWidth(dot5:Height())
dot5:SetAnchor("CENTER", ScreenWidth() - bigRadius, ScreenHeight()/2 - bigRadius - 6)

time5 = Region()
time5.t = time5:Texture(DocumentPath("darkdot.png"))
time5:Show()
time5.t:SetBlendMode("ALPHAKEY")
time5:SetHeight(0)
time5:SetWidth(0)
time5:SetAnchor("CENTER",dot5,"CENTER")
time5:SetParent(dot5)

dot6 = Region()
dot6.t = dot6:Texture(DocumentPath("Dot.png"))
dot6:Show()
dot6.id = 5
dot6.t:SetBlendMode("ALPHAKEY")
dot6:SetHeight(bigHeight)
dot6:SetWidth(dot6:Height())
dot6:SetAnchor("CENTER", ScreenWidth() - bigRadius, ScreenHeight()/2 + bigRadius + 6)

time6 = Region()
time6.t = time6:Texture(DocumentPath("darkdot.png"))
time6:Show()
time6.t:SetBlendMode("ALPHAKEY")
time6:SetHeight(0)
time6:SetWidth(0)
time6:SetAnchor("CENTER",dot6,"CENTER")
time6:SetParent(dot6)

dots = {["1"]=dot1, ["2"]=dot2, ["3"]=dot3, ["4"]=dot5, ["5"]=dot6}

dot1:EnableInput(true)
dot2:EnableInput(true)
dot3:EnableInput(true)
dot5:EnableInput(true)
dot6:EnableInput(true)

dot1:Handle("OnTouchDown", timerShrink)
dot2:Handle("OnTouchDown", timerShrink)
dot3:Handle("OnTouchDown", timerShrink)
dot5:Handle("OnTouchDown", timerShrink)
dot6:Handle("OnTouchDown", timerShrink)

--chaos
SetPage(2)

r2 = Region()
r2.t = r2:Texture(0,0,0,255)
r2:EnableHorizontalScroll(true)
r2:Handle("OnDoubleTap", SimpleSwitchPage)
r2:Show()
r2:EnableInput(true)
r2:SetWidth(ScreenWidth())
r2:SetHeight(ScreenHeight())
r2:SetAnchor("BOTTOMLEFT",0,0)
r2:SetLayer("BACKGROUND")
r2:Handle("OnAccelerate", chaosMovement)

displayButton2 = Region()
displayButton2.t = displayButton2:Texture(255,255,255,255)
displayButton2:SetAnchor("TOPRIGHT", r2, "TOPRIGHT", 0, 0)
displayButton2:EnableInput(true)
displayButton2:SetHeight(20)
displayButton2:SetWidth(40)
displayButton2:Handle("OnTouchUp", displayAppChange)
displayButton2:Show()

firstPlayerButton2 = Region()
firstPlayerButton2.t = firstPlayerButton2:Texture(255,255,255,255)
firstPlayerButton2:SetAnchor("TOPLEFT", r2, "TOPLEFT", 0, 0)
firstPlayerButton2:EnableInput(true)
firstPlayerButton2:SetHeight(20)
firstPlayerButton2:SetWidth(40)
firstPlayerButton2:Handle("OnTouchUp", firstPlayerChange)
firstPlayerButton2:Show()

bar1 = Region()
bar1.t = bar1:Texture(60,45,70,255)
bar1:SetAnchor("BOTTOMLEFT", r2, "BOTTOMLEFT")
bar1:SetHeight(20)
bar1:SetWidth(ScreenWidth())
bar1:Show()

progress1 = Region()
progress1.t = progress1:Texture(150,0,150,255)
progress1:SetAnchor("BOTTOMLEFT", r2, "BOTTOMLEFT")
progress1:SetHeight(20)
progress1:SetWidth(currwidth)
progress1:Show()

middleCircle = Region()
middleCircle.t = middleCircle:Texture("2000px-Disc_Plain_red.svg.png")
middleCircle:Show()
middleCircle:EnableInput(true)
middleCircle:SetWidth(50)
middleCircle:SetHeight(50)
middleCircle:SetAnchor("TOP", halfWidth, halfHeight)

switchedToMode("chaos")

netRegion2 = Region()
netRegion2:Handle("OnNetConnect", serviceConnected)
netRegion2:Handle("OnNetDisconnect", serviceDisconnected)
netRegion2:Handle("OnOSCMessage", receivedMessage)

-- Switch back to harmony
SetPage(1)

switchedToMode("harmony")

updateSounds()

-- Initial Network Setup
SetOSCPort(NET_PORT)
myIP, port = StartOSCListener()
StartNetAdvertise("chaosandharmony", 8889)

netRegion = Region()
netRegion:Handle("OnNetConnect", serviceConnected)
netRegion:Handle("OnNetDisconnect", serviceDisconnected)
netRegion:Handle("OnOSCMessage", receivedMessage)
StartNetDiscovery("chaosandharmony")
