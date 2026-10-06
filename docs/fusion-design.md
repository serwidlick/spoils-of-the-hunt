# Trophy fusion — design draft (Phase 4)

Status: draft for review, nothing built yet. Numbers are a starting point; balance is the standing worry.

## Rules

1. **Same class only.** Two trophies whose monsters share a bestiary class can be fused. The class is the game's own
   (`EMonsterCategory`), the same one the "vs. class" bonuses already use.
2. **One binder, consumed:** either trophy's own monster mutagen, or a generic mutagen (red, green or blue, normal grade)
   of either trophy's colour. Colours come from the game's mutagen table; trophies without a monster mutagen get a colour
   assigned below.
3. **Class line:** only when at least one source has one: `5% + the better of the two`, capped at 20%. Two trait-only
   trophies (forktail + dracolizard) keep both traits and gain no class line. 10% + 10% gives 15%; 10% + 15% gives 20%.
4. **Traits:** both trophies' traits carry over. If both have the same trait, the result gets the higher one plus 5%.
5. **Both trophies are consumed.** A fused trophy cannot be fused again (cap of one fusion in v1).
6. **Done through the alchemy panel**, under its own "Trophies" group (two tiny vanilla type-mapping functions are replaced for that), with recipes taught only for pairs Geralt currently owns.
   No craftsman, no new UI.
7. **The pig-race trophy is not a monster** and cannot be fused.

Worked examples: wyvern (10% vs Draconids) + forktail (15% poison resistance) → 15% vs Draconids, 15% poison.
Cave troll (5% vs Ogroids, 5% bludgeoning) + cyclops (10% vs Ogroids, 5% bludgeoning) → 15% vs Ogroids, 10% bludgeoning.
Griffin + archgriffin → 20% vs Hybrids. Ekhidna (5%) + succubus (Axii 10%) → 10% vs Hybrids, Axii 10%.

## The table

Class per the bestiary. "?" marks a class to confirm in game (the test harness prints the class of the creature it
spawns). Mutagen = the monster's own mutagen in the game and its colour; "assigned" means the game has no mutagen for
that monster and the colour is ours.

### Hybrids (6 trophies, 15 pairs)

| Trophy | Bonus today | Binder mutagen | Colour |
|---|---|---|---|
| Royal Griffin (White Orchard) | 10% vs Hybrids | Gryphon mutagen | green |
| Griffin (sq108) | 10% vs Hybrids | Gryphon mutagen | green |
| Griffin (Toussaint) | 10% vs Hybrids | Gryphon mutagen | green |
| Archgriffin | 15% vs Hybrids | Volcanic Gryphon mutagen | red |
| Ekhidna | 5% vs Hybrids | Lamia mutagen | blue |
| Succubus | 10% Axii intensity | Succubus mutagen | red |

### Draconids (6 trophies, 15 pairs)

| Trophy | Bonus today | Binder mutagen | Colour |
|---|---|---|---|
| Shrieker (cockatrice) | 10% vs Draconids | Cockatrice mutagen | blue |
| Wyvern (mh105) | 10% vs Draconids | Wyvern mutagen | red |
| Wyvern (Skellige) | 10% vs Draconids | Wyvern mutagen | red |
| Forktail | 15% poison resistance | Forktail mutagen | blue |
| White Basilisk | 10% vs Draconids, 10% poison resistance | Basilisk mutagen | blue |
| Dracolizard | 15% fire resistance | assigned | red |

### Relicts (6 trophies, 15 pairs)

| Trophy | Bonus today | Binder mutagen | Colour |
|---|---|---|---|
| Leshen (mh204) | 10% vs Relicts | Leshy mutagen | blue |
| Leshen (Skellige) | 10% vs Relicts | Ancient Leshy mutagen | blue |
| Fiend | 10% vs Relicts | Fiend mutagen | green |
| Chort | 10% bludgeoning resistance | Czart mutagen | blue |
| Spriggan | 10% vs Relicts | assigned | blue |
| Doppler | 10% gold | Doppler mutagen | red |

### Specters (5 trophies, 10 pairs)

| Trophy | Bonus today | Binder mutagen | Colour |
|---|---|---|---|
| Phantom of Eldberg | 10% vs Specters | Wraith mutagen | green |
| Jenny o' the Woods | 10% Yrden intensity | Nightwraith mutagen | green |
| Noonwraith (mh308) | 10% vs Specters | Noonwraith mutagen | green |
| Noonwraith (White Orchard) | 10% vs Specters | Noonwraith mutagen | green |
| Night wraith (Toussaint) | 10% vs Specters | assigned | green |

### Vampires (4 trophies, 6 pairs)

| Trophy | Bonus today | Binder mutagen | Colour |
|---|---|---|---|
| Ekimmara | 10% vs Vampires | Ekimma mutagen | green |
| Katakan | 10% vs Vampires, 5% crit chance | Katakan mutagen | red |
| Garkain | 10% vs Vampires | assigned | red |
| Cammerlengo | 15% vs Vampires | assigned | red |

### Necrophages (3 trophies, 3 pairs)

| Trophy | Bonus today | Binder mutagen | Colour |
|---|---|---|---|
| Grave Hag | 10% vs Necrophages | Grave Hag mutagen | green |
| Fogler | 5% vs Necrophages | Fogling mutagen | blue |
| Water Hag | 5% poison resistance | Water Hag mutagen | red |

### Ogroids (3 trophies, 3 pairs)

| Trophy | Bonus today | Binder mutagen | Colour |
|---|---|---|---|
| Cave Troll | 5% vs Ogroids, 5% bludgeoning | Troll mutagen | green |
| Nekker Warrior | 5% vs Ogroids | Nekker Warrior mutagen | red |
| Cyclops | 10% vs Ogroids, 5% bludgeoning | assigned | green |

### Insectoids (3 trophies, 3 pairs) — shaelmaar class to confirm (?)

| Trophy | Bonus today | Binder mutagen | Colour |
|---|---|---|---|
| Arachas | 15% poison resistance | Arachas mutagen | green |
| Shaelmaar (?) | 10% bludgeoning resistance | assigned | green |
| Shaelmaar Matriarch (?) | 15% bludgeoning resistance | assigned | green |

### Elementa (2 trophies, 1 pair) — hound class to confirm (?)

| Trophy | Bonus today | Binder mutagen | Colour |
|---|---|---|---|
| Earth Elemental | 15% bludgeoning resistance | Dao mutagen | blue |
| Hound of the Wild Hunt (?) | 15% frost resistance | assigned | blue |

### No partner

| Trophy | Class | Note |
|---|---|---|
| Wight | Cursed One | only Cursed trophy; fusable once a second one exists (werewolf trophy is cut from the game) |
| Pig-race trophy | none | not a monster |

## Numbers

- 71 pairs. Each pair has up to four binders (two own mutagens, two colours), so about 250 recipes and 71 fused
  item definitions, all generated from the design table.
- Strongest results under the rules: 20% vs Hybrids (griffin + archgriffin), 20% vs Vampires (katakan + Cammerlengo,
  plus 5% crit), 15% vs Draconids + 15% poison (wyvern + forktail), 15% vs Ogroids + 10% bludgeoning (troll + cyclops).
- For comparison, a superior oil adds +50% to the multiplier, worth roughly +25% real damage. A 20% fused trophy that
  stacks with it is a specialist's reward, not a replacement for oils.

## Open questions

1. Confirm the three "?" classes in game before generating recipes.
2. Should lesser and greater generic mutagens count as binders too, or only the normal grade? (Normal only keeps
   lesser ones for decoctions and greater ones precious.)
3. Result name: "Fused trophy: Griffin and Forktail" style, or a class name such as "Hybrid hunter's trophy"?
   The tooltip lists the bonuses either way.
4. Mesh on the saddle: the first-listed trophy's, unless you want the rarer one shown.
