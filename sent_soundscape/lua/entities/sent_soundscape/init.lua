AddCSLuaFile()

DEFINE_BASECLASS("base_entity")

ENT.Type = "point"
ENT.Base = "base_entity"
ENT.PrintName = "Soundscape"
ENT.Author = "tixe"
ENT.Spawnable = false

function ENT:Initialize()
    self:SetNoDraw(true)
end

function ENT:KeyValue(key, value)
    if key == "sound" then
        self:SetNWString("Sound", value)
    elseif key == "radius" then
        self:SetNWFloat("Radius", tonumber(value))
    end
end
