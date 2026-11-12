-- The rules for a changed setting, shared by /sb and the settings panel. The /sb wording is in
-- commands_spec; these cover the rules the panel reaches without a command.
local ns = {}
for _, file in ipairs({ "locales/enUS.lua", "src/Matcher.lua", "src/Config.lua", "src/Options.lua" }) do
    assert(loadfile(file))("SummonBoundaries", ns)
end
local Config = ns.Config
local Options = ns.Options

local function Warned(result, text)
    for _, warning in ipairs(result.warnings or {}) do
        if warning:find(text, 1, true) then
            return true
        end
    end
    return false
end

describe("Options", function()
    local settings

    before_each(function()
        settings = Config.ApplyDefaults(nil)
    end)

    describe("SetText", function()
        it("refuses empty text for each Reply, and keeps the old text", function()
            for _, key in ipairs({ "message", "messageNoFee", "messageNoSpell" }) do
                local result = Options.SetText(settings, key, "  \n ")
                assert.is_false(result.saved, key)
                assert.truthy(result.reason, key)
                assert.are.equal(Config.DEFAULTS[key], settings[key], key)
            end
        end)

        it("joins lines, since a whisper is one line", function()
            Options.SetText(settings, "messageNoSpell", "  Not yet.\nSorry!  ")
            assert.are.equal("Not yet. Sorry!", settings.messageNoSpell)
        end)

        it("warns about a missing {fee} in the Reply with the Fee, even while the Fee is off", function()
            settings.mentionFee = false
            local result = Options.SetText(settings, "message", "Bring two friends.")
            assert.is_true(result.saved)
            assert.is_true(Warned(result, "{fee}"))
        end)

        it("checks the length of the text it changed, not the one in use", function()
            local result = Options.SetText(settings, "messageNoSpell", ("a"):rep(300))
            assert.is_true(result.saved)
            assert.is_true(Warned(result, "Your Reply is 300 bytes."))
        end)
    end)

    describe("SetFee", function()
        it("refuses an empty Fee", function()
            local result = Options.SetFee(settings, "   ")
            assert.is_false(result.saved)
            assert.are.equal("1g", settings.fee)
        end)

        it("saves on and off as plain text, since the panel has a checkbox for the switch", function()
            settings.mentionFee = false
            Options.SetFee(settings, "off")
            assert.are.equal("off", settings.fee)
            assert.is_true(settings.mentionFee)
        end)
    end)

    describe("SetKeywords", function()
        it("saves the list, and notes when it has no keyword", function()
            local result = Options.SetKeywords(settings, " , ")
            assert.is_true(result.saved)
            assert.are.equal(" , ", settings.keywords)
            assert.is_true(Warned(result, "No keywords, so the built-in list is used."))
        end)
    end)
end)
