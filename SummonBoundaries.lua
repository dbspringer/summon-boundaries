local addonName, ns = ...
local Config = ns.Config

-- Warlock class colour.
local PREFIX = "|cff8788eeSummon Boundaries|r: "

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. message)
end

local function GetVersion()
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    -- The packager fills the token from the tag, so a repo checkout shows it raw.
    if not version or version:find("^@") then
        return "dev"
    end
    return version
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, _, loadedName)
    if loadedName ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    SummonBoundariesDB = Config.ApplyDefaults(SummonBoundariesDB)
    ns.settings = SummonBoundariesDB
end)

SLASH_SUMMONBOUNDARIES1 = "/sb"
SlashCmdList.SUMMONBOUNDARIES = function(input)
    local _, class = UnitClass("player")
    local context = {
        isWarlock = class == "WARLOCK",
        knowsSummon = C_SpellBook.IsSpellKnown(Config.SUMMON_SPELL_ID),
        version = GetVersion(),
    }
    for _, line in ipairs(ns.Commands.Run(input, ns.settings, context)) do
        Print(line)
    end
end
