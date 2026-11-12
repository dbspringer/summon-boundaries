-- Pure Lua: no WoW API calls, so the specs can load this file directly.
-- The shell passes the client facts in `context`: isWarlock, knowsSummon, and version.
-- Run returns the lines to print, and "options" as a second value when the shell should open the panel.
local _, ns = ...
local L = ns.L
local Options = ns.Options

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
    L["/sb options: open the settings panel."],
    L["/sb reset: set everything back to the defaults, with auto-replies off."],
}

local SWITCH = { on = true, off = false }

-- The shell opens the settings panel when Run returns this action.
local OPEN_OPTIONS = { options = true, config = true, settings = true }

local function Append(lines, more)
    for _, line in ipairs(more) do
        lines[#lines + 1] = line
    end
    return lines
end

local function ReplyLine(settings, context)
    return L["Reply: %s"]:format(Options.ShownReply(settings, context))
end

local function WarlockNote(lines, context)
    if not context.isWarlock then
        lines[#lines + 1] = L["Auto-replies only run on your warlocks."]
    end
    return lines
end

-- The lines for a setter's result: the refusal reason, or the confirmation and any warnings.
local function ResultLines(result, confirmation)
    if not result.saved then
        return { result.reason }
    end
    return Append({ confirmation }, result.warnings)
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
    local key, confirmation = "messageNoFee", L["Reply without the Fee set."]
    if settings.mentionFee then
        key, confirmation = "message", L["Reply with the Fee set."]
    end
    local lines = ResultLines(Options.SetText(settings, key, text), confirmation)
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
        local confirmation = switch and L["The Fee is on."] or L["The Fee is off."]
        lines = ResultLines(Options.SetFeeShown(settings, switch), confirmation)
    else
        lines = ResultLines(Options.SetFee(settings, argument), L["Fee set to %s."]:format(argument))
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
    local result = Options.SetCooldown(settings, argument)
    return ResultLines(result, L["Cooldown set to %d minutes."]:format(settings.cooldownMinutes))
end

local function Reset(settings)
    Options.Reset(settings)
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
        return { L["Test, sent to no one: %s"]:format(Options.ShownReply(settings, context)) }
    elseif OPEN_OPTIONS[command] then
        return {}, "options"
    end
    return Append({ L["Unknown command: %s."]:format(word) }, HELP)
end
