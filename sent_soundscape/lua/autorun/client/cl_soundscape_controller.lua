local currentSND_ = nil
local oldSND_ = "NaN"
local activeSound = nil
local fadeVolume = 1
local fadeStep = 0.05

local function tryPlaySound(basePath, callback)
    local extensions = { ".ogg", ".mp3", ".wav" }

    local function tryNext(index)
        if index > #extensions then
            print("[Soundscape] Failed to load sound:", basePath)
            return
        end

        local fullPath = "sound/" .. basePath
        if not string.EndsWith(basePath, extensions[index]) then
            fullPath = fullPath .. extensions[index]
        end

        sound.PlayFile(fullPath, "noplay noblock", function(chan, errID, errStr)
            if IsValid(chan) then
                callback(chan)
            else
                tryNext(index + 1)
            end
        end)
    end

    tryNext(1)
end

local function FadeOutAndStop(chan)
    if not IsValid(chan) then return end

    local vol = fadeVolume
    timer.Create("SoundscapeFadeOut_" .. tostring(chan), 0.05, math.ceil(vol / fadeStep), function()
        if not IsValid(chan) then return end
        vol = vol - fadeStep
        if vol <= 0 then
            chan:Stop()
        else
            chan:SetVolume(math.max(vol, 0))
        end
    end)
end

timer.Create("SoundscapeScanner", 0.2, 0, function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local bestEnt = nil
    local bestDist = math.huge

    for _, ent in ipairs(ents.FindByClass("sent_soundscape")) do
        if not IsValid(ent) then continue end

        local radius = ent:GetNWFloat("Radius", 512)
        local pos = ent:GetPos()
        local dist = ply:GetPos():DistToSqr(pos)

        if dist <= radius * radius then
            local tr = util.TraceLine({
                start = pos,
                endpos = ply:EyePos(),
                filter = { ent, ply }
            })

            if tr.Fraction == 1.0 and dist < bestDist then
                bestDist = dist
                bestEnt = ent
            end
        end
    end

    if IsValid(bestEnt) then
        local snd = bestEnt:GetNWString("Sound")
        if snd and snd ~= "" then
            currentSND_ = snd
        end
    end
end)


timer.Create("SoundscapeSwitcher", 0.1, 0, function()
    if currentSND_ ~= oldSND_ then
        if activeSound then
            FadeOutAndStop(activeSound)
            activeSound = nil
        end

        if currentSND_ then
            tryPlaySound(currentSND_, function(chan)
                if not IsValid(chan) then return end

                chan:SetVolume(0)
                chan:EnableLooping(true)
                chan:Play()
                activeSound = chan

                -- Fade in
                local vol = 0
                timer.Create("SoundscapeFadeIn", 0.05, math.ceil(1 / fadeStep), function()
                    if IsValid(chan) then
                        vol = vol + fadeStep
                        chan:SetVolume(math.min(vol, 1))
                    end
                end)
            end)
        end

        oldSND_ = currentSND_
    end
end)


concommand.Add("resetsentsoundscape", function()
    if IsValid(activeSound) then
        activeSound:Stop()
        activeSound = nil
    end

    currentSND_ = nil
    oldSND_ = "NaN"

    print("Reset sent soundscapes")
end)
