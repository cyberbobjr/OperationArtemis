# Changelog

This changelog starts with the initial repository snapshot. Earlier development
is summarized below rather than reconstructed as separate releases.

## 0.3.2 — 2026-10-09

### Fixed

- Singleplayer: a walkie-talkie switched on and clipped to the belt received the ARTEMIS broadcasts but showed nothing on screen. Each line is shown again above your character, once, as with a radio in hand.
- Multiplayer: a radio carried in the main inventory but not held (belt included) now also shows the lines it receives above your character, once, instead of only in the radio chat: ARTEMIS and every other channel on its frequency. Messages from other players stay in the radio chat. Nothing is added when Better Walkie Talkies is active.

## 0.3.1 — 2026-10-07

### Fixed

- Multiplayer: the Artemis notebook now shows the radio frequency again and opens in each reader's own language. Notebooks already found are fixed when read.
- Multiplayer: the ARTEMIS broadcasts, the name of V's stash map, Miller's ID card and the Computer Mod disc and laptop no longer show raw translation keys such as `IGUI_Artemis_...`.

### Known limits

- In multiplayer, these broadcasts and item names use the server's language, not each player's. Items placed before this update keep the names they were given.

## 0.3.0 — 2026-10-04

### Added

- The story is now translated into German, Spanish, Portuguese, Brazilian Portuguese, Russian, Turkish, Simplified Chinese, Japanese and Korean, in addition to English and French: radio broadcasts, V's lines, thoughts, journal, objectives, endings, item names and sandbox options.
- In German, Spanish, Portuguese, Brazilian Portuguese, Russian and Turkish, the documents you find are translated too, with their layout kept.

### Known limits

- In Chinese, Japanese and Korean, the documents stay in English: the game's document fonts have no glyphs for these languages. Their English titles are given in the journal and objectives.
- The voiced endings remain in English and French.

## 0.2.0 — 2026-10-04

First release on the Steam Workshop, for Project Zomboid Build 42.21. Requires Signal Smoke.

### Added

- A story-driven investigation across Knox County: a bloodstained notebook found on military infected, the ARTEMIS broadcast on 108.0 MHz, and a voice called V.
- Four sites to search: the March Ridge bunker, the West Point clinic, the KY-7 radio relay and a secret underground base, with readable documents and a journal.
- A laboratory escape: the dossier sets off the alarm and the base wakes up.
- Three ways out of the Exclusion Zone (helicopter, ferryman on the river, checkpoint), each with its own ending, victory screen and voiced epilogue in English or French.
- An optional sterilization countdown, plus sandbox settings for discovery, intensity and extraction timing.

### Known limits

- Tested in singleplayer. Multiplayer, boat-mod routes and optional integrations still need their own validation.

## 0.1.0 — 2026-10-04

Initial development snapshot for Project Zomboid Build 42.21; not a Steam
Workshop release.

### Added

- A story-driven end-game investigation across Knox County, starting with a
  notebook found on military infected and the ARTEMIS broadcast on 108.0 MHz.
- A bunker, clinic, radio relay and secret base investigation with readable
  evidence, journal entries, map reveals, security access and a laboratory escape.
- Helicopter, ferryman and checkpoint evacuation routes, plus optional routes
  using supported boat mods.
- A victory screen, chronicle and route-specific epilogues with French and
  English narration and music.
- An optional sterilization countdown and sandbox settings for discovery,
  intensity and extraction timing.
- Signal Smoke support as a required dependency, and optional integrations
  documented in the project.
- Workshop artwork, descriptions in eleven languages, production sources and
  a 31-scenario PZPuppeteer test campaign.

### Fixed and adjusted during development

- Valid military radio calls now reach the helicopter and ferryman evacuation
  services instead of being rejected as a missing device.
- Checkpoint quarantine lasts at most one in-game hour, with an incident at
  thirty minutes, whether or not the player carries the dossier.
- Relay guard Miller placement and radio text readability were corrected and
  checked in the recorded singleplayer campaign.
- The initial ending screen clears nearby loaded zombies on the same floor in
  singleplayer; reopening the ending from the journal does not repeat this action.

### Validation and known limits

- Existing campaign records report successful singleplayer helicopter, ferryman
  and checkpoint endings on Build 42.21. They also record ending persistence
  after complete game restarts for helicopter and ferryman.
- These records cover their stated test conditions. Debug placement used in
  preparation does not validate natural access to every location; the exterior
  entrance to the secret base remains outside that coverage.
- Multiplayer, boat routes, optional integrations, a missed extraction,
  the full sterilization countdown and several alternate checkpoint branches
  still require dedicated in-game validation.
- See [campaign results](tests/puppeteer/RESULTATS.md) for scenario coverage and
  [test instructions](tests/puppeteer/README.md) for reproduction procedures.
  Raw local reports are excluded from Git by the existing `.gitignore`.
