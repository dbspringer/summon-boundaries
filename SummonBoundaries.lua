local addonName, ns = ...
local L = ns.L
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

local function PrintStatus()
    local settings = ns.settings
    Print(L["Version %s"]:format(GetVersion()))
    if settings.enabled then
        Print(L["Auto-replies are on."])
    else
        Print(L["Auto-replies are off. Type /sb on to turn them on."])
    end
    Print(L["Fee: %s. Cooldown: %d minutes."]:format(settings.fee, settings.cooldownMinutes))
    Print(L["Reply: %s"]:format(Config.FormatReply(settings)))
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
SlashCmdList.SUMMONBOUNDARIES = function()
    PrintStatus()
end
