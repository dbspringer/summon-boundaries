-- Pure Lua: no WoW API calls, so the specs can load this file directly.
local _, ns = ...
local L = ns.L

local Config = {}
ns.Config = Config

-- The chat server drops a message longer than this, in bytes.
Config.MAX_MESSAGE_LENGTH = 255

-- Ritual of Summoning. A warlock learns it from a trainer (at level 20 in the original game), so a
-- warlock without it can't summon at all.
Config.SUMMON_SPELL_ID = 698

Config.DEFAULTS = {
    -- A fresh install sends nothing until the player turns it on.
    enabled = false,
    fee = "1g",
    mentionFee = true,
    noSpellReply = true,
    -- luacheck: push no max line length
    message = L["A summon requires two other players, not just a warlock. If you'd like one, please arrange two clickers and offer {fee} for the trouble. Otherwise, please make your own way here."],
    messageNoFee = L["A summon requires two other players, not just a warlock. If you'd like one, please arrange two clickers. Otherwise, please make your own way here."],
    messageNoSpell = L["I can't summon yet, since I haven't learned Ritual of Summoning. Please make your own way here."],
    -- luacheck: pop
    cooldownMinutes = 15,
    exemptFriends = true,
    exemptGuild = true,
}

-- Fills each missing or wrong-type key from DEFAULTS and keeps every value the
-- player set. Takes nil on a first install.
function Config.ApplyDefaults(saved)
    if type(saved) ~= "table" then
        saved = {}
    end
    for key, value in pairs(Config.DEFAULTS) do
        if type(saved[key]) ~= type(value) then
            saved[key] = value
        end
    end
    return saved
end

local function IsContinuationByte(byte)
    return byte ~= nil and byte >= 0x80 and byte < 0xC0
end

local function ReplyTemplate(settings, knowsSummon)
    if settings.noSpellReply and not knowsSummon then
        return settings.messageNoSpell
    end
    if settings.mentionFee then
        return settings.message
    end
    return settings.messageNoFee
end

-- knowsSummon: whether the player's character knows Ritual of Summoning, which the shell looks up.
-- Returns the Reply, cut to the chat limit, and the length in bytes before the cut.
function Config.FormatReply(settings, knowsSummon)
    local template = ReplyTemplate(settings, knowsSummon)
    -- A function replacement keeps a "%" in the fee from reading as a capture.
    local fee = tostring(settings.fee)
    local reply = template:gsub("{fee}", function()
        return fee
    end)
    local fullLength = #reply
    if fullLength > Config.MAX_MESSAGE_LENGTH then
        -- Cut on a character boundary, since half a UTF-8 character is not valid chat text.
        local cut = Config.MAX_MESSAGE_LENGTH
        while cut > 0 and IsContinuationByte(reply:byte(cut + 1)) do
            cut = cut - 1
        end
        reply = reply:sub(1, cut)
    end
    return reply, fullLength
end
