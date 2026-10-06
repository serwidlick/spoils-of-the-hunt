# Trophy fusion design table (Phase 4). Read by generate-sources.ps1, make-w3strings.ps1 and check-sources.ps1.
# Rules are in docs\fusion-design.md: two trophies of the same class + one binder mutagen -> one fused trophy.
#   Class   = the game's EMonsterCategory token (Troll is the ogroid class; Magicals is elementa).
#   Mutagen = the monster's own mutagen item in the game ('' when the game has none); a type-matching binder.
#   Colour  = red/green/blue; a normal-grade generic mutagen of this colour is the colour-matching binder.
# Order within a class matters: the first trophy of a pair lends its saddle mesh and icon; keep rarer heads later.
@{
    Trophies = @(
        # ---- Hybrids ----
        @{ Item = 'q002_griffin_trophy';          Class = 'Hybrid';     Mutagen = 'Gryphon mutagen';          Colour = 'green' }
        @{ Item = 'sq108_griffin_trophy';         Class = 'Hybrid';     Mutagen = 'Gryphon mutagen';          Colour = 'green' }
        @{ Item = 'mq7009_griffin_trophy';        Class = 'Hybrid';     Mutagen = 'Gryphon mutagen';          Colour = 'green' }
        @{ Item = 'mh301_gryphon_trophy';         Class = 'Hybrid';     Mutagen = 'Volcanic Gryphon mutagen'; Colour = 'red' }
        @{ Item = 'mh210_lamia_trophy';           Class = 'Hybrid';     Mutagen = 'Lamia mutagen';            Colour = 'blue' }
        @{ Item = 'mh303_succubus_trophy';        Class = 'Hybrid';     Mutagen = 'Succubus mutagen';         Colour = 'red' }
        # ---- Draconids ----
        @{ Item = 'mh101_cockatrice_trophy';      Class = 'Draconide';  Mutagen = 'Cockatrice mutagen';       Colour = 'blue' }
        @{ Item = 'mh105_wyvern_trophy';          Class = 'Draconide';  Mutagen = 'Wyvern mutagen';           Colour = 'red' }
        @{ Item = 'mq1051_wyvern_trophy';         Class = 'Draconide';  Mutagen = 'Wyvern mutagen';           Colour = 'red' }
        @{ Item = 'mh208_forktail_trophy';        Class = 'Draconide';  Mutagen = 'Forktail mutagen';         Colour = 'blue' }
        @{ Item = 'mq7018_basilisk_trophy';       Class = 'Draconide';  Mutagen = 'Basilisk mutagen';         Colour = 'blue' }
        @{ Item = 'mq7010_dracolizard_trophy';    Class = 'Draconide';  Mutagen = '';                         Colour = 'red' }
        # ---- Relicts ----
        @{ Item = 'mh204_leshy_trophy';           Class = 'Relic';      Mutagen = 'Leshy mutagen';            Colour = 'blue' }
        @{ Item = 'mh302_leshy_trophy';           Class = 'Relic';      Mutagen = 'Ancient Leshy mutagen';    Colour = 'blue' }
        @{ Item = 'mh206_fiend_trophy';           Class = 'Relic';      Mutagen = 'Fiend mutagen';            Colour = 'green' }
        @{ Item = 'mh107_czart_trophy';           Class = 'Relic';      Mutagen = 'Czart mutagen';            Colour = 'blue' }
        @{ Item = 'mq7002_spriggan_trophy';       Class = 'Relic';      Mutagen = '';                         Colour = 'blue' }
        @{ Item = 'mh305_doppler_trophy';         Class = 'Relic';      Mutagen = 'Doppler mutagen';          Colour = 'red' }
        # ---- Specters ----
        @{ Item = 'mh207_wraith_trophy';          Class = 'Specter';    Mutagen = 'Wraith mutagen';           Colour = 'green' }
        @{ Item = 'mh103_nightwraith_trophy';     Class = 'Specter';    Mutagen = 'Nightwraith mutagen';      Colour = 'green' }
        @{ Item = 'mh308_noonwraith_trophy';      Class = 'Specter';    Mutagen = 'Noonwraith mutagen';       Colour = 'green' }
        @{ Item = 'mq0003_noonwraith_trophy';     Class = 'Specter';    Mutagen = 'Noonwraith mutagen';       Colour = 'green' }
        @{ Item = 'mq7017_zmora_trophy';          Class = 'Specter';    Mutagen = '';                         Colour = 'green' }
        # ---- Vampires ----
        @{ Item = 'mh104_ekimma_trophy';          Class = 'Vampire';    Mutagen = 'Ekimma mutagen';           Colour = 'green' }
        @{ Item = 'mh304_katakan_trophy';         Class = 'Vampire';    Mutagen = 'Katakan mutagen';          Colour = 'red' }
        @{ Item = 'q704_garkain_trophy';          Class = 'Vampire';    Mutagen = '';                         Colour = 'red' }
        @{ Item = 'camm_trophy';                  Class = 'Vampire';    Mutagen = '';                         Colour = 'red' }
        # ---- Necrophages ----
        @{ Item = 'mh106_gravehag_trophy';        Class = 'Necrophage'; Mutagen = 'Grave Hag mutagen';        Colour = 'green' }
        @{ Item = 'mh108_fogling_trophy';         Class = 'Necrophage'; Mutagen = 'Fogling 1 mutagen';        Colour = 'blue' }
        @{ Item = 'mh203_water_hag_trophy';       Class = 'Necrophage'; Mutagen = 'Water Hag mutagen';        Colour = 'red' }
        # ---- Ogroids (the game calls the class Troll) ----
        @{ Item = 'mh201_cave_troll_trophy';      Class = 'Troll';      Mutagen = 'Troll mutagen';            Colour = 'green' }
        @{ Item = 'mh202_nekker_warrior_trophy';  Class = 'Troll';      Mutagen = 'Nekker Warrior mutagen';   Colour = 'red' }
        @{ Item = 'q701_cyclops_trophy';          Class = 'Troll';      Mutagen = '';                         Colour = 'green' }
        # ---- Insectoids (shaelmaar class to confirm in game) ----
        @{ Item = 'mh102_arachas_trophy';         Class = 'Insectoid';  Mutagen = 'Arachas mutagen';          Colour = 'green' }
        @{ Item = 'q603_sharley_trophy';          Class = 'Insectoid';  Mutagen = '';                         Colour = 'green' }
        @{ Item = 'mh701_sharley_matriarch_trophy'; Class = 'Insectoid'; Mutagen = '';                        Colour = 'green' }
        # ---- Elementa (the game calls the class Magicals; hound class to confirm in game) ----
        @{ Item = 'mh306_dao_trophy';             Class = 'Magicals';   Mutagen = 'Dao mutagen';              Colour = 'blue' }
        @{ Item = 'mh307_minion_trophy';          Class = 'Magicals';   Mutagen = '';                         Colour = 'blue' }
        # ---- Cursed Ones: only one trophy, so no pair yet ----
        @{ Item = 'q702_wicht_trophy';            Class = 'Cursed';     Mutagen = '';                         Colour = 'green' }
        # q602_pig_contest_trophy is not a monster and is left out on purpose.
    )

    # Generic mutagens accepted as colour-matching binders (normal grade only; greater is reserved for a later tier).
    GenericMutagens = @{ red = 'Mutagen red'; green = 'Mutagen green'; blue = 'Mutagen blue' }

    # Fused items are named by class, so the tooltip's bonus lines tell the pairs apart.
    Classes = @{
        Hybrid     = @{ Name = "Hybrid hunter's trophy";     Desc = "Two hybrid heads bound into one standard with mutagen. Everything that hunts on feathered wings or sings from the rocks has an enemy who knows it twice over." }
        Draconide  = @{ Name = "Draconid hunter's trophy";   Desc = "Scaled heads fused jaw to jaw, the venom and the fire of two draconids set in one binding. Their kin will learn to fear the saddle it hangs from." }
        Relic      = @{ Name = "Relict hunter's trophy";     Desc = "Old things of the forest and the hills, bound together with mutagen. Relicts are rarely met twice; this hunter met two." }
        Specter    = @{ Name = "Specter hunter's trophy";    Desc = "What two spectres left behind, bound with mutagen so neither can drift away. Silver finds the unquiet dead more easily in its company." }
        Vampire    = @{ Name = "Vampire hunter's trophy";    Desc = "Two vampires' heads, fangs locked, bound with mutagen. Their lesser kin smell what it is and hesitate, and hesitation is where the blade goes." }
        Necrophage = @{ Name = "Necrophage hunter's trophy"; Desc = "Two carrion-eaters bound together, the rot sealed under mutagen. A grim thing to carry, and a precise map of where their kind come apart." }
        Troll      = @{ Name = "Ogroid hunter's trophy";     Desc = "Two ogroid heads bound with mutagen, heavy enough to tilt the saddle. Nothing teaches where a troll breaks like having broken two." }
        Insectoid  = @{ Name = "Insectoid hunter's trophy";  Desc = "Chitin and venom sacs from two insectoids, bound with mutagen into one plated mass. Poison runs off its bearer like rain off a shell." }
        Magicals   = @{ Name = "Elementa hunter's trophy";   Desc = "Fragments of two elemental things, one cold, one stone, bound with mutagen. The body beside it learns to stand against what the elements send." }
        Cursed     = @{ Name = "Cursed hunter's trophy";     Desc = "Two cursed creatures bound with mutagen. Whatever curse they carried has nowhere left to go." }
    }
}
