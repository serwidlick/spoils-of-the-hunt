# Spoils of the Hunt

*Lore-friendly saddle trophy bonuses for The Witcher 3: Wild Hunt – Remastered*

A griffin's head should not make you find more coins. In vanilla, every trophy you hang on Roach gives one of five generic bonuses: +5% XP from monsters, +5% XP from humans, +5% extra herbs, +5% gold, or +10% dismember chance. None of them has anything to do with the beast you killed.

Spoils of the Hunt replaces all of them. Each trophy now carries something that came from the hunt itself:

- **Hunter's knowledge:** attack power against the monster's own class. Hang a griffin head and you hit Hybrids (griffins, sirens, harpies, succubi) 10% harder.
- **A trait of the creature:** forktail and arachas venom give poison resistance, the Hound of the Wild Hunt gives frost resistance, the earth elemental and chort harden you against blunt blows, the nightwraith strengthens Yrden, the succubus strengthens Axii.
- **Tiered by the hunt:** minor beasts give 5%, named contract monsters 10%, rare ones such as the archgriffin or white basilisk 15% or two smaller bonuses.

Works on any save. Trophies you already own pick up their new bonus the moment you load. New Game Plus is supported. All 40 trophies across the base game, Hearts of Stone and Blood and Wine are covered.

## The bonuses

**Base game**

- Royal Griffin, Griffin (sq108): +10% attack vs. Hybrids
- Archgriffin: +15% attack vs. Hybrids
- Shrieker (Cockatrice): +10% attack vs. Draconids
- Arachas: +15% poison resistance
- Jenny o' the Woods (Nightwraith): +10% Yrden sign intensity
- Ekimmara: +10% attack vs. Vampires
- Wyvern (both): +10% attack vs. Draconids
- Grave Hag: +10% attack vs. Necrophages
- Chort: +10% bludgeoning resistance
- Fogler: +5% attack vs. Necrophages
- Cave Troll: +5% attack vs. Ogroids, +5% bludgeoning resistance
- Nekker Warrior: +5% attack vs. Ogroids
- Water Hag: +5% poison resistance
- Leshen (both): +10% attack vs. Relicts
- Fiend: +10% attack vs. Relicts
- Phantom of Eldberg (Wraith): +10% attack vs. Specters
- Forktail: +15% poison resistance
- Ekhidna (Siren): +5% attack vs. Hybrids
- Succubus: +10% Axii sign intensity
- Katakan: +10% attack vs. Vampires, +5% critical hit chance
- Doppler: +10% gold from loot (kept: the one you kill is a thief)
- Earth Elemental: +15% bludgeoning resistance
- Hound of the Wild Hunt: +15% frost resistance
- Noonwraith (both): +10% attack vs. Specters

**Hearts of Stone**

- Pig-race trophy: +15% gold (kept: it's a joke, and it should stay one)
- Shaelmaar: +10% bludgeoning resistance

**Blood and Wine**

- Cyclops: +10% attack vs. Ogroids, +5% bludgeoning resistance
- Wight: +10% attack vs. Cursed Ones
- Garkain: +10% attack vs. Vampires
- Spriggan: +10% attack vs. Relicts
- Griffin: +10% attack vs. Hybrids
- Night wraith: +10% attack vs. Specters
- Dracolizard: +15% fire resistance
- White Basilisk: +10% attack vs. Draconids, +10% poison resistance
- Shaelmaar Matriarch: +15% bludgeoning resistance
- Cammerlengo: +15% attack vs. Vampires

The "attack vs. class" percentages mean real damage: a +10% trophy multiplies your attack power against that class by 1.10. Trophies and oils stack.

## Installation

Subscribe here, then restart the game. The mod appears in the game's Mods menu; make sure it is enabled there. Nothing else to do.

**Uninstall:** unsubscribe. Trophies revert to vanilla. Nothing is stored in your saves.

## Compatibility

- Requires The Witcher 3: Wild Hunt – Remastered (5.x).
- No vanilla script file is replaced. The single script is a scope annotation (@wrapMethod), so it cannot conflict with other script mods.
- No vanilla XML file is replaced. Trophy abilities are overridden by name through the Remastered on_conflict mechanism. Only a mod that also redefines trophy abilities would conflict.
- One shared file: gameplay\globals\tooltip_settings.csv is replaced to add display rows for fire and frost resistance. If another mod replaces the same file, the only effect is whether those two labels show on two trophies.
- New Game Plus supported.

## Known limits

- Trophy descriptions still show the generic vanilla text; only the stat line changes. Per-trophy flavour text is planned.
- Only the trophy on Roach's saddle counts, as in vanilla. Trophies in your bags do nothing.

## Source

Build scripts, the full bonus table and the test harness are open: https://github.com/serwidlick/spoils-of-the-hunt
Also on Nexus Mods: https://www.nexusmods.com/witcher3/mods/13705
