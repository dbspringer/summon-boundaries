# Summon Boundaries

A WoW: Forever addon that answers unsolicited summon requests with one firm whisper. It never summons, invites, queues, or collects payment.

## Language

**Summon Request**:
A whisper from another player that asks the player to summon them, such as "sum pls" or "any chance of a summon?".
_Avoid_: Summon whisper, request, ask

**Reply**:
The one whisper the addon sends back to a Summon Request. Its text is a setting, and `{fee}` in it stands for the Fee.
_Avoid_: Response, auto-response, answer

**Sender**:
The character a whisper comes from. Two whispers have the same Sender only when the same character sends them, whatever form the name takes.
_Avoid_: Player, name, author

**Fee**:
The compensation the Reply suggests, as text the player writes, such as `1g`. The addon never checks that anyone pays it.
_Avoid_: Price, payment, tip

**Clickers**:
The two other players a Ritual of Summoning needs to click the portal.
_Avoid_: Helpers, assistants

**Exempt Sender**:
A Sender who never gets a Reply: a party or raid member always, and a friend (a Battle.net friend's character too) or guild member when that setting is on.
_Avoid_: Whitelist, allow list

**Cooldown**:
The time after a Reply during which the same sender gets no other Reply.
_Avoid_: Timeout, throttle

**Rate Limit**:
The cap on Replies to all senders together in a time window.
_Avoid_: Throttle, flood control

**Chat Lockdown**:
A client state in which the text and sender of a whisper are secret values that addon code can't read. The addon sends nothing while it lasts.
_Avoid_: Combat lockdown (a different restriction, on protected frames)

**Decision**:
What the core returns for one whisper: send the Reply, or the reason it doesn't (disabled, filtered, loop, no match, exempt, cooldown, rate limit, lockdown).
_Avoid_: Result, verdict
