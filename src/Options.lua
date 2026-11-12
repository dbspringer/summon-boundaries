-- Pure Lua: no WoW API calls, so the specs can load this file directly.
-- The rules for a changed setting, shared by /sb and the settings panel. Each setter returns
-- { saved = true, warnings = {...} } or { saved = false, reason = "..." }, with ns.L strings.
local _, ns = ...
local L = ns.L
local Config = ns.Config
local Matcher = ns.Matcher

local Options = {}
ns.Options = Options

local function Saved(warnings)
    return { saved = true, warnings = warnings or {} }
end

local function Refused(reason)
    return { saved = false, reason = reason }
end

-- One line, with no spaces at the ends: a whisper can't hold a line break.
local function Clean(text)
    return (text:gsub("[\r\n]+", " "):match("^%s*(.-)%s*$"))
end

-- Warns when this Reply text, with the Fee in place, is too long to send whole.
local function AddLengthWarning(warnings, settings, template)
    local _, fullLength = Config.FormatText(settings, template)
    if fullLength > Config.MAX_MESSAGE_LENGTH then
        warnings[#warnings + 1] = L["Your Reply is %d bytes. Strangers get only the first %d."]:format(
            fullLength,
            Config.MAX_MESSAGE_LENGTH
        )
    end
    return warnings
end

-- The text a stranger gets while the Fee switch is as it is now, if the warlock knows the spell.
local function FeeSwitchText(settings)
    return settings.mentionFee and settings.message or settings.messageNoFee
end

-- key: "message" (with the Fee), "messageNoFee", or "messageNoSpell".
function Options.SetText(settings, key, text)
    text = Clean(text)
    if text == "" then
        return Refused(L["The Reply can't be empty."])
    end
    settings[key] = text
    local warnings = {}
    if key == "message" and not text:find("{fee}", 1, true) then
        warnings[#warnings + 1] = L["Your text has no {fee}, so the Fee won't show."]
    end
    return Saved(AddLengthWarning(warnings, settings, text))
end

-- Setting an amount also turns the Fee on: a player who sets one wants strangers to see it.
function Options.SetFee(settings, amount)
    amount = Clean(amount)
    if amount == "" then
        return Refused(L["The Fee can't be empty."])
    end
    settings.fee = amount
    settings.mentionFee = true
    return Saved(AddLengthWarning({}, settings, settings.message))
end

-- Either way, the switch changes which text goes out, so the new one gets the length check.
function Options.SetFeeShown(settings, shown)
    settings.mentionFee = shown
    return Saved(AddLengthWarning({}, settings, FeeSwitchText(settings)))
end

function Options.SetCooldown(settings, value)
    value = Clean(value)
    -- Digits only, so a sign, a decimal point, or an exponent never gets through.
    local minutes = value:find("^%d+$") and tonumber(value)
    if not minutes or minutes < 1 then
        return Refused(L["The Cooldown must be a whole number of minutes, 1 or more."])
    end
    settings.cooldownMinutes = minutes
    return Saved()
end

-- Any text saves. An empty list falls back to the built-in keywords (Matcher.ActiveKeywords).
function Options.SetKeywords(settings, text)
    settings.keywords = text
    local warnings = {}
    if #Matcher.ParseKeywords(text) == 0 then
        warnings[#warnings + 1] = L["No keywords, so the built-in list is used."]
    end
    return Saved(warnings)
end

-- Every setting back to its default, auto-replies too, as on a new install.
function Options.Reset(settings)
    for key, value in pairs(Config.DEFAULTS) do
        settings[key] = value
    end
end

-- The Reply a stranger would get from this character. Another class shows a trained warlock's Reply,
-- since auto-replies only run on a warlock. context comes from the shell: isWarlock, knowsSummon.
function Options.ShownReply(settings, context)
    return (Config.FormatReply(settings, context.knowsSummon or not context.isWarlock))
end
