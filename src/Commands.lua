-- Pure Lua: no WoW API calls, so the specs can load this file directly.
-- The shell passes the client facts in `context`: isWarlock, knowsSummon, and version.
local _, ns = ...
local L = ns.L
local Config = ns.Config

local Commands = {}
ns.Commands = Commands

local HELP = {
    L["/sb: show your settings and Reply."],
    L["/sb on | off: turn auto-replies on or off."],
    L["/sb message <text>: set your Reply. {fee} stands for the Fee."],
    L["/sb fee <amount>: set the Fee and mention it."],
    L["/sb fee on | off: mention the Fee or not."],
    L["/sb nospell on | off: tell strangers when you haven't learned Ritual of Summoning."],
    L["/sb cooldown <minutes>: set how long each player waits for another Reply."],
    L["/sb test: show your Reply here, sent to no one."],
    L["/sb reset: set everything back to the defaults, with auto-replies off."],
}

local SWITCH = { on = true, off = false }

local function Append(lines, more)
    for _, line in ipairs(more) do
        lines[#lines + 1] = line
    end
    return lines
end

-- The Reply a stranger would get from this character. Another class shows a trained warlock's Reply,
-- since auto-replies only run on a warlock.
local function ShownReply(settings, context)
    return (Config.FormatReply(settings, context.knowsSummon or not context.isWarlock))
end

local function ReplyLine(settings, context)
    return L["Reply: %s"]:format(ShownReply(settings, context))
end

local function WarlockNote(lines, context)
    if not context.isWarlock then
        lines[#lines + 1] = L["Auto-replies only run on your warlocks."]
    end
    return lines
end

-- Warns when the text for the current Fee switch is too long to send whole.
local function LengthWarning(lines, settings)
    local _, fullLength = Config.FormatReply(settings, true)
    if fullLength > Config.MAX_MESSAGE_LENGTH then
        lines[#lines + 1] = L["Your Reply is %d bytes. Strangers get only the first %d."]:format(
            fullLength,
            Config.MAX_MESSAGE_LENGTH
        )
    end
    return lines
end

local function Status(settings, context)
    local lines = { L["Version %s"]:format(context.version) }
    if settings.enabled then
        lines[#lines + 1] = L["Auto-replies are on."]
    else
        lines[#lines + 1] = L["Auto-replies are off. Type /sb on to turn them on."]
    end
    WarlockNote(lines, context)
    if settings.mentionFee then
        lines[#lines + 1] = L["Fee: %s. Cooldown: %d minutes."]:format(settings.fee, settings.cooldownMinutes)
    else
        lines[#lines + 1] = L["Fee: off. Cooldown: %d minutes."]:format(settings.cooldownMinutes)
    end
    lines[#lines + 1] = ReplyLine(settings, context)
    lines[#lines + 1] = L["Type /sb help for commands."]
    return lines
end

local function SetEnabled(settings, context, enabled)
    settings.enabled = enabled
    local lines = { enabled and L["Auto-replies are on."] or L["Auto-replies are off."] }
    return WarlockNote(lines, context)
end

local function SetMessage(settings, context, text)
    if text == "" then
        return { L["Type /sb message followed by the text of your Reply."] }
    end
    local lines
    if settings.mentionFee then
        settings.message = text
        lines = { L["Reply with the Fee set."] }
        if not text:find("{fee}", 1, true) then
            lines[#lines + 1] = L["Your text has no {fee}, so the Fee won't show."]
        end
    else
        settings.messageNoFee = text
        lines = { L["Reply without the Fee set."] }
    end
    LengthWarning(lines, settings)
    lines[#lines + 1] = ReplyLine(settings, context)
    return lines
end

local function SetFee(settings, context, argument)
    if argument == "" then
        return { L["Type /sb fee followed by an amount, or /sb fee on or off."] }
    end
    local lines
    local switch = SWITCH[argument:lower()]
    if switch ~= nil then
        settings.mentionFee = switch
        lines = { switch and L["The Fee is on."] or L["The Fee is off."] }
    else
        settings.fee = argument
        settings.mentionFee = true
        lines = { L["Fee set to %s."]:format(argument) }
        LengthWarning(lines, settings)
    end
    lines[#lines + 1] = ReplyLine(settings, context)
    return lines
end

local function SetNoSpell(settings, argument)
    local switch = SWITCH[argument:lower()]
    if switch == nil then
        return { L["Type /sb nospell on or off."] }
    end
    settings.noSpellReply = switch
    return { switch and L["The no-spell Reply is on."] or L["The no-spell Reply is off."] }
end

local function SetCooldown(settings, argument)
    if argument == "" then
        return {
            L["Cooldown: %d minutes."]:format(settings.cooldownMinutes),
            L["Type /sb cooldown followed by a whole number of minutes, 1 or more."],
        }
    end
    -- Digits only, so a sign, a decimal point, or an exponent never gets through.
    local minutes = argument:find("^%d+$") and tonumber(argument)
    if not minutes or minutes < 1 then
        return { L["The Cooldown must be a whole number of minutes, 1 or more."] }
    end
    settings.cooldownMinutes = minutes
    return { L["Cooldown set to %d minutes."]:format(minutes) }
end

local function Reset(settings)
    for key, value in pairs(Config.DEFAULTS) do
        settings[key] = value
    end
    return { L["Settings reset. Auto-replies are off. Type /sb on to turn them on."] }
end

function Commands.Run(input, settings, context)
    local word, argument = input:match("^%s*(%S*)%s*(.-)%s*$")
    local command = word:lower()
    if command == "" then
        return Status(settings, context)
    elseif command == "help" then
        return Append({}, HELP)
    elseif SWITCH[command] ~= nil and argument == "" then
        return SetEnabled(settings, context, SWITCH[command])
    elseif command == "message" then
        return SetMessage(settings, context, argument)
    elseif command == "fee" then
        return SetFee(settings, context, argument)
    elseif command == "nospell" then
        return SetNoSpell(settings, argument)
    elseif command == "cooldown" then
        return SetCooldown(settings, argument)
    elseif command == "reset" then
        return Reset(settings)
    elseif command == "test" then
        return { L["Test, sent to no one: %s"]:format(ShownReply(settings, context)) }
    end
    return Append({ L["Unknown command: %s."]:format(word) }, HELP)
end
