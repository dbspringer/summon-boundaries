-- Shell: reads whispers from the client, asks Policy, and sends the Reply.
local _, ns = ...
local Config = ns.Config

local policy = ns.Policy.New()

-- During Chat Lockdown these can be secret, and a string call on a secret value errors (ADR 0003).
local function InChatLockdown(text, sender, guid)
    return C_ChatInfo.InChatMessagingLockdown()
        or issecretvalue(text)
        or issecretvalue(sender)
        or issecretvalue(guid)
end

local function IsPlayerGuid(guid)
    return type(guid) == "string" and guid:find("^Player%-") ~= nil
end

local function OnWhisper(text, sender, flags, guid)
    if InChatLockdown(text, sender, guid) or not IsPlayerGuid(guid) then
        return
    end
    local settings = ns.settings
    local now = GetTime()
    local whisper = {
        text = text,
        sender = sender,
        guid = guid,
        flags = flags,
        isSelf = guid == UnitGUID("player"),
        inGroup = C_PartyInfo.IsGUIDInGroup(guid),
        isFriend = C_FriendList.IsFriend(guid) or C_BattleNet.GetGameAccountInfoByGUID(guid) ~= nil,
        isGuildMember = IsGuildMember(guid),
    }
    if policy:Decide(whisper, settings, now) ~= "reply" then
        return
    end
    -- Recorded before the send, so a send that errors never leads to a second Reply.
    -- No pcall, so that error still reaches the player's error display.
    policy:RecordReply(guid, settings, now)
    local knowsSummon = C_SpellBook.IsSpellKnown(Config.SUMMON_SPELL_ID)
    C_ChatInfo.SendChatMessage(Config.FormatReply(settings, knowsSummon), "WHISPER", nil, sender)
end

-- Fires for every whisper the player sends, our own Reply too.
local function OnWhisperSent(guid)
    if issecretvalue(guid) or not IsPlayerGuid(guid) then
        return
    end
    policy:RecordWhisperSent(guid, ns.settings, GetTime())
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        -- Only a warlock gets Summon Requests worth a Reply, and the class never changes in a session.
        local _, class = UnitClass("player")
        if class == "WARLOCK" then
            self:RegisterEvent("CHAT_MSG_WHISPER")
            self:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local text, sender, _, _, _, flags, _, _, _, _, _, guid = ...
        OnWhisper(text, sender, flags, guid)
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        OnWhisperSent((select(12, ...)))
    end
end)
