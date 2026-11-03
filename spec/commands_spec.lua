local ns = {}
for _, file in ipairs({ "locales/enUS.lua", "src/Config.lua", "src/Commands.lua" }) do
    assert(loadfile(file))("SummonBoundaries", ns)
end
local Config = ns.Config
local Commands = ns.Commands

local WARLOCK = { isWarlock = true, knowsSummon = true, version = "dev" }
local LOW_LEVEL_WARLOCK = { isWarlock = true, knowsSummon = false, version = "dev" }
local MAGE = { isWarlock = false, knowsSummon = false, version = "dev" }

local function Output(lines)
    return table.concat(lines, "\n")
end

local function Shows(lines, text)
    return Output(lines):find(text, 1, true) ~= nil
end

describe("/sb", function()
    local settings

    before_each(function()
        settings = Config.ApplyDefaults(nil)
    end)

    local function Run(input, context)
        return Commands.Run(input, settings, context or WARLOCK)
    end

    describe("status", function()
        it("tells a new player how to turn auto-replies on", function()
            local lines = Run("")
            assert.is_true(Shows(lines, "Auto-replies are off. Type /sb on to turn them on."))
            assert.is_true(Shows(lines, "Type /sb help for commands."))
        end)

        it("shows the Reply a stranger would get", function()
            assert.is_true(Shows(Run(""), Config.FormatReply(settings, true)))
            assert.is_true(Shows(Run("", LOW_LEVEL_WARLOCK), Config.DEFAULTS.messageNoSpell))
        end)

        it("on another class, says auto-replies only run on warlocks and shows a warlock's Reply", function()
            local lines = Run("", MAGE)
            assert.is_true(Shows(lines, "Auto-replies only run on your warlocks."))
            assert.is_true(Shows(lines, Config.FormatReply(settings, true)))
        end)
    end)

    describe("on and off", function()
        it("turns auto-replies on and off", function()
            Run("on")
            assert.is_true(settings.enabled)
            Run("OFF")
            assert.is_false(settings.enabled)
        end)

        it("work on another class, with a note", function()
            local lines = Run("on", MAGE)
            assert.is_true(settings.enabled)
            assert.is_true(Shows(lines, "Auto-replies only run on your warlocks."))
        end)
    end)

    describe("message", function()
        it("sets the Reply with the Fee while the Fee is on", function()
            Run("message Bring {fee} and two friends.")
            assert.are.equal("Bring {fee} and two friends.", settings.message)
            assert.are.equal(Config.DEFAULTS.messageNoFee, settings.messageNoFee)
        end)

        it("sets the Reply without the Fee while the Fee is off", function()
            settings.mentionFee = false
            Run("message Bring two friends.")
            assert.are.equal("Bring two friends.", settings.messageNoFee)
            assert.are.equal(Config.DEFAULTS.message, settings.message)
        end)

        it("keeps the case of the text", function()
            Run("MESSAGE Bring {fee}, Please")
            assert.are.equal("Bring {fee}, Please", settings.message)
        end)

        it("refuses empty text", function()
            local lines = Run("message   ")
            assert.are.equal(Config.DEFAULTS.message, settings.message)
            assert.is_true(Shows(lines, "Type /sb message followed by the text of your Reply."))
        end)

        it("warns when the Fee is on but the text has no {fee}", function()
            local lines = Run("message Bring two friends.")
            assert.are.equal("Bring two friends.", settings.message)
            assert.is_true(Shows(lines, "Your text has no {fee}, so the Fee won't show."))
        end)

        it("warns when the Reply is too long to send whole", function()
            local lines = Run("message {fee} " .. ("a"):rep(300))
            assert.is_true(Shows(lines, "Your Reply is 303 bytes. Strangers get only the first 255."))
        end)
    end)

    describe("fee", function()
        it("sets the Fee and turns it on", function()
            settings.mentionFee = false
            local lines = Run("fee 2g")
            assert.are.equal("2g", settings.fee)
            assert.is_true(settings.mentionFee)
            assert.is_true(Shows(lines, "offer 2g for the trouble"))
        end)

        it("turns the Fee on and off without changing the amount", function()
            Run("fee off")
            assert.is_false(settings.mentionFee)
            Run("fee on")
            assert.is_true(settings.mentionFee)
            assert.are.equal("1g", settings.fee)
        end)

        it("warns when a long Fee makes the Reply too long", function()
            local lines = Run("fee " .. ("9"):rep(100))
            assert.is_true(Shows(lines, "Strangers get only the first 255."))
        end)

        it("warns when turning the Fee on brings back a Reply that is too long", function()
            Run("fee " .. ("9"):rep(100))
            Run("fee off")
            assert.is_true(Shows(Run("fee on"), "Strangers get only the first 255."))
        end)

        it("warns when turning the Fee off brings in a Reply that is too long", function()
            settings.messageNoFee = ("a"):rep(300)
            assert.is_true(Shows(Run("fee off"), "Your Reply is 300 bytes."))
        end)
    end)

    it("turns the no-spell Reply on and off", function()
        Run("nospell off")
        assert.is_false(settings.noSpellReply)
        Run("nospell on")
        assert.is_true(settings.noSpellReply)
    end)

    describe("cooldown", function()
        it("sets the Cooldown in whole minutes", function()
            Run("cooldown 30")
            assert.are.equal(30, settings.cooldownMinutes)
        end)

        it("refuses a value that isn't a whole number of minutes, 1 or more", function()
            for _, value in ipairs({ "0", "-5", "2.5", "soon" }) do
                local lines = Run("cooldown " .. value)
                assert.are.equal(15, settings.cooldownMinutes, value)
                assert.is_true(Shows(lines, "The Cooldown must be a whole number of minutes, 1 or more."), value)
            end
        end)

        it("shows the current Cooldown with no value", function()
            assert.is_true(Shows(Run("cooldown"), "Cooldown: 15 minutes."))
        end)
    end)

    it("resets every setting to its default, with auto-replies off", function()
        Run("on")
        Run("fee 5g")
        Run("cooldown 60")
        Run("message Go away.")
        local lines = Run("reset")
        assert.are.same(Config.ApplyDefaults(nil), settings)
        assert.is_true(Shows(lines, "Settings reset. Auto-replies are off. Type /sb on to turn them on."))
    end)

    describe("test", function()
        it("shows the Reply here, for the warlock's own spell", function()
            assert.is_true(Shows(Run("test"), Config.FormatReply(settings, true)))
            assert.is_true(Shows(Run("test", LOW_LEVEL_WARLOCK), Config.DEFAULTS.messageNoSpell))
        end)

        it("shows a warlock's Reply on another class", function()
            assert.is_true(Shows(Run("test", MAGE), Config.FormatReply(settings, true)))
        end)
    end)

    it("names an unknown command and lists the commands", function()
        local lines = Run("dance")
        assert.is_true(Shows(lines, "Unknown command: dance."))
        assert.is_true(Shows(lines, "/sb cooldown"))
    end)
end)
