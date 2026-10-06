// Spoils of the Hunt: a "Trophies" group in the alchemy panel.
// The panel groups recipes by their result type, a fixed enum. Fusion recipes use the type "trophy", which the
// loader maps to EACIT_Undefined, and these two tiny vanilla mapping functions get a fallback for it. Both are
// copied verbatim from alchemyTypes.ws with only the default branch changed.
@replaceMethod
function AlchemyCookedItemTypeEnumToName( type : EAlchemyCookedItemType) : name
{
	switch (type)
	{
		case EACIT_Potion			: return 'potion';
		case EACIT_Bomb				: return 'petard';
		case EACIT_Oil				: return 'oil';
		case EACIT_Substance		: return 'Substance';
		case EACIT_Bolt				: return 'bolt';
		case EACIT_MutagenPotion 	: return 'mutagen_potion';
		case EACIT_Alcohol 			: return 'alcohol';
		case EACIT_Quest			: return 'quest';
		case EACIT_Dye				: return 'dye';
		default	     				: return 'trophy';
	}
}

@replaceMethod
function AlchemyCookedItemTypeToLocKey( type : EAlchemyCookedItemType ) : string
{
	switch (type)
	{
		case EACIT_Potion			: return "panel_alchemy_tab_potions";
		case EACIT_Bomb				: return "panel_alchemy_tab_bombs";
		case EACIT_Oil				: return "panel_alchemy_tab_oils";
		case EACIT_Substance		: return "item_category_Substance";
		case EACIT_Bolt				: return "item_category_bolt";
		case EACIT_MutagenPotion 	: return "panel_inventory_filter_type_decoctions";
		case EACIT_Alcohol 			: return "panel_inventory_filter_type_alcohols";
		case EACIT_Quest 			: return "panel_button_worldmap_showquests";
		case EACIT_Dye				: return "item_category_dye";
		default	     				: return "panel_alchemy_tab_trophies";
	}
}
