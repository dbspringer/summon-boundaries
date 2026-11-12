std = "lua51"
max_line_length = 120
self = false

exclude_files = { ".release/" }

globals = {
  "SLASH_SUMMONBOUNDARIES1",
  "SlashCmdList",
  "SummonBoundariesDB",
}

read_globals = {
  "C_AddOns",
  "C_BattleNet",
  "C_ChatInfo",
  "C_SpellBook",
  "C_Timer",
  "C_FriendList",
  "C_PartyInfo",
  "CreateFrame",
  "DEFAULT_CHAT_FRAME",
  "GameFontHighlightSmall",
  "GetTime",
  "IsGuildMember",
  "issecretvalue",
  "Settings",
  "UnitClass",
  "UnitGUID",
}

files["spec"] = { std = "+busted" }
-- A translated sentence can't wrap.
files["locales"] = { max_line_length = false }
