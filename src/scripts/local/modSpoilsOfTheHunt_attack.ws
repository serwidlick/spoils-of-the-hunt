// Spoils of the Hunt (modSpoilsOfTheHunt)
//
// Vanilla only reads "vs. monster class" attack power from the sword (oils). This wrapper also
// counts the bonus carried by the saddle trophy hung on Roach.
//
// Written as a scope annotation rather than a copy of attackAction.ws, so it never collides with
// another mod's copy of that file and needs no Script Merger. Only abilities tagged SpoilsOfTheHunt are
// read: an applied oil also adds its own ability (tagged OilBonus) to the player, and the oil is
// already counted by the vanilla code via the sword.
//
// The bonus scales the attack power multiplier instead of adding to it. Geralt's base attack power
// multiplier is about 10, so a plain +0.1 (what oils do) is worth only ~1% damage; scaling by
// (1 + 0.1) makes a "+10%" trophy really deal 10% more damage, which is what the tooltip says.

@wrapMethod(W3Action_Attack)
function GetPowerStatValue() : SAbilityAttributeValue
{
	var result : SAbilityAttributeValue;
	var bonus : SAbilityAttributeValue;
	var actorVictim : CActor;
	var playerAttacker : CPlayer;
	var monsterCategory : EMonsterCategory;
	var bonusName, soundName : name;
	var tmpBool : bool;
	var trophyTags : array<name>;

	result = wrappedMethod();

	actorVictim = (CActor)victim;
	playerAttacker = (CPlayer)attacker;
	if(playerAttacker && actorVictim)
	{
		theGame.GetMonsterParamsForActor(actorVictim, monsterCategory, soundName, tmpBool, tmpBool, tmpBool);
		bonusName = MonsterCategoryToAttackPowerBonus(monsterCategory);
		if(monsterCategory != MC_NotSet && IsNameValid(bonusName))
		{
			trophyTags.PushBack('SpoilsOfTheHunt');
			bonus = playerAttacker.GetAttributeValue(bonusName, trophyTags);
			if(bonus.valueMultiplicative > 0)
			{
				result.valueMultiplicative *= (1 + bonus.valueMultiplicative);
			}
		}
	}

	return result;
}
