Spoils of the Hunt
==================
Lore-friendly saddle trophy bonuses for The Witcher 3: Wild Hunt - Remastered (5.x).

Every trophy's bonus now comes from the beast it was taken from: attack power against that
beast's class, or a trait of the creature such as venom resistance or frost resistance.
No more "+5% gold" griffin heads. Works on any save; trophies you already own pick up the new
bonus the moment you load.

INSTALL
-------
Vortex: install the archive like any other mod and deploy.
Manual: copy the DLC and Mods folders into your game folder (the one containing bin, content,
DLC and Mods). Quit the game first.

The mod has two parts and needs both:
  DLC\dlcSpoilsOfTheHunt    the trophy definitions
  Mods\modSpoilsOfTheHunt   the tooltip table, text labels and one script

COMPATIBILITY
-------------
- No vanilla script file is replaced. The one script uses a scope annotation (@wrapMethod), so
  it does not conflict with other mods and does not need Script Merger.
- No vanilla XML file is replaced. Trophy abilities are overridden by name through the game's
  on_conflict="replace" mechanism, so other XML mods are unaffected unless they also redefine
  trophy abilities.
- The tooltip table (gameplay\globals\tooltip_settings.csv) is replaced to add two display rows.
  Another mod replacing that same file will win or lose depending on load order; the only effect
  is whether "Fire resistance" / "Frost resistance" labels show on two trophies.
- New Game Plus is supported.

UNINSTALL
---------
Remove both folders. Trophies revert to their vanilla bonuses; nothing is stored in saves.

SOURCE
------
Mod page: https://www.nexusmods.com/witcher3/mods/13705
Source:   https://github.com/serwidlick/spoils-of-the-hunt
