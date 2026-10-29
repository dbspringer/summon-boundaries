-- Pure Lua: no WoW API calls, so the specs can load this file directly.
local _, ns = ...

local Matcher = {}
ns.Matcher = Matcher

local KEYWORDS = {
    sum = true,
    summ = true,
    summo = true,
    summon = true,
    summons = true,
    summoning = true,
}

function Matcher.IsSummonRequest(text)
    -- Whole words only, so a keyword inside a longer word never counts.
    for word in text:lower():gmatch("%a+") do
        if KEYWORDS[word] then
            return true
        end
    end
    return false
end
