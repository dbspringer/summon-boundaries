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

-- The client facts the core needs, for /sb and the panel's preview.
function ns.ClientContext()
    local _, class = UnitClass("player")
    return {
        isWarlock = class == "WARLOCK",
        knowsSummon = C_SpellBook.IsSpellKnown(Config.SUMMON_SPELL_ID),
        version = GetVersion(),
    }
end

SLASH_SUMMONBOUNDARIES1 = "/sb"
SlashCmdList.SUMMONBOUNDARIES = function(input)
    local lines, action = ns.Commands.Run(input, ns.settings, ns.ClientContext())
    for _, line in ipairs(lines) do
        Print(line)
    end
    -- Opening can fail silently on Forever, so say where the panel is (Settings Panel Plan, decision 7).
    if action == "options" and not ns.Panel.Open() then
        Print(L["Open it at Esc > Options > AddOns > Summon Boundaries."])
    end
end
