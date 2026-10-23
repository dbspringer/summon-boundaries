# Summon Boundaries

Being a warlock doesn't make you a free, on-demand taxi service.

Summon Boundaries is a small WoW: Forever addon for warlocks who get whispered by strangers asking for a summon. It answers each request once, with a short and firm reply, so you don't have to type the same thing every time.

**Status:** not released yet. The first version is in progress, and this page describes what it'll do.

## Why

A summon needs two other players to click the portal, and it pulls all three of you away from whatever you were doing. Most requests come from strangers who haven't found anyone to click or offered anything for the trouble. Summon Boundaries says so for you, politely, and then gets out of the way.

## What it does

- Spots whispers that ask for a summon, like "summon?", "sum pls", or "any chance of a summon?", and leaves everything else alone ("summary" and "summit" don't count)
- Replies once with your message. The default is: "A summon requires two other players, not just a warlock. If you'd like one, please arrange two clickers and offer 1g for the trouble. Otherwise, please make your own way here."
- Never replies to your party or raid, and by default skips your friends and guild too
- Waits 15 minutes before it'll reply to the same player again, and caps how many replies it sends overall, so it can't turn into a spam source
- Stays quiet in dungeons and encounters while the game locks down chat for addons
- Does nothing until you turn it on

It never summons, invites, keeps a queue, or checks that anyone pays.

## How to use it

Type `/sb` to see your settings and the reply people will get. Auto-replies start off, so type `/sb on` when you're ready.

| Command | What it does |
| --- | --- |
| `/sb` | Shows help and your current settings |
| `/sb on`, `/sb off` | Turns auto-replies on or off |
| `/sb fee 2g` | Changes the fee in the reply |
| `/sb fee off`, `/sb fee on` | Leaves the fee out of the reply, or puts it back |
| `/sb cooldown 20` | Sets how many minutes to wait before replying to the same player again |
| `/sb message <text>` | Sets your own reply. Put `{fee}` where the fee goes |
| `/sb reset` | Restores the default settings (auto-replies stay off) |
| `/sb test` | Shows the reply in your own chat window, without whispering anyone |

Right now only `/sb` works. The rest arrives with the first release.

## Good to know

- Built for WoW: Forever (the 1.60 client). Other versions of WoW aren't supported.
- To keep other players' names off your disk, the addon forgets who it replied to when you reload or log out. Someone who just got a reply could get one more after a `/reload`.
- Replies are cut at 255 characters, the game's limit for one chat message.

## Bugs and ideas

Open an issue at [github.com/dbspringer/summon-boundaries](https://github.com/dbspringer/summon-boundaries/issues).

## Develop

Symlink the repo as `SummonBoundaries` into your Forever client's AddOns folder (`_forever_/Interface/AddOns`). Lint with `luacheck .` and run the specs with `busted` (on Lua 5.1 or LuaJIT, since that's what WoW runs). The decision logic in `src/` calls no WoW API, so the specs can feed it mock whispers.

Releases are plain numbers that go up by one each time (`1`, `2`, `3`), and pushing that number as a tag cuts the release with the BigWigs packager. `./export.sh <version> [destination]` builds the same zip by hand, for example `./export.sh 1 ~/Desktop`. It ships exactly the files the TOC loads, plus the license.

Every release gets an entry in `CHANGELOG.md`, and the packager uses that file for the release notes.

## License

MIT licensed. See [LICENSE](LICENSE).
