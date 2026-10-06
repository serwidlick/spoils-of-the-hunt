# Flavour text per trophy, shown under the stat line in the item tooltip.
# Only trophies that share vanilla's generic description ("item_desc_trophy") are listed; the Blood and Wine
# trophies that already have their own vanilla description keep CDPR's text.
# Read by generate-sources.ps1 (item redefinitions), make-w3strings.ps1 (strings) and check-sources.ps1.
# Order matters: string ids are assigned by position, so append new entries at the end.
@{
    Descriptions = @(
        # ---- base game ----
        @('q002_griffin_trophy',         "Head of the royal griffin that terrorised White Orchard. Every gap in the plumage is familiar now; the next griffin's hide will offer less shelter."),
        @('mh101_cockatrice_trophy',     "A shrieker's head, beak still half open. Cockatrices share more with wyverns than with any bird, and a hunter who has gutted one reads the whole draconid family better."),
        @('mh102_arachas_trophy',        "Chitin plates from an arachas, still beaded with venom that refuses to dry. Carry it long enough and the body learns to shrug off lesser poisons."),
        @('mh103_nightwraith_trophy',    "What remains of Jenny o' the Woods, bound in a rag that still smells of grave soil. Spectral residue clings to it and lends weight to Yrden's traps."),
        @('mh104_ekimma_trophy',         "An ekimmara's head, fangs worn from gnawing bone. Its anatomy maps onto every lesser vampire, and teaches where the blood runs closest to the skin."),
        @('mh105_wyvern_trophy',         "A wyvern's head, tail barb threaded through the jaw. Having found where the scales thin on this one, a hunter finds the same gaps on its cousins."),
        @('mh106_gravehag_trophy',       "A grave hag's head, grinning still. Necrophages are built alike beneath the rot, and this one showed where the vital organs hide."),
        @('mh107_czart_trophy',          "A chort's horned skull. The frontal bone that let it charge through a timber wall makes a hide-wrapped guard against clubs and hooves."),
        @('mh108_fogling_trophy',        "A fogler's head, eyes still faintly luminous. It drifted among drowners for years, and its scent now guides the blade toward necrophage weak points."),
        @('mh201_cave_troll_trophy',     "A cave troll's head, nearly as hard as the rock it slept on. It teaches both where ogroids break and how a troll's skull takes a blow."),
        @('mh202_nekker_warrior_trophy', "A nekker warrior's head, brow scarred from a life of pit fights. Small, but the pattern of its weak points holds for every ogroid."),
        @('mh203_water_hag_trophy',      "A water hag's head, mud still weeping from the skin. The venom in its spit is weak but constant, and a body that carries it grows used to poison."),
        @('mh204_leshy_trophy',          "A leshen's antlered skull, roots threaded through the bone. The forest spirit's living wood shows where to cut every relict that borrows its shape."),
        @('mh206_fiend_trophy',          "A fiend's three-eyed head, the hypnotic eye sewn shut. Few relicts are built so solidly or hide their vitals better. Finding them once helps find them again."),
        @('mh207_wraith_trophy',         "A shard of the Phantom of Eldberg's lantern, iron fused with ash. The light it once bore now helps a silver blade find purchase on anything spectral."),
        @('mh208_forktail_trophy',       "A forktail's head, barbs intact. Its venom, dried and ground into the hide, keeps lesser poisons at bay by sheer familiarity."),
        @('mh210_lamia_trophy',          "An ekhidna's head, gills crusted with salt. Sirens and their kin share its ribcage, and a blade that found this one's heart finds the next more easily."),
        @('mq1051_wyvern_trophy',        "A Skellige wyvern's head, teeth notched on the bones of its own catch. Draconids are kin beneath the scale, and this one showed where they part."),
        @('mh301_gryphon_trophy',        "An archgriffin's head, its acid still etching the strap it hangs by. The largest of its line, and what it taught about griffins holds for every hybrid that flies."),
        @('mh302_leshy_trophy',          "A leshen's skull from the woods of Ard Skellig, wrapped in the vines that kept it standing. Relicts of the old forest all follow the same grain."),
        @('mh303_succubus_trophy',       "A succubus's horn, warm to the touch long after the hunt. Whatever charm lived in it lingers, and Axii carries farther for it."),
        @('mh304_katakan_trophy',        "A katakan's head, ears pinned flat. The vampire's reflexes taught the eye to anticipate, and its anatomy where to put the point."),
        @('mh305_doppler_trophy',        "A doppler's face, settled at last into one shape. It was a thief in life, and its luck with other people's purses seems to have stayed in the skin."),
        @('mh306_dao_trophy',            "A shard from an earth elemental's core, warm long after the rest fell to gravel. Bound to the saddle, it steadies the body against crushing blows."),
        @('mh307_minion_trophy',         "The head of a Hound of the Wild Hunt, rime along the jaw that never melts. A body that rides beside it learns to bear the cold the riders bring."),
        @('mh308_noonwraith_trophy',     "A noonwraith's bridal veil, bleached to nothing by the sun that bound her. Spectres recoil from it, and silver bites them deeper."),
        @('sq108_griffin_trophy',        "A griffin's head, taken from a nest built over a battlefield. The hybrid's weak points are the same as every griffin's; the lesson came cheaper this time."),
        @('mq0003_noonwraith_trophy',    "The noonwraith of White Orchard, or what the sun left of her. A relic of a first contract, and a reminder of where spectres are weakest."),
        # ---- Hearts of Stone ----
        @('q602_pig_contest_trophy',     "First prize in a pig race. It involved no monster, no sword and no skill a witcher respects, which is exactly why it fetches such good coin as a story."),
        @('q603_sharley_trophy',         "A plate from a shaelmaar's hide, taken in the Oxenfurt arena. Nothing in the known world rolls harder, and the shell softens whatever lands on its bearer."),
        # ---- Blood and Wine (the rest already have their own vanilla descriptions) ----
        @('q704_garkain_trophy',         "A garkain's head, jaw unhinged even in death. Higher vampires are not so easily killed, but their lesser kin share this one's weaknesses."),
        @('mq7009_griffin_trophy',       "A Toussaint griffin's head, feathers still scented by the vineyards it hunted over. A griffin's weak points are the same from White Orchard to Beauclair.")
    )

    # Vanilla gives several trophies the same display name (four "Griffin trophy", two "Wyvern", two "Leshen", two
    # "Noonwraith"), which makes fusion recipes indistinguishable. These override the name of a redefined item.
    Names = @(
        @('q002_griffin_trophy',      'Royal griffin trophy'),
        @('mh301_gryphon_trophy',     'Archgriffin trophy'),
        @('mq7009_griffin_trophy',    'Toussaint griffin trophy'),
        @('mq1051_wyvern_trophy',     'Skellige wyvern trophy'),
        @('mh302_leshy_trophy',       'Skellige leshen trophy'),
        @('mq0003_noonwraith_trophy', 'White Orchard noonwraith trophy')
    )
}
