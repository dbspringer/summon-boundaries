local ns = {}
assert(loadfile("locales/enUS.lua"))("SummonBoundaries", ns)
assert(loadfile("src/Config.lua"))("SummonBoundaries", ns)
local Config = ns.Config

local function SettingsWith(overrides)
    local settings = Config.ApplyDefaults(nil)
    for key, value in pairs(overrides) do
        settings[key] = value
    end
    return settings
end

describe("Settings", function()
    it("stay off on a first install, until the player opts in", function()
        assert.is_false(Config.ApplyDefaults(nil).enabled)
    end)

    it("keep what the player set across a reload, and fill in new keys", function()
        local saved = Config.ApplyDefaults({ enabled = true, fee = "5g", cooldownMinutes = 30 })
        assert.is_true(saved.enabled)
        assert.are.equal("5g", saved.fee)
        assert.are.equal(30, saved.cooldownMinutes)
        assert.are.equal(Config.DEFAULTS.message, saved.message)
    end)

    it("fall back to the default for a value of the wrong type", function()
        local saved = Config.ApplyDefaults({ cooldownMinutes = "soon" })
        assert.are.equal(Config.DEFAULTS.cooldownMinutes, saved.cooldownMinutes)
    end)
end)

describe("Reply", function()
    it("puts the fee in place of {fee}", function()
        local reply = Config.FormatReply(SettingsWith({ fee = "2g" }))
        assert.truthy(reply:find("offer 2g for the trouble", 1, true))
        assert.falsy(reply:find("{fee}", 1, true))
    end)

    it("uses the no-fee text when the fee is off", function()
        local reply = Config.FormatReply(SettingsWith({ fee = "2g", mentionFee = false }))
        assert.are.equal(Config.DEFAULTS.messageNoFee, reply)
    end)

    it("inserts a fee with % as plain text", function()
        local reply = Config.FormatReply(SettingsWith({ fee = "50%", message = "pay {fee}" }))
        assert.are.equal("pay 50%", reply)
    end)

    it("cuts an over-long reply to the chat limit on a character boundary", function()
        -- "é" is two bytes, and 254 ASCII bytes put its first byte at position 255.
        local reply = Config.FormatReply(SettingsWith({ message = ("a"):rep(254) .. "é tail" }))
        assert.are.equal(("a"):rep(254), reply)
    end)
end)
