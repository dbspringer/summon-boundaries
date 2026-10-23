# summon-boundaries

A WoW addon that answers unsolicited summon whispers with one firm Reply, for the Forever client (`_forever_`, 1.60.x, Interface 16001). It never summons, invites, queues, or collects payment.

## Agent skills

### Issue tracker

Issues are GitHub Issues on dbspringer/summon-boundaries, driven with the `gh` CLI. See `docs/agents/issue-tracker.md`. Issues are for problems that users find. Planned work and TODOs go in the vault (see Plans and research), never in an issue. This overrides any skill that says to publish work to the issue tracker.

### Triage labels

Default vocabulary: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Plans and research

Plans, research, and other working notes live in the Obsidian vault, under `Summon Boundaries/`, not in this repo. This overrides any skill that says to write such a file in the repo (for example `/research`). `CONTEXT.md` and `docs/adr/` stay in the repo.

- Use the `obsidian` CLI; the app must be open. `obsidian create path="Summon Boundaries/<Topic> Research.md" content="..."`, and also `read`, `append`, `search`.
- Name notes `<Topic> Research.md` or `<Topic> Plan.md`, and link each new note from the index note `Summon Boundaries/Summon Boundaries.md`.
- Track TODOs and planned work in the Backlog section of the index note, with a link to the plan note when one exists.
- Read the index note before you plan work, and `MVP Plan.md` for the spec, the module layout, and the test cases. The vault is at `~/Documents/Obsidian Vault`.

## Forever gotchas

- During Chat Lockdown, the text and sender of a whisper can be secret values. Check `issecretvalue` (or `C_ChatInfo.InChatMessagingLockdown()`) before any string call on them, and send nothing while they are secret (ADR 0003).
- Send with `C_ChatInfo.SendChatMessage`. The global `SendChatMessage` exists only as a deprecated fallback behind a CVar.
- Settle a client fact with an in-game test or the installed addons in `_forever_/Interface/AddOns/`, and label any fact you have not tested as unverified.

## Conventions

- The core in `src/` calls no WoW API, so `busted` runs it with mock whispers; the shell reads the client and sends the Reply (ADR 0001). Sender names stay in memory, never in SavedVariables (ADR 0002).
- Display text goes through `ns.L[...]` or a Blizzard global string, never a literal. enUS is the key, so a missing translation shows English. A translation lives in `locales/<locale>.lua`, returns early unless `GetLocale()` matches, then assigns into `ns.L`.
- Text that people read (PR titles and descriptions, commit messages, issue comments, the README) goes through the `/writing-style` skill first. Code comments and the docs under `docs/` keep a neutral, technical voice.
- A release version is a plain integer that goes up by 1 for each publish (`1`, `2`, `3`), with no `v` prefix and no semver. The tag is that number, and a pushed tag starts the release workflow. Find the next number with `git tag --sort=-v:refname | head -1`. Derek decides when to tag.
- Every release gets an entry in `CHANGELOG.md`, under a `## <number>` heading, newest first. Write it for players: what changed for them, not how. A change that players can see adds its line in the same PR, under the next number. The packager uses this file for the release notes.
