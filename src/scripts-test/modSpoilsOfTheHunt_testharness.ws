// Spoils of the Hunt — TEST HARNESS. Installed only with `build.ps1 -Install -TestHarness`, never packaged.
//
// The debug console does not open on Remastered, so this stands in for `spawn`/`additem`:
// every time something is hung on Roach, it reads the vs-class attack bonuses Geralt currently
// has from SpoilsOfTheHunt-tagged abilities, prints them on the HUD, and spawns one hostile creature
// of the first matching class about eight metres in front of the camera.
//
// Expected: griffin trophy -> "vsHybrid_attack_power=0.1 -> spawned harpy". With a Hybrid oil
// on the sword but no griffin trophy, the tagged value must stay 0 (oils are excluded).
//
// Note: a backslash right before a closing quote escapes it in WitcherScript, so paths are kept
// whole and never end in a backslash.

// ---------------------------------------------------------------------------------------------
// Damage recorder: every non-critical melee hit by the player is bucketed by whether a trophy
// "vs. class" bonus for the victim's class was active, and running averages + ratio are shown.
// Totals live in game facts (modlt_*), so they survive menus; they are test-only numbers.
// Do the oil check LAST: oil hits would otherwise pollute the "without trophy" bucket.

@wrapMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	wrappedMethod(act);
	modLT_RecordHit(act);
}

function modLT_RecordHit(act : W3DamageAction)
{
	var player : CPlayer;
	var victim : CActor;
	var dmg : float;
	var cat : EMonsterCategory;
	var soundName : name;
	var tmpBool : bool;
	var tags : array<name>;
	var v : SAbilityAttributeValue;
	var withBonus : bool;
	var nWith, sWith, nWithout, sWithout : int;
	var avgWith, avgWithout, ratio : float;
	var msg : string;

	player = (CPlayer)act.attacker;
	victim = (CActor)act.victim;
	if(!player || !victim || !act.IsActionMelee() || act.IsCriticalHit())
	{
		return;
	}
	dmg = act.processedDmg.vitalityDamage + act.processedDmg.essenceDamage;
	if(dmg <= 0)
	{
		return;
	}

	theGame.GetMonsterParamsForActor(victim, cat, soundName, tmpBool, tmpBool, tmpBool);
	tags.PushBack('SpoilsOfTheHunt');
	v = player.GetAttributeValue(MonsterCategoryToAttackPowerBonus(cat), tags);
	withBonus = (v.valueMultiplicative != 0);

	if(withBonus)
	{
		FactsAdd("modlt_v2_with_n", 1);
		FactsAdd("modlt_v2_with_sum", RoundMath(dmg));
	}
	else
	{
		FactsAdd("modlt_v2_without_n", 1);
		FactsAdd("modlt_v2_without_sum", RoundMath(dmg));
	}
	nWith = FactsQuerySum("modlt_v2_with_n");       sWith = FactsQuerySum("modlt_v2_with_sum");
	nWithout = FactsQuerySum("modlt_v2_without_n"); sWithout = FactsQuerySum("modlt_v2_without_sum");
	if(nWith > 0) { avgWith = sWith / (float)nWith; }
	if(nWithout > 0) { avgWithout = sWithout / (float)nWithout; }
	if(avgWithout > 0) { ratio = avgWith / avgWithout; }

	msg = "LT dmg: " + RoundMath(dmg);
	if(withBonus) { msg += " [trophy]"; } else { msg += " [no trophy]"; }
	msg += " | with: avg " + RoundMath(avgWith) + " (n=" + nWith + ") | without: avg " + RoundMath(avgWithout) + " (n=" + nWithout + ") | ratio " + ratio;
	thePlayer.DisplayHudMessage(msg);

	// mirror the totals into the user settings file (variables declared in SpoilsOfTheHuntTest.xml)
	// so they can be read from outside the game
	modLT_WriteSetting('LTwithN', nWith);
	modLT_WriteSetting('LTwithSum', sWith);
	modLT_WriteSetting('LTwithoutN', nWithout);
	modLT_WriteSetting('LTwithoutSum', sWithout);
	modLT_WriteSetting('LTratioX1000', RoundMath(ratio * 1000));
	// the attack power components the damage formula actually used: (dmg + base) * mult + add
	v = act.GetPowerStatValue();
	modLT_WriteSetting('LTpowerBaseX1000', RoundMath(v.valueBase * 1000));
	modLT_WriteSetting('LTpowerMultX1000', RoundMath(v.valueMultiplicative * 1000));
	modLT_WriteSetting('LTpowerAddX1000', RoundMath(v.valueAdditive * 1000));
	theGame.SaveUserSettings();
}

function modLT_WriteSetting(varName : name, value : int)
{
	theGame.GetInGameConfigWrapper().SetVarValue('SpoilsOfTheHuntTest', varName, IntToString(value));
}

@wrapMethod(W3HorseManager)
function EquipItem(id : SItemUniqueId) : SItemUniqueId
{
	var r : SItemUniqueId;

	r = wrappedMethod(id);
	modLT_TestAfterEquip();
	return r;
}

function modLT_TestAfterEquip()
{
	var tags : array<name>;
	var cats : array<EMonsterCategory>;
	var labels : array<string>;
	var templates : array<string>;
	var i : int;
	var v : SAbilityAttributeValue;
	var bonusName : name;
	var msg : string;
	var spawned : bool;

	tags.PushBack('SpoilsOfTheHunt');
	cats.PushBack(MC_Hybrid);     labels.PushBack("harpy");    templates.PushBack("characters\npc_entities\monsters\harpy_lvl1.w2ent");
	cats.PushBack(MC_Draconide);  labels.PushBack("wyvern");   templates.PushBack("characters\npc_entities\monsters\wyvern_lvl1.w2ent");
	cats.PushBack(MC_Vampire);    labels.PushBack("ekimmara"); templates.PushBack("characters\npc_entities\monsters\vampire_ekima_lvl1.w2ent");
	cats.PushBack(MC_Relic);      labels.PushBack("chort");    templates.PushBack("characters\npc_entities\monsters\czart_lvl1.w2ent");
	cats.PushBack(MC_Necrophage); labels.PushBack("drowner");  templates.PushBack("characters\npc_entities\monsters\drowner_lvl1.w2ent");
	cats.PushBack(MC_Troll);      labels.PushBack("nekker");   templates.PushBack("characters\npc_entities\monsters\nekker_lvl1.w2ent");
	cats.PushBack(MC_Specter);    labels.PushBack("wraith");   templates.PushBack("characters\npc_entities\monsters\wraith_lvl1.w2ent");
	cats.PushBack(MC_Cursed);     labels.PushBack("werewolf"); templates.PushBack("characters\npc_entities\monsters\werewolf_lvl1.w2ent");

	msg = "LT test:";
	spawned = false;
	for(i = 0; i < cats.Size(); i += 1)
	{
		bonusName = MonsterCategoryToAttackPowerBonus(cats[i]);
		v = thePlayer.GetAttributeValue(bonusName, tags);
		if(v.valueMultiplicative != 0)
		{
			msg += " " + NameToString(bonusName) + "=" + v.valueMultiplicative;
			if(!spawned)
			{
				modLT_SpawnHostile(templates[i], labels[i]);
				spawned = true;
				msg += " -> spawned " + labels[i];
			}
		}
	}
	if(!spawned)
	{
		// control group: no attack bonus active, spawn a harpy anyway so damage can be compared
		modLT_SpawnHostile(templates[0], labels[0]);
		msg += " no vs-class bonus on Geralt -> spawned control harpy";
	}
	thePlayer.DisplayHudMessage(msg);
	// oil check readout: the tagged Hybrid bonus at equip time must be 0 unless a griffin trophy is hung
	v = thePlayer.GetAttributeValue(MonsterCategoryToAttackPowerBonus(MC_Hybrid), tags);
	modLT_WriteSetting('LTequipHybridX1000', RoundMath(v.valueMultiplicative * 1000));
	if(spawned) { modLT_WriteSetting('LTequipAnyBonus', 1); } else { modLT_WriteSetting('LTequipAnyBonus', 0); }
	theGame.SaveUserSettings();
}

function modLT_SpawnHostile(templatePath : string, label : string)
{
	var template : CEntityTemplate;
	var ent : CEntity;
	var actor : CActor;
	var npc : CNewNPC;
	var pos, dir, hit, normal : Vector;
	var rot : EulerAngles;

	template = (CEntityTemplate)LoadResource(templatePath, true);
	if(!template)
	{
		thePlayer.DisplayHudMessage("LT test: template not found for " + label);
		return;
	}

	dir = theCamera.GetCameraDirection();
	dir.Z = 0;
	dir = VecNormalize(dir);
	dir.X *= 8;
	dir.Y *= 8;
	pos = thePlayer.GetWorldPosition() + dir;
	if(theGame.GetWorld().StaticTrace(pos + Vector(0, 0, 5), pos - Vector(0, 0, 5), hit, normal))
	{
		pos = hit;
	}
	rot = thePlayer.GetWorldRotation();
	rot.Yaw += 180;

	ent = theGame.CreateEntity(template, pos, rot);
	actor = (CActor)ent;
	if(actor)
	{
		actor.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	}
	// scale to Geralt so it survives several hits and damage numbers can be compared
	npc = (CNewNPC)ent;
	if(npc)
	{
		npc.SetLevel(GetWitcherPlayer().GetLevel());
	}
}
