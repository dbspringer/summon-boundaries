-- Shell: the settings panel at Esc > Options > AddOns > Summon Boundaries. Every rule lives in Options;
-- this file lays out the controls, saves through Options, and shows the result. It has no spec, so the
-- in-game checklist is its test (Settings Panel Plan, decision 8).
local _, ns = ...
local L = ns.L
local Matcher = ns.Matcher
local Options = ns.Options

local Panel = {}
ns.Panel = Panel

local CONTENT_WIDTH = 560
local TEXT_BOX_HEIGHT = 56
local MARGIN = 16

local RED = { 1, 0.3, 0.3 }
local YELLOW = { 1, 0.82, 0 }

-- The canvas scrolls: the controls sit on `content`, the scroll child, which can be taller than the window.
local canvas = CreateFrame("Frame")
local scroll = CreateFrame("ScrollFrame", nil, canvas, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, -4)
scroll:SetPoint("BOTTOMRIGHT", -28, 4)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(CONTENT_WIDTH + 2 * MARGIN, 1000)
scroll:SetScrollChild(content)

-- Each control has a refresh function that shows the saved value; Refresh runs them all.
local refreshers = {}
-- True while Refresh sets controls, so their scripts don't save what they're shown.
local syncing = false
local Refresh

local last -- the lowest region so far; each new one goes under it
local messages = {} -- every message line, cleared when the panel opens

local function Place(region, gap, x)
    if last then
        region:SetPoint("TOPLEFT", last, "BOTTOMLEFT", x or 0, -(gap or 8))
    else
        region:SetPoint("TOPLEFT", content, "TOPLEFT", MARGIN, -MARGIN)
    end
    last = region
    return region
end

local function Text(font, text, gap)
    local label = content:CreateFontString(nil, "ARTWORK", font)
    label:SetWidth(CONTENT_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return Place(label, gap)
end

-- A line under a field for a refusal (red) or a warning (yellow). Empty and zero-height when unused.
local function Message(gap)
    local line = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    line:SetWidth(CONTENT_WIDTH)
    line:SetJustifyH("LEFT")
    Place(line, gap or 2)
    messages[#messages + 1] = line
    function line:ShowResult(result)
        if not result.saved then
            self:SetTextColor(unpack(RED))
            self:SetText(result.reason)
        else
            self:SetTextColor(unpack(YELLOW))
            self:SetText(table.concat(result.warnings, " "))
        end
    end
    function line:Clear()
        self:SetText("")
    end
    return line
end

-- onClick, if given, saves through Options and returns its result, shown on a message line.
local function Checkbox(label, key, onClick)
    local box = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    box.label = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    box.label:SetPoint("LEFT", box, "RIGHT", 2, 0)
    box.label:SetText(label)
    box:SetScript("OnClick", function(self)
        if syncing then
            return
        end
        local checked = self:GetChecked() and true or false
        if onClick then
            local result = onClick(checked)
            Refresh()
            self.message:ShowResult(result)
        else
            ns.settings[key] = checked
            Refresh()
        end
    end)
    refreshers[#refreshers + 1] = function()
        box:SetChecked(ns.settings[key])
    end
    Place(box, 4)
    if onClick then
        box.message = Message()
    end
    return box
end

-- Saves the field when it loses focus (Enter clears focus), unless the text is the saved value.
-- Escape puts the saved value back. A refused value goes back to the saved one.
local function WireField(edit, key, save, message)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEnterPressed", edit.ClearFocus)
    edit:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(ns.settings[key]))
        message:Clear()
        self:ClearFocus()
    end)
    edit:SetScript("OnEditFocusLost", function(self)
        local text = self:GetText()
        if text == tostring(ns.settings[key]) then
            return
        end
        local result = save(ns.settings, text)
        Refresh()
        message:ShowResult(result)
    end)
    refreshers[#refreshers + 1] = function()
        edit:SetText(tostring(ns.settings[key]))
        edit:SetCursorPosition(0)
    end
end

-- A one-line field to the right of its label.
local function Field(label, key, width, save, numeric)
    local title = Text("GameFontNormal", label, 12)
    title:SetWidth(0)
    local edit = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    edit:SetSize(width, 22)
    edit:SetPoint("LEFT", title, "RIGHT", 16, 0)
    edit:SetNumeric(numeric or false)
    WireField(edit, key, save, Message(8))
    return edit
end

-- A multi-line field under its label, in a bordered box that scrolls.
local function TextBox(label, key, save)
    Text("GameFontNormal", label, 12)
    local frame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    frame:SetSize(CONTENT_WIDTH, TEXT_BOX_HEIGHT)
    Place(frame, 4)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.6)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    local boxScroll = CreateFrame("ScrollFrame", nil, frame)
    boxScroll:SetPoint("TOPLEFT", 7, -6)
    boxScroll:SetPoint("BOTTOMRIGHT", -7, 6)
    local edit = CreateFrame("EditBox", nil, boxScroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetWidth(CONTENT_WIDTH - 14)
    edit:SetMaxLetters(500)
    boxScroll:SetScrollChild(edit)
    -- Keeps the cursor's line in view while typing.
    edit:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local top, bottom = -y, -y + height
        local offset, visible = boxScroll:GetVerticalScroll(), boxScroll:GetHeight()
        if top < offset then
            boxScroll:SetVerticalScroll(top)
        elseif bottom > offset + visible then
            boxScroll:SetVerticalScroll(bottom - visible)
        end
    end)
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function()
        edit:SetFocus()
    end)
    local message = Message()
    WireField(edit, key, save, message)
    return edit, message
end

local function SaveText(key)
    return function(settings, text)
        return Options.SetText(settings, key, text)
    end
end

-- Layout --------------------------------------------------------------------------------------------

Text("GameFontNormalLarge", L["Summon Boundaries"])
Text("GameFontHighlightSmall", L["Answers summon requests from strangers with one firm whisper."], 8)

Text("GameFontNormalLarge", L["General"], 20)
Checkbox(L["Answer summon requests from strangers"], "enabled")
Field(L["Cooldown (minutes)"], "cooldownMinutes", 60, Options.SetCooldown, true)
Checkbox(L["Skip friends, Battle.net friends' characters too"], "exemptFriends")
Checkbox(L["Skip guild members"], "exemptGuild")

Text("GameFontNormalLarge", L["Reply"], 20)
Field(L["Fee"], "fee", 120, Options.SetFee)
Checkbox(L["Mention the Fee"], "mentionFee", function(checked)
    return Options.SetFeeShown(ns.settings, checked)
end)
TextBox(L["Reply with the Fee ({fee} stands for the Fee)"], "message", SaveText("message"))
TextBox(L["Reply without the Fee"], "messageNoFee", SaveText("messageNoFee"))
Checkbox(L["Say so when this warlock hasn't learned Ritual of Summoning"], "noSpellReply")
TextBox(L["Reply before Ritual of Summoning"], "messageNoSpell", SaveText("messageNoSpell"))

Text("GameFontNormalLarge", L["Keywords"], 20)
Checkbox(L["Use my own keywords"], "customKeywords")
local _, keywordMessage = TextBox(L["Keywords, separated by commas"], "keywords", Options.SetKeywords)
refreshers[#refreshers + 1] = function()
    if #Matcher.ParseKeywords(ns.settings.keywords) == 0 then
        keywordMessage:SetTextColor(unpack(YELLOW))
        keywordMessage:SetText(L["No keywords, so the built-in list is used."])
    else
        keywordMessage:Clear()
    end
end

Text("GameFontNormalLarge", L["Preview"], 20)
local warlockNote = Text("GameFontHighlightSmall", "", 4)
local preview = Text("GameFontHighlight", "", 4)
refreshers[#refreshers + 1] = function()
    local context = ns.ClientContext()
    warlockNote:SetText(context.isWarlock and "" or L["Auto-replies only run on your warlocks."])
    preview:SetText(Options.ShownReply(ns.settings, context))
end

local footer = Text("GameFontDisableSmall", L["To reset everything, type /sb reset."], 20)

-- Behavior ------------------------------------------------------------------------------------------

function Refresh()
    syncing = true
    for _, refresh in ipairs(refreshers) do
        refresh()
    end
    syncing = false
end

-- Sizes the scroll child to its controls, once the window has laid the canvas out.
local function FitContent()
    content:SetWidth(math.max(1, scroll:GetWidth()))
    local top, bottom = content:GetTop(), footer:GetBottom()
    if top and bottom then
        content:SetHeight(top - bottom + MARGIN)
    end
end
scroll:HookScript("OnSizeChanged", FitContent)
canvas:HookScript("OnShow", function()
    for _, line in ipairs(messages) do
        line:Clear()
    end
    Refresh()
    FitContent()
    C_Timer.After(0, FitContent)
end)

-- The Settings UI calls these. OnDefault does nothing: a reset of Blizzard settings must not reset
-- ours, and /sb reset is the way to do that (Settings Panel Plan, decision 5).
function canvas.OnCommit() end
function canvas.OnDefault() end
function canvas.OnRefresh()
    Refresh()
end

local category = Settings.RegisterCanvasLayoutCategory(canvas, L["Summon Boundaries"])
Settings.RegisterAddOnCategory(category)

-- Returns whether the panel is on screen afterwards: the call can fail silently on Forever.
function Panel.Open()
    Settings.OpenToCategory(category:GetID())
    return canvas:IsVisible()
end
