local ns = {}
for _, file in ipairs({ "locales/enUS.lua", "src/Config.lua", "src/Matcher.lua", "src/Policy.lua" }) do
    assert(loadfile(file))("SummonBoundaries", ns)
end
local Config = ns.Config
local Policy = ns.Policy

local MINUTE = 60

local function Settings(overrides)
    local settings = Config.ApplyDefaults({ enabled = true })
    for key, value in pairs(overrides or {}) do
        settings[key] = value
    end
    return settings
end

local function Whisper(overrides)
    local whisper = {
        text = "can you summon me?",
        sender = "Stranger",
        guid = "Player-1",
        flags = "",
        isSelf = false,
        inGroup = false,
        isFriend = false,
        isGuildMember = false,
    }
    for key, value in pairs(overrides or {}) do
        whisper[key] = value
    end
    return whisper
end

-- Mirrors the shell: a Reply is recorded before it is sent.
local function Handle(policy, whisper, settings, now)
    local decision = policy:Decide(whisper, settings, now)
    if decision == "reply" then
        policy:RecordReply(whisper.guid, settings, now)
    end
    return decision
end

describe("Policy", function()
    local policy, settings

    before_each(function()
        policy = Policy.New()
        settings = Settings()
    end)

    it("replies to a stranger's Summon Request", function()
        assert.are.equal("reply", Handle(policy, Whisper(), settings, 0))
    end)

    it("ignores a whisper that is not a Summon Request", function()
        assert.are.equal("no-match", Handle(policy, Whisper({ text = "hey, nice mount" }), settings, 0))
    end)

    it("sends nothing while auto-replies are off", function()
        assert.are.equal("disabled", Handle(policy, Whisper(), Settings({ enabled = false }), 0))
    end)

    it("skips staff and away senders", function()
        for _, flags in ipairs({ "GM", "DEV", "AFK", "DND" }) do
            assert.are.equal("filtered", Handle(policy, Whisper({ flags = flags }), settings, 0), flags)
        end
    end)

    it("skips a whisper from the player's own character", function()
        assert.are.equal("filtered", Handle(policy, Whisper({ isSelf = true }), settings, 0))
    end)

    describe("Exempt Senders", function()
        it("never replies to a party or raid member", function()
            assert.are.equal("exempt", Handle(policy, Whisper({ inGroup = true }), settings, 0))
        end)

        it("skips a friend or guild member while that setting is on", function()
            assert.are.equal("exempt", Handle(policy, Whisper({ isFriend = true }), settings, 0))
            assert.are.equal("exempt", Handle(policy, Whisper({ isGuildMember = true }), settings, 0))
        end)

        it("replies to a friend or guild member once that setting is off", function()
            local off = Settings({ exemptFriends = false, exemptGuild = false })
            assert.are.equal("reply", Handle(policy, Whisper({ guid = "Player-1", isFriend = true }), off, 0))
            assert.are.equal("reply", Handle(policy, Whisper({ guid = "Player-2", isGuildMember = true }), off, 0))
        end)

        it("skips a Sender who answers the player's own whisper", function()
            policy:RecordWhisperSent("Player-1", settings, 0)
            assert.are.equal("exempt", Handle(policy, Whisper({ text = "yes, summon pls" }), settings, 14 * MINUTE))
        end)

        it("replies to that Sender once the conversation is older than the Cooldown length", function()
            policy:RecordWhisperSent("Player-1", settings, 0)
            assert.are.equal("reply", Handle(policy, Whisper(), settings, 15 * MINUTE))
        end)
    end)

    describe("Cooldown", function()
        it("stops two auto-responders after one exchange", function()
            assert.are.equal("reply", Handle(policy, Whisper(), settings, 0))
            local echo = "Auto-reply: " .. Config.FormatReply(settings, true)
            assert.are.equal("cooldown", Handle(policy, Whisper({ text = echo }), settings, 1))
        end)

        it("gives the same Sender one Reply inside the Cooldown", function()
            assert.are.equal("reply", Handle(policy, Whisper(), settings, 0))
            assert.are.equal("cooldown", Handle(policy, Whisper(), settings, 14 * MINUTE))
        end)

        it("replies again once the Cooldown ends", function()
            assert.are.equal("reply", Handle(policy, Whisper(), settings, 0))
            assert.are.equal("reply", Handle(policy, Whisper(), settings, 15 * MINUTE))
        end)

        it("uses the configured length", function()
            local short = Settings({ cooldownMinutes = 1 })
            assert.are.equal("reply", Handle(policy, Whisper(), short, 0))
            assert.are.equal("reply", Handle(policy, Whisper(), short, 1 * MINUTE))
        end)

        it("keeps each Sender separate", function()
            assert.are.equal("reply", Handle(policy, Whisper({ guid = "Player-1", sender = "First" }), settings, 0))
            assert.are.equal("reply", Handle(policy, Whisper({ guid = "Player-2", sender = "Second" }), settings, 1))
        end)

        it("knows a Sender by GUID, whatever form the name takes", function()
            assert.are.equal("reply", Handle(policy, Whisper({ sender = "First Last" }), settings, 0))
            assert.are.equal("cooldown", Handle(policy, Whisper({ sender = "First Last-Realm" }), settings, 1))
        end)

        it("keeps a live Cooldown when it clears expired ones", function()
            assert.are.equal("reply", Handle(policy, Whisper({ guid = "Player-1" }), settings, 0))
            assert.are.equal("reply", Handle(policy, Whisper({ guid = "Player-2" }), settings, 10 * MINUTE))
            assert.are.equal("reply", Handle(policy, Whisper({ guid = "Player-3" }), settings, 20 * MINUTE))
            assert.are.equal("cooldown", Handle(policy, Whisper({ guid = "Player-2" }), settings, 21 * MINUTE))
        end)
    end)

    describe("Rate Limit", function()
        it("allows five Replies in five minutes and holds back the sixth", function()
            for i = 1, 5 do
                assert.are.equal("reply", Handle(policy, Whisper({ guid = "Player-" .. i }), settings, i * 10))
            end
            assert.are.equal("rate-limit", Handle(policy, Whisper({ guid = "Player-6" }), settings, 60))
        end)

        it("frees a slot once the oldest Reply leaves the window", function()
            for i = 1, 5 do
                Handle(policy, Whisper({ guid = "Player-" .. i }), settings, i * 10)
            end
            assert.are.equal("rate-limit", Handle(policy, Whisper({ guid = "Player-6" }), settings, 5 * MINUTE + 9))
            assert.are.equal("reply", Handle(policy, Whisper({ guid = "Player-6" }), settings, 5 * MINUTE + 10))
        end)
    end)
end)
