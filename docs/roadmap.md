# Spoils of the Hunt — roadmap

Status key: **done** · **cheap** (script/XML only, hours) · **medium** (script + binary edits, days) · **REDkit** (needs new assets: meshes, effects, scenes, NPC templates).

Everything below builds on what v1 proved: we can override any trophy ability, add new items and abilities through our DLC XML, patch any vanilla script, ship localisation tables, and replace plain files like CSVs.

---

## Phase 1 — Lore-friendly bonuses · done

- 37 trophies rewritten, tiered 5 / 10 / 15 %, tooltips and labels working on Remastered 5.x.
- Reproducible build pipeline in the repo.

## Phase 2 — Polish and release the base mod · cheap

1. **Flavour text per trophy.** Replace the shared "Strap trophies to your saddle" description with one line per beast ("Forktail venom, dried and ground into the hide. The smell alone keeps lesser poisons at bay."). Needs each item redefined with `on_conflict="replace"` and a new `localisation_key_description`, plus strings in our `.w3strings`. We already have both mechanisms.
2. **Balance pass after play.** Numbers are deliberately modest; revisit once a few contracts have been fought with the bonuses live.
3. **Nexus page: done (mod 13705). mod.io: `build.ps1 -ModIo` makes the package; upload pending.** Console eligibility needs `-ScriptBlob` (REDkit wcc_lite, EULA accepted once) and CDPR review; PC works with the loose script.
4. **Compatibility notes.** Script Merger for the single script change; our XML never touches vanilla files, so it stacks with most other mods.

## Phase 3 — Mod settings menu · cheap

The game has a built-in mod options system: an XML under `bin\config\r4game\user_config_matrix\pc\` adds a page to Options → Mods, and scripts read it with `theGame.GetInGameConfigWrapper().GetVarValue(group, var)`. The Simple Loadout System mod uses exactly this on Remastered.

Proposed options:

| Option | Effect | How |
|---|---|---|
| Bonus strength: Subtle / Default / Strong | 0.5× / 1× / 2× the vs-class and resistance values | Three ability variants per trophy in the XML (`_subtle`, default, `_strong`); a small patch in `horseManager.ws` picks the variant when the trophy is hung |
| "Vs. class" damage counts | On/off switch for the attack-script change | Read the setting inside our existing patch |
| Keep gold-bonus trophies thematic | Replaces the doppler and pig-race gold bonuses with class bonuses | Ability variant swap, as above |
| Max combined bonuses per trophy | 2 / 3 / 4 (Phase 4) | Script check at combine time |
| Combined-trophy visuals | On/off (Phase 5) | Script check when equipping |
| Merchant price bonus | 1.25× / 1.5× / 2× (Phase 6) | Script hook on sell price |

Limitation worth knowing: XML attribute values are static, so a "slider" cannot scale them directly. Variants plus a swap on equip is the clean workaround and also keeps the tooltip honest.

## Phase 4 — Combining trophies (the "enchanted book" idea) · medium

**Goal.** Reward collectors: fuse trophies so one saddle hook carries several bonuses, with real cost and a cap so it stays a reward rather than a free stat pile.

**Mechanics proposal.**
- A fused trophy is a new item, "Hunter's Trophy", defined in our XML with no bonuses of its own. When the player fuses trophies into it, the script copies the source trophies' abilities onto that one item with `AddItemBaseAbility` (the engine function armour enchanting uses). Abilities added this way live on the item instance and save with it. One item type, any combination, no explosion of XML entries. This is the enchanted-book model.
- Rules: max N bonuses per fused trophy (default 3, configurable); the same class bonus cannot stack twice; fusing consumes the source trophies; a fee in crowns or crafting components so it is a decision, not a click.
- Tier-up idea: fusing two trophies of the *same* class (two griffins) upgrades that class bonus one tier (10 % → 15 %) instead of adding a second line. Rewards hunting the same beast more than once.

**Interface options**, cheapest first:
1. *Crafting recipes.* Static recipes at any armourer: two specific trophies → a specific fused item. Simple, uses the vanilla crafting UI, but every combination is a separate recipe, so it only suits a small set of curated fusions (e.g. "Hunter's Trophy: Draconids" from any two draconid trophies).
2. *Fuse on the saddle.* With one trophy hung on Roach, using another trophy from the inventory fuses it in. Needs a small script change to make trophies "usable" and a confirmation popup. No new UI assets.
3. *The trophy merchant does it* (Phase 6) through a dialogue choice. Best fit for lore, biggest dependency.

Recommend starting with option 2 as the core and adding option 3 when the merchant exists.

**Tooltip.** Fused items show every ability line automatically, since the tooltip reads item attributes. The item name can carry a count ("Hunter's Trophy (3)") via the item's localisation key plus a script-set display name.

## Phase 5 — Visual identity for fused trophies · medium, full version REDkit

- **Cheap version.** The game already has horse-wide effects: the Devil Saddle turns Roach into a flaming horse purely through script (`horseManager.ws`, `EHM_Devil` mode and the saddle's appearance names). A fused trophy can trigger an existing effect on Roach the same way, such as a faint glow or the mist used by wraiths, chosen per dominant class. Also possible: swap the fused trophy's `equip_template` to a different vanilla trophy mesh, so it looks distinct on the saddle.
- **Full version.** A dedicated particle effect or a new trophy mesh (a bundle of skulls, say) needs REDkit to author the entity and particle assets. Worth it only after the mechanics prove fun.

## Phase 6 — Trophy merchants · REDkit for the proper version, script-only version possible

**Design.** A travelling taxidermist or "trophy dealer" who pays a premium for trophies (rate configurable), sells a rotating stock of trophies the player missed, and later offers fusion as a paid service. One per region keeps travel meaningful:

| Region | Spot | Flavour |
|---|---|---|
| Velen + Novigrad | Novigrad, Hierarch Square market or the Putrid Grove edge | Ex-hunter turned dealer |
| Skellige | Kaer Trolde harbour | Skelliger who trades in sea-monster parts |
| Toussaint | Beauclair market square | Collector supplying noble trophy rooms |

**What it takes.**
- *Shop contents and prices:* XML and script, cheap. Shop inventories are XML loot definitions; a higher trophy price is a script hook on the sell-price calculation when the merchant is ours.
- *The NPC itself:* an entity template with an inventory initialiser, voice tag and interaction. Vanilla merchant templates can be reused; placing one at a world position and spawning it from script is cheap. Giving it a unique look or editing its template cleanly is REDkit work (WolvenKit's library can edit entity binaries, but it is fiddly).
- *Dialogue:* "Let's trade" and the fusion menu need a scene file. Scenes are REDkit territory. Reusing generic merchant voice lines, as you suggested, is exactly how CDPR's unnamed merchants work, so this is feasible, just tool-heavy.
- *Script-only fallback:* spawn a vanilla merchant and open the shop screen directly on interaction, skipping dialogue. Less polished, no REDkit.

Suggested order: fallback version first to validate the economy, REDkit version later.

## Further ideas (mine, for discussion)

- **Blooded trophies.** A trophy grows with use: kills of its own class while it is hung on Roach raise its bonus one tier at thresholds (10 / 25 kills). Script-only, saves with the item, strong "collector" fantasy.
- **Master Hunter perk.** Owning 10 / 20 / 30 distinct trophies grants a small passive (stamina regen, +1 adrenaline point on contract kills). Counts inventory plus stash; script-only.
- **Trophy codex.** A journal or glossary page listing every trophy, where it came from and whether it is collected. Needs journal entries, which are REDkit.
- **Lore-accurate drops.** Beasts that have no trophy today (wraiths outside contracts, archespores, slyzards) could drop a lesser "trophy" from the monster category, so the system is not limited to the 37 contract heads. New items are cheap; new loot entries are XML.
- **Corvo Bianco trophy room.** Mount fused trophies on the estate walls. Pure REDkit, the showpiece if the mod gets that far.
- **Difficulty-aware numbers.** Death March scales bonuses down a notch so they stay flavour rather than crutch; configurable.

## Suggested sequence

1. Phase 2 (release what works).
2. Phase 3 (settings) and the Blooded Trophies idea together, since both need the equip hook.
3. Phase 4 fusion with the saddle interface.
4. Phase 5 cheap visuals.
5. Phase 6 merchants, fallback first, and decide then whether to install REDkit.
