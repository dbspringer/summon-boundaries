-- Pure Lua: no WoW API calls, so the specs can load this file directly.
local _, ns = ...
local L = ns.L

local Config = {}
ns.Config = Config

-- The chat server drops a message longer than this, in bytes.
Config.MAX_MESSAGE_LENGTH = 255

Config.DEFAULTS = {
    -- A fresh install sends nothing until the player turns it on.
    enabled = false,
    fee = "1g",
    mentionFee = true,
    -- luacheck: push no max line length
    message = L["A summon requires two other players, not just a warlock. If you'd like one, please arrange two clickers and offer {fee} for the trouble. Otherwise, please make your own way here."],
    messageNoFee = L["A summon requires two other players, not just a warlock. If you'd like one, please arrange two clickers. Otherwise, please make your own way here."],
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

function Config.FormatReply(settings)
    local template = settings.mentionFee and settings.message or settings.messageNoFee
    -- A function replacement keeps a "%" in the fee from reading as a capture.
    local fee = tostring(settings.fee)
    local reply = template:gsub("{fee}", function()
        return fee
    end)
    if #reply > Config.MAX_MESSAGE_LENGTH then
        -- Cut on a character boundary, since half a UTF-8 character is not valid chat text.
        local cut = Config.MAX_MESSAGE_LENGTH
        while cut > 0 and IsContinuationByte(reply:byte(cut + 1)) do
            cut = cut - 1
        end
        reply = reply:sub(1, cut)
    end
    return reply
end
