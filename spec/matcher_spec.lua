local ns = {}
assert(loadfile("src/Matcher.lua"))("SummonBoundaries", ns)
local Matcher = ns.Matcher

describe("Summon Request matching", function()
    it("matches a bare request", function()
        assert.is_true(Matcher.IsSummonRequest("summon"))
    end)

    it("finds the keyword inside a sentence with punctuation", function()
        assert.is_true(Matcher.IsSummonRequest("can you summon me?"))
        assert.is_true(Matcher.IsSummonRequest("any chance of a summon?"))
    end)

    it("ignores case", function()
        assert.is_true(Matcher.IsSummonRequest("SUMMON!!"))
        assert.is_true(Matcher.IsSummonRequest("Summon pls"))
    end)

    it("matches the short forms and other forms of the word", function()
        for _, text in ipairs({ "sum pls", "summ?", "summo plz", "any summons?", "summoning anyone?" }) do
            assert.is_true(Matcher.IsSummonRequest(text), text)
        end
    end)

    it("leaves words that only contain a keyword alone", function()
        for _, text in ipairs({ "summary?", "see you at the summit", "consume", "assume so", "sumac", "nice mount" }) do
            assert.is_false(Matcher.IsSummonRequest(text), text)
        end
    end)
end)
