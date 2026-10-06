# Spoils of the Hunt — lore-friendly trophy rework (design draft v1)

## The problem with vanilla

Every trophy in the game grants one of five generic bonuses, unrelated to the beast it came from:

| Vanilla bonus | Trophies that give it |
|---|---|
| +5% XP from monsters | cave troll, leshen (x2), forktail, wyvern (x2), fiend, chort, ekimmara, katakan, cyclops, wight, garkain |
| +5% XP from humans | grave hag, wraith, water hag, nightwraith, noonwraith (x2) |
| +5% chance of extra herbs | nekker warrior, arachas, spriggan, night wraith (BaW) |
| +5% gold from loot | fogler, siren, succubus, doppler, shaelmaar, pig contest (15%) |
| +10% dismember chance | griffin (x3), cockatrice, earth elemental, dracolizard |

A griffin head making you find more coins is the kind of thing this rework removes.

## Design principles

1. **The bonus comes from the beast.** Either the witcher learned how to fight that class of monster (offence vs. the monster's bestiary class), or the trophy carries a trait of the creature (its venom, its hide, its cold).
2. **Contract tier sets strength.** Minor beasts (nekker, water hag, fogler) give 5%. Named contract monsters give 10%. Rare or legendary beasts (archgriffin, earth elemental, white basilisk) give 15% or two smaller bonuses.
3. **No XP or gold.** Those were never something a severed head could plausibly provide. The one exception is kept as a deliberate joke: the Hearts of Stone pig-race trophy.
4. **Everything shows correctly in the tooltip.** Only stats the game's item tooltip already knows how to display are used, so no UI edits are required.
5. **The percentage means damage.** A "+10% vs. Hybrids" trophy multiplies attack power by 1.10 against that class. Vanilla oils instead add their figure to the multiplier, so an oil's "+50%" is really a smaller real-damage gain; trophies deliberately say what they do. Verified in game: attack power multiplier 1.32 with the griffin trophy versus 1.20 without.

## Proposed bonuses

Classes follow the in-game bestiary. "vs." bonuses are attack power against that class.

### Base game

| Trophy (quest id) | Beast class | New bonus | Why |
|---|---|---|---|
| Royal Griffin (q002, White Orchard) | Hybrid | +10% vs. Hybrids | First great hunt of the game; a hunter learns his prey |
| Griffin (sq108) | Hybrid | +10% vs. Hybrids | same |
| Archgriffin (mh301, Skellige) | Hybrid | +15% vs. Hybrids | Rarer, deadlier kin |
| Shrieker / Cockatrice (mh101) | Draconid | +10% vs. Draconids | |
| Arachas (mh102) | Insectoid | +15% poison resistance | Arachas venom glands |
| Jenny o' the Woods / Nightwraith (mh103) | Specter | +10% Yrden sign intensity | Yrden is the witcher's tool against wraiths |
| Ekimmara (mh104) | Vampire | +10% vs. Vampires | |
| Wyvern (mh105 and mq1051) | Draconid | +10% vs. Draconids | |
| Grave Hag (mh106) | Necrophage | +10% vs. Necrophages | |
| Chort (mh107) | Relict | +10% bludgeoning resistance | Chorts win by charging; its hide teaches you to brace |
| Fogler (mh108) | Necrophage | +5% vs. Necrophages | Minor beast |
| Cave Troll (mh201) | Ogroid | +5% vs. Ogroids, +5% bludgeoning resistance | |
| Nekker Warrior (mh202) | Ogroid | +5% vs. Ogroids | Minor beast |
| Water Hag (mh203) | Necrophage | +5% poison resistance | Hags spit poison mud |
| Leshen (mh204 and mh302) | Relict | +10% vs. Relicts | |
| Fiend (mh206) | Relict | +10% vs. Relicts | |
| Phantom of Eldberg / Wraith (mh207) | Specter | +10% vs. Specters | |
| Forktail (mh208) | Draconid | +15% poison resistance | Forktail venom |
| Ekhidna / Siren (mh210) | Hybrid | +5% vs. Hybrids | Minor beast |
| Succubus (mh303) | Relict | +10% Axii sign intensity | A creature of charm, if you chose to kill her |
| Katakan (mh304) | Vampire | +10% vs. Vampires, +5% critical hit chance | Katakans hunt from invisibility |
| Doppler (mh305) | Relict | +10% gold from loot | Kept: the doppler you kill is a thief and merchant, so this one is actually lore-friendly |
| Earth Elemental (mh306) | Elementa | +15% bludgeoning resistance | Stone fists |
| Hound of the Wild Hunt (mh307) | Cursed/Wild Hunt | +15% frost resistance | Creature of the Hunt's cold |
| Noonwraith (mh308 and mq0003) | Specter | +10% vs. Specters | |

### Hearts of Stone

| Trophy | New bonus | Why |
|---|---|---|
| Pig-race trophy (q602) | +15% gold from loot (unchanged) | Comedy quest reward; leave the joke alone |
| Shaelmaar (q603) | +10% bludgeoning resistance | Burrowing boulder of a beast |

### Blood and Wine

| Trophy | Beast class | New bonus |
|---|---|---|
| Cyclops (q701) | Ogroid | +10% vs. Ogroids, +5% bludgeoning resistance |
| Wight (q702) | Cursed | +10% vs. Cursed Ones |
| Garkain (q704) | Vampire | +10% vs. Vampires |
| Spriggan (mq7002) | Relict | +10% vs. Relicts |
| Griffin (mq7009) | Hybrid | +10% vs. Hybrids |
| Night wraith (mq7017) | Specter | +10% vs. Specters |
| Dracolizard (mq7010) | Draconid | +15% fire resistance |
| White Basilisk (mq7018) | Draconid | +10% vs. Draconids, +10% poison resistance |
| Shaelmaar Matriarch (mh701) | Relict | +15% bludgeoning resistance |
| Cammerlengo (camm) | Vampire | +15% vs. Vampires |

## How it is built

- **XML.** Every trophy's `xxx_trophy_stats` ability in the three `def_item_trophies.xml` files (base, Hearts of Stone, Blood and Wine) and their NG+ twins gets new attributes. The game already applies a trophy's abilities directly to Geralt when it is hung on Roach, so resistances, sign intensity and crit chance work with no further code.
- **One script line.** Attack power "vs. class" is only read from the sword (oils) today. A one-line addition to the damage calculation makes Geralt's own bonuses count too. The change is Script Merger friendly.
- **Packaging.** XML files must be packed into a mod bundle, which needs WolvenKit. Scripts go in the mod folder as loose files.
- **No new text needed for v1.** The tooltip already has names for every stat used. Custom flavour descriptions per trophy can come in v2 via a w3strings file.

## Open questions for you

1. Happy with the "vs. class" offence as the backbone, with venom/hide/cold resistances as flavour? Or would you rather see more defensive and utility effects and fewer damage bonuses?
2. Are the numbers (5 / 10 / 15%) about right? Oils give 10% to 50%, so these stay deliberately modest.
3. Keep the doppler gold bonus and the pig-race joke, or make every single one thematic?
4. OK to install WolvenKit for packing? It is the standard community tool and is required for the XML side.
