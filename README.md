# Spoils of the Hunt (dlcSpoilsOfTheHunt / modSpoilsOfTheHunt)

A lore-friendly rework of the saddle trophies in The Witcher 3: Wild Hunt Remastered (game 5.x).
Each trophy grants a bonus that comes from the beast it was taken from, instead of the vanilla
+5% XP / gold / herbs. The full bonus table and reasoning is in
[docs/trophy-rework-design.md](docs/trophy-rework-design.md).

Verified in game on build 5.0.1044392 (2026-10-06): tooltips show the new stats, including the
added fire / frost resistance labels.

## What gets installed

| Game path | Contents |
|---|---|
| `DLC\dlcSpoilsOfTheHunt\content\` | `blob0.bundle` + `metadata.store` holding the override XML and the `.reddlc` that mounts it |
| `Mods\modSpoilsOfTheHunt\content\` | `blob0.bundle` + `metadata.store` with the tooltip table, loose `scripts\`, and `<lang>.w3strings` |

## Build

```powershell
.\build.ps1 -Install
```

Quit the game first; it keeps the bundles open. Requires WolvenKit 7.2.0 extracted to
`tools\WolvenKit` (only its CR2W library is used, to edit the `.reddlc`). Everything else is
PowerShell in this repo.

## Layout

| File | Purpose |
|---|---|
| `generate-sources.ps1` | **The bonus table.** Writes the override XML into `src\dlc\` and the tooltip CSV into `src\mod\`. Edit this to tune values. |
| `check-sources.ps1` | Build-time checks; the build stops if any fail. Tooltip rows and display labels exist for every stat used, every vanilla trophy resolves and is covered by the design, values have the right type and range, the tooltip table is vanilla plus our rows, and the shipped script is vanilla plus the one marked patch block. |
| `make-reddlc.ps1` | Builds the DLC definition file from a vanilla template via WolvenKit's CR2W library. |
| `pack-mod.ps1` | Packs a folder into a legacy-format bundle + metadata.store (the format proven to load on Remastered). |
| `make-w3strings.ps1` | Writes the localisation tables (stat labels, DLC name). |
| `build.ps1` | Runs the above and assembles `build\`; `-Install` copies into the game. |
| `src\scripts\local\` | The one annotation-style script (`modSpoilsOfTheHunt_attack.ws`). No vanilla file copies. |
| `dist\README.txt` | The readme shipped inside the release archive (`build.ps1 -Package`). |
| `vanilla\` | Untouched game files for reference (trophy XML, tooltip CSV, DLC definitions). Not committed: they are CD PROJEKT RED's. Run `extract-vanilla.ps1` once after cloning to pull them from your game install. |
| `extract-vanilla.ps1` | Rebuilds `vanilla\` from the game's bundles (verified byte-identical). |
| `tools\` | WolvenKit, w3edit, reference sources. Not committed. |

## How it works on Remastered

Remastered changed XML modding. Replacing a vanilla gameplay XML wholesale crashes the game at
startup. Instead a mod ships a DLC whose `.reddlc` carries a `CR4DefinitionsDLCMounter` pointing at
its own XML, and entries in that XML override vanilla ones by name with `on_conflict="replace"`
(the REDkit 5.0 changelog spells it `onConflict`; the engine parses `on_conflict`).

- Trophy abilities are redefined that way; the game copies a trophy's abilities onto Geralt when it
  is hung on Roach (`horseManager.ws`), so resistances, sign intensity and crit chance just work.
- `vsX_attack_power` bonuses are only read from the sword (oils) in vanilla. A scope-annotation
  script (`@wrapMethod(W3Action_Attack) GetPowerStatValue`) adds the bonus from abilities tagged
  `SpoilsOfTheHunt`. No vanilla script file is shipped, so the mod never conflicts with other script
  mods and needs no Script Merger; Vortex records it as "annotation style". The tag filter matters:
  applied oils also add their ability to the player, and an untagged lookup would count them twice.
- The trophy bonus *scales* the attack power multiplier (`x 1.10`) rather than adding 0.10 to it
  the way oils do. Measured in game (level 45 Geralt): the multiplier the damage formula uses is
  about 1.2 to 1.3 depending on attack style, and it reads 1.32 with the griffin trophy hung versus
  1.20 without, i.e. exactly +10%. The damage formula is `(weaponDmg + base) * mult + add` with a
  flat `add` of ~72, so the realised damage gain is slightly under 10%. Scaling keeps the tooltip
  honest regardless of how large the multiplier gets from skills and gear.
- The item tooltip only shows attributes listed in `gameplay\globals\tooltip_settings.csv`, so a
  copy with two extra rows is shipped through the Mods layer (plain files may still be replaced
  wholesale). Their display names come from the mod's `.w3strings`.
- The `.reddlc` is CR2W version 164, identical in layout to 162; `make-reddlc.ps1` patches the
  version so WolvenKit can edit it, then restores it and recomputes the header CRC.

## Debugging notes

- `DBGConsoleOn=true` in `general.ini` does not open the console on Remastered. For in-game
  diagnostics, add a temporary `thePlayer.DisplayHudMessage(...)` to the patched script.
- `theGame.GetDLCManager().IsDLCEnabled('dlc_spoilsofthehunt')` and
  `theGame.GetDefinitionsManager().IsAbilityDefined(...)` tell you whether the DLC mounted and the
  XML loaded. The game also writes `DlcEnabled_dlc_spoilsofthehunt=1` to `Documents\The Witcher 3\dx12user.settings`.
- Crash dumps land in `%LOCALAPPDATA%\CrashDumps`; there is no engine text log.

## Testing

- `check-sources.ps1` runs on every build (see Layout).
- `src\scripts-test\` and `src\config-test\` hold the in-game test harness: it spawns a creature
  of the matching class when a trophy is hung on Roach, records non-critical hits with and
  without a trophy bonus, and mirrors the totals into `dx12user.settings` so they can be read
  from outside the game. Installed only with `build.ps1 -Install -TestHarness`; `-Package`
  refuses to include it, and the checker fails if test code appears in `src\scripts\`.
- `dev\monitor-launch.ps1` waits for the game to start and reports a crash or a clean startup;
  `dev\watch-results.ps1` tails the harness totals. The in-game console does not open on
  Remastered, so these replace it.
