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
        replyTimes = {}, -- times of recent Replies to anyone, oldest first
    }, Instance)
end

local function CooldownSeconds(settings)
    return settings.cooldownMinutes * 60
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
    if not Matcher.IsSummonRequest(whisper.text) then
        return "no-match"
    end
    local lastReplyAt = self.lastReplyAt[whisper.guid]
    if lastReplyAt and now - lastReplyAt < CooldownSeconds(settings) then
        return "cooldown"
    end
    if self:CountRecentReplies(now) >= RATE_LIMIT_REPLIES then
        return "rate-limit"
    end
    return "reply"
end

-- Records a Reply to the Sender with this GUID, and drops entries that no longer matter.
function Instance:RecordReply(guid, settings, now)
    local cooldown = CooldownSeconds(settings)
    for key, at in pairs(self.lastReplyAt) do
        if now - at >= cooldown then
            self.lastReplyAt[key] = nil
        end
    end
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
