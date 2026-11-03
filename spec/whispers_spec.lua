-- Drives src/Whispers.lua through stubbed WoW globals, the way the client would.

local PLAYER_GUID = "Player-0-PLAYER"

-- A secret value is a table, so any string call on it errors, as it would in the client.
local function Secret()
    return {}
end

local client

local function StubClient()
    client = {
        class = "WARLOCK",
        knowsSummon = true,
        now = 0,
        lockdown = false,
        secrets = {},
        inGroup = {},
        friends = {},
        bnetFriends = {},
        guildMembers = {},
        sent = {},
        sendError = nil,
        frame = nil,
    }

    _G.CreateFrame = function()
        local frame = { events = {} }
        function frame:RegisterEvent(event)
            self.events[event] = true
        end
        function frame:UnregisterEvent(event)
            self.events[event] = nil
        end
        function frame:SetScript(_, handler)
            self.onEvent = handler
        end
        client.frame = frame
        return frame
    end
    _G.UnitClass = function()
        return "Classname", client.class
    end
    _G.C_SpellBook = {
        IsSpellKnown = function(spellID)
            return spellID == 698 and client.knowsSummon
        end,
    }
    _G.UnitGUID = function()
        return PLAYER_GUID
    end
    _G.GetTime = function()
        return client.now
    end
    _G.issecretvalue = function(value)
        return client.secrets[value] == true
    end
    _G.IsGuildMember = function(guid)
        return client.guildMembers[guid] == true
    end
    _G.C_PartyInfo = {
        IsGUIDInGroup = function(guid)
            return client.inGroup[guid] == true
        end,
    }
    _G.C_FriendList = {
        IsFriend = function(guid)
            return client.friends[guid] == true
        end,
    }
    _G.C_BattleNet = {
        GetGameAccountInfoByGUID = function(guid)
            if client.bnetFriends[guid] then
                return { isOnline = true }
            end
            return nil
        end,
    }
    _G.C_ChatInfo = {
        InChatMessagingLockdown = function()
            return client.lockdown
        end,
        SendChatMessage = function(message, chatType, languageID, target)
            if client.sendError then
                error(client.sendError)
            end
            client.sent[#client.sent + 1] = {
                message = message,
                chatType = chatType,
                languageID = languageID,
                target = target,
            }
        end,
    }
end

local ns

local function LoadAddon()
    ns = {}
    local files = { "locales/enUS.lua", "src/Config.lua", "src/Matcher.lua", "src/Policy.lua", "src/Whispers.lua" }
    for _, file in ipairs(files) do
        assert(loadfile(file))("SummonBoundaries", ns)
    end
    ns.settings = ns.Config.ApplyDefaults({ enabled = true })
end

-- Delivers an event only if the addon registered for it, as the client does.
local function Fire(event, ...)
    local frame = client.frame
    if frame.events[event] then
        frame.onEvent(frame, event, ...)
    end
end

local function Login()
    Fire("PLAYER_LOGIN")
end

-- CHAT_MSG_WHISPER: text is arg 1, sender arg 2, flags arg 6, GUID arg 12.
local function Whisper(text, sender, guid, flags)
    Fire("CHAT_MSG_WHISPER", text, sender, "", "", sender, flags or "", 0, 0, "", 0, 1, guid)
end

-- CHAT_MSG_WHISPER_INFORM: the recipient's GUID is arg 12.
local function WhisperSent(text, target, guid)
    Fire("CHAT_MSG_WHISPER_INFORM", text, target, "", "", target, "", 0, 0, "", 0, 1, guid)
end

local function Reply()
    return ns.Config.FormatReply(ns.settings, true)
end

describe("Whispers", function()
    before_each(function()
        StubClient()
        LoadAddon()
    end)

    it("whispers the Reply back to the sender, as the client named them", function()
        Login()
        Whisper("can you summon me?", "First Last", "Player-1")
        Whisper("sum pls", "Other-Realm", "Player-2")
        assert.are.same({
            { message = Reply(), chatType = "WHISPER", languageID = nil, target = "First Last" },
            { message = Reply(), chatType = "WHISPER", languageID = nil, target = "Other-Realm" },
        }, client.sent)
    end)

    it("tells the sender when the warlock hasn't learned Ritual of Summoning yet", function()
        client.knowsSummon = false
        Login()
        Whisper("summon?", "Stranger", "Player-1")
        assert.are.equal(1, #client.sent)
        assert.are.equal(ns.Config.DEFAULTS.messageNoSpell, client.sent[1].message)
    end)

    it("stays quiet for a whisper that is not a Summon Request", function()
        Login()
        Whisper("hey, nice mount", "Stranger", "Player-1")
        assert.are.equal(0, #client.sent)
    end)

    it("sends nothing on a character that is not a warlock", function()
        client.class = "MAGE"
        Login()
        Whisper("summon?", "Stranger", "Player-1")
        assert.are.equal(0, #client.sent)
    end)

    it("skips Exempt Senders and the player's own character", function()
        client.inGroup["Player-1"] = true
        client.friends["Player-2"] = true
        client.bnetFriends["Player-3"] = true
        client.guildMembers["Player-4"] = true
        Login()
        for _, guid in ipairs({ "Player-1", "Player-2", "Player-3", "Player-4", PLAYER_GUID }) do
            Whisper("summon?", "Someone", guid)
        end
        assert.are.equal(0, #client.sent)
    end)

    it("skips a Sender who answers the player's own whisper", function()
        Login()
        WhisperSent("want a summon to ZG?", "Stranger", "Player-1")
        client.now = 60
        Whisper("yes, summon pls", "Stranger", "Player-1")
        assert.are.equal(0, #client.sent)
    end)

    describe("in Chat Lockdown", function()
        before_each(Login)

        it("sends nothing while the client reports lockdown", function()
            client.lockdown = true
            Whisper("summon?", "Stranger", "Player-1")
            assert.are.equal(0, #client.sent)
        end)

        it("touches no secret text, sender, or GUID", function()
            local text, sender, guid = Secret(), Secret(), Secret()
            client.secrets[text], client.secrets[sender], client.secrets[guid] = true, true, true
            Whisper(text, "Stranger", "Player-1")
            Whisper("summon?", sender, "Player-2")
            Whisper("summon?", "Stranger", guid)
            assert.are.equal(0, #client.sent)
        end)

        it("passes over a whisper sent to a secret GUID", function()
            local guid = Secret()
            client.secrets[guid] = true
            WhisperSent("hi", "Stranger", guid)
            Whisper("summon?", "Stranger", "Player-1")
            assert.are.equal(1, #client.sent)
        end)
    end)

    it("ignores a whisper whose GUID is not a player's", function()
        Login()
        Whisper("summon?", "Stranger", nil)
        Whisper("summon?", "Stranger", "Creature-0-1")
        assert.are.equal(0, #client.sent)
    end)

    it("records the Cooldown before the send, so a failed send never repeats", function()
        Login()
        client.sendError = "send failed"
        assert.has_error(function()
            Whisper("summon?", "Stranger", "Player-1")
        end)
        client.sendError = nil
        client.now = 60
        Whisper("summon?", "Stranger", "Player-1")
        assert.are.equal(0, #client.sent)
    end)
end)
