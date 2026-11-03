local ns = {}
assert(loadfile("src/Matcher.lua"))("SummonBoundaries", ns)
local Matcher = ns.Matcher

local BUILT_IN = { customKeywords = false, keywords = Matcher.BUILT_IN_KEYWORDS }

local function Matches(text, settings)
    return Matcher.IsSummonRequest(text, Matcher.ActiveKeywords(settings or BUILT_IN))
end

describe("Summon Request matching", function()
    it("matches a bare request", function()
        assert.is_true(Matches("summon"))
    end)

    it("finds the keyword inside a sentence with punctuation", function()
        assert.is_true(Matches("can you summon me?"))
        assert.is_true(Matches("any chance of a summon?"))
    end)

    it("ignores case", function()
        assert.is_true(Matches("SUMMON!!"))
        assert.is_true(Matches("Summon pls"))
    end)

    it("matches the short forms, misspellings, and other forms of the word", function()
        local texts = { "sum pls", "summ?", "summo plz", "any summons?", "summoning anyone?", "smn?", "sumon pls" }
        for _, text in ipairs(texts) do
            assert.is_true(Matches(text), text)
        end
    end)

    it("matches a phrase as whole words", function()
        assert.is_true(Matches("lock port pls"))
        assert.is_true(Matches("any warlock port to ZG?"))
        assert.is_true(Matches("Warlock-port?"))
    end)

    it("leaves words that only contain a keyword alone", function()
        for _, text in ipairs({ "summary?", "see you at the summit", "consume", "assume so", "sumac", "nice mount" }) do
            assert.is_false(Matches(text), text)
        end
    end)

    it("leaves a portal and a raid code alone", function()
        for _, text in ipairs({ "port to org?", "the warlock portal is up", "1", "123" }) do
            assert.is_false(Matches(text), text)
        end
    end)

    describe("with the player's own keywords", function()
        it("uses them in place of the built-in list", function()
            local settings = { customKeywords = true, keywords = "beam me up, teleport" }
            assert.is_true(Matches("Beam me up!", settings))
            assert.is_true(Matches("teleport pls", settings))
            assert.is_false(Matches("summon?", settings))
        end)

        it("ignores them while the override is off", function()
            local settings = { customKeywords = false, keywords = "beam me up" }
            assert.is_false(Matches("beam me up", settings))
            assert.is_true(Matches("summon?", settings))
        end)

        it("falls back to the built-in list when the player's list is empty", function()
            assert.is_true(Matches("summon?", { customKeywords = true, keywords = " , ,  " }))
        end)

        it("matches a keyword of two characters or fewer only as the whole message", function()
            local settings = { customKeywords = true, keywords = "1" }
            assert.is_true(Matches("1", settings))
            assert.is_true(Matches(" 1! ", settings))
            assert.is_false(Matches("I have 1 question", settings))
        end)

        it("counts letters, not bytes, for that rule", function()
            -- Each Cyrillic letter is two bytes in UTF-8, so this keyword is 2 letters and 4 bytes.
            local settings = { customKeywords = true, keywords = "тп" }
            assert.is_true(Matches("тп", settings))
            assert.is_false(Matches("дай тп плиз", settings))
        end)

        it("follow an edit to the list", function()
            local settings = { customKeywords = true, keywords = "beam me up" }
            assert.is_true(Matches("beam me up", settings))
            settings.keywords = "teleport"
            assert.is_false(Matches("beam me up", settings))
            assert.is_true(Matches("teleport", settings))
        end)
    end)
end)
