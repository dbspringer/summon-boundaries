-- Pure Lua: no WoW API calls, so the specs can load this file directly.
local _, ns = ...
local Matcher = ns.Matcher

local Policy = {}
ns.Policy = Policy

local RATE_LIMIT_REPLIES = 5
local RATE_LIMIT_SECONDS = 5 * 60

-- Staff, or a sender who is away and whose client may auto-reply to ours.
local FILTERED_FLAGS = { GM = true, DEV = true, AFK = true, DND = true }

local Instance = {}
Instance.__index = Instance

-- State lives for the session only, so no Sender reaches SavedVariables (ADR 0002).
function Policy.New()
    return setmetatable({
        lastReplyAt = {}, -- GUID -> time of the last Reply to that Sender
        lastWhisperedAt = {}, -- GUID -> time the player last whispered that character
        replyTimes = {}, -- times of recent Replies to anyone, oldest first
    }, Instance)
end

local function CooldownSeconds(settings)
    return settings.cooldownMinutes * 60
end

-- Removes each GUID whose time is maxAge or more seconds before now.
local function DropExpired(timesByGuid, maxAge, now)
    for guid, at in pairs(timesByGuid) do
        if now - at >= maxAge then
            timesByGuid[guid] = nil
        end
    end
end

local function IsWithin(at, maxAge, now)
    return at ~= nil and now - at < maxAge
end

function Instance:IsExempt(whisper, settings, now)
    return whisper.inGroup
        or (settings.exemptFriends and whisper.isFriend)
        or (settings.exemptGuild and whisper.isGuildMember)
        -- An answer to the player's own whisper is part of a conversation the player started.
        or IsWithin(self.lastWhisperedAt[whisper.guid], CooldownSeconds(settings), now)
end

function Instance:CountRecentReplies(now)
    local count = 0
    for _, at in ipairs(self.replyTimes) do
        if now - at < RATE_LIMIT_SECONDS then
            count = count + 1
        end
    end
    return count
end

-- Returns the first reason in the Decision order that stops a Reply, or "reply".
-- The shell handles "lockdown" before it calls this, and records a "reply" before it sends.
function Instance:Decide(whisper, settings, now)
    if not settings.enabled then
        return "disabled"
    end
    if whisper.isSelf or FILTERED_FLAGS[whisper.flags] then
        return "filtered"
    end
    if not Matcher.IsSummonRequest(whisper.text, Matcher.ActiveKeywords(settings)) then
        return "no-match"
    end
    if self:IsExempt(whisper, settings, now) then
        return "exempt"
    end
    if IsWithin(self.lastReplyAt[whisper.guid], CooldownSeconds(settings), now) then
        return "cooldown"
    end
    if self:CountRecentReplies(now) >= RATE_LIMIT_REPLIES then
        return "rate-limit"
    end
    return "reply"
end

-- Records a Reply to the Sender with this GUID, and drops entries that no longer matter.
function Instance:RecordReply(guid, settings, now)
    DropExpired(self.lastReplyAt, CooldownSeconds(settings), now)
    self.lastReplyAt[guid] = now

    local recent = {}
    for _, at in ipairs(self.replyTimes) do
        if now - at < RATE_LIMIT_SECONDS then
            recent[#recent + 1] = at
        end
    end
    recent[#recent + 1] = now
    self.replyTimes = recent
end

-- Records a whisper the player sent to the character with this GUID.
function Instance:RecordWhisperSent(guid, settings, now)
    DropExpired(self.lastWhisperedAt, CooldownSeconds(settings), now)
    self.lastWhisperedAt[guid] = now
end
