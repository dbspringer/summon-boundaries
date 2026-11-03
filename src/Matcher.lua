-- Pure Lua: no WoW API calls, so the specs can load this file directly.
local _, ns = ...

local Matcher = {}
ns.Matcher = Matcher

-- Each entry is a word or a phrase, matched as whole words. Config uses this as the default for the
-- player's own list, so the two start out the same.
Matcher.BUILT_IN_KEYWORDS = "sum, summ, summo, summon, summons, summoning, smn, sumon, lock port, warlock port"

-- A keyword this short matches only as the whole message, so "1" can't match "I have 1 question".
local WHOLE_MESSAGE_MAX_LENGTH = 2

-- Counts UTF-8 characters: every byte except a continuation byte starts one.
local function CharacterCount(text)
    return select(2, text:gsub("[^\128-\191]", ""))
end

-- Lowercase, with punctuation as spaces and single spaces between words.
local function Normalize(text)
    return (text:lower():gsub("%p", " "):gsub("%s+", " "):match("^%s*(.-)%s*$"))
end

function Matcher.ParseKeywords(source)
    local keywords = {}
    for entry in source:gmatch("[^,]+") do
        local keyword = Normalize(entry)
        if keyword ~= "" then
            keywords[#keywords + 1] = keyword
        end
    end
    return keywords
end

local builtIn = Matcher.ParseKeywords(Matcher.BUILT_IN_KEYWORDS)
local customSource, customKeywords

-- The player's list while that override is on, else the built-in list. An empty player list falls
-- back to the built-in one, since /sb off is the way to stop Replies.
function Matcher.ActiveKeywords(settings)
    if not settings.customKeywords then
        return builtIn
    end
    if settings.keywords ~= customSource then
        customSource = settings.keywords
        customKeywords = Matcher.ParseKeywords(customSource)
    end
    if #customKeywords == 0 then
        return builtIn
    end
    return customKeywords
end

function Matcher.IsSummonRequest(text, keywords)
    local message = Normalize(text)
    if message == "" then
        return false
    end
    -- Spaces at both ends, so every keyword can match as whole words with one plain search.
    local padded = " " .. message .. " "
    for _, keyword in ipairs(keywords) do
        if CharacterCount(keyword) <= WHOLE_MESSAGE_MAX_LENGTH then
            if message == keyword then
                return true
            end
        elseif padded:find(" " .. keyword .. " ", 1, true) then
            return true
        end
    end
    return false
end
