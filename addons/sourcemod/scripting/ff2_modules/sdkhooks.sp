/*
	Optional:
	tf2attributes.sp
	tts.sp
*/

#define FF2_SDKHOOKS

Handle SDKEquipWearable;

void SDK_Setup()
{
	GameData gameData = new GameData("ff2");
	if(gameData == INVALID_HANDLE)
	{
		LogError2("[Gamedata] Failed to find ff2.txt");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(SDKEquipWearable == null)
		LogError2("[Gamedata] Failed to create call: CBasePlayer::EquipWearable");

	#if defined FF2_DHOOKS
	DHook_Setup(gameData);
	#endif

	delete gameData;
}

stock int SDK_SpawnWeapon(int client, const char[] name, int index, int level, int quality, char[] attributes)
{
	int entity = CreateEntityByName(name);
	if(!IsValidEntity(entity))
		return -1;

	SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(entity, Prop_Send, "m_bInitialized", 1);

	static char netClass[64];
	GetEntityNetClass(entity, netClass, sizeof(netClass));
	SetEntData(entity, FindSendPropInfo(netClass, "m_iEntityQuality"), quality);
	SetEntData(entity, FindSendPropInfo(netClass, "m_iEntityLevel"), level);

	SetEntProp(entity, Prop_Send, "m_iEntityQuality", quality);
	SetEntProp(entity, Prop_Send, "m_iEntityLevel", level);

	#if defined FF2_TF2ATTRIBUTES
	if(attributes[0] && TF2Attributes)
	{
		static char atts[32][16];
		int count = ExplodeString(attributes, " ; ", atts, sizeof(atts), sizeof(atts[]));
		if(count > 1)
		{
			for(int i; i<count; i+=2)
			{
				TF2Attrib_SetByDefIndex(entity, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			}
		}
	}
	#endif

	DispatchSpawn(entity);
	if(!StrContains(name, "tf_weap", false))
	{
		EquipPlayerWeapon(client, entity);
		return entity;
	}

	if(SDKEquipWearable != null)
		SDKCall(SDKEquipWearable, client, entity);

	return entity;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(Enabled<=Game_Disabled || damage<=0 || !IsValidClient(client))
		return Plugin_Continue;

	if((attacker<1 || client==attacker))
	{
		if(Boss[client].Active)
		{
			if(Boss[client].Knockback < 2)
				return (damagetype & DMG_FALL) ? Plugin_Handled : Boss[client].Knockback==1 ? Plugin_Continue : Plugin_Handled;
		}
		else if(Enabled==Game_Arena && (damagetype & DMG_FALL))
		{
			bool changed;
			for(int i; i<3; i++)
			{
				if(Weapon[client][i].Fall == 1)
					continue;

				damage *= Weapon[client][i].Fall;
				changed = true;
			}

			if(changed)
				return Plugin_Changed;
		}
		return Plugin_Continue;
	}

	if(!IsValidClient(attacker) || IsInvuln(client))
		return Plugin_Continue;

	if(!Boss[client].Active)
	{
		if(!Boss[attacker].Active || TF2_IsPlayerInCondition(client, TFCond_Bonked))
			return Plugin_Continue;

		if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
		{
			damage /= 2.0;
			return Plugin_Changed;
		}

		if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
		{
			damage /= 3.0;
			return Plugin_Changed;
		}

		if(damage<=160 && Boss[attacker].Triple)
		{
			damage *= 3;
			return Plugin_Changed;
		}
		return Plugin_Continue;
	}

	static char buffer[PLATFORM_MAX_PATH];
	int index = -1;
	if(weapon>MaxClients && IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		GetEntityClassname(weapon, buffer, sizeof(buffer));
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	}
	else
	{
		buffer[0] = 0;
	}

	if(damagecustom!=TF_CUSTOM_BACKSTAB && damagecustom!=TF_CUSTOM_TELEFRAG)
	{
		if(weapon!=4095 && !StrContains(buffer, "tf_weapon_knife", false) && damage>1000.0)
		{
			damagecustom = TF_CUSTOM_BACKSTAB;
		}
		else if(!buffer[0] && (damagetype & DMG_CRUSH) && damage==1000.0)
		{
			damagecustom = TF_CUSTOM_TELEFRAG;
		}
	}

	static float position[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
	if(damagecustom == TF_CUSTOM_BACKSTAB)
	{
		int health;
		int team = GetClientTeam(client);
		for(int i=1; i<=MaxClients; i++)
		{
			if(i==client || (Boss[i].Active && GetClientTeam(i)==team))
				health += Boss[i].MaxHealth*Boss[i].MaxLives;
		}

		#if defined FF2_TIMESTEN
		damage = Pow(health, 0.65-(Weapon[attacker][2].Stale++*0.01))*(1.0+(0.5*(TimesTen_Value()-1.0)));
		#else
		damage = Pow(health, 0.65-(Weapon[attacker][2].Stale++*0.01));
		#endif
		damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;

		Action action = Plugin_Continue;
		Call_StartForward(OnBackstabbed);
		Call_PushCell(boss);
		Call_PushCell(client);
		Call_PushCell(attacker);
		Call_Finish(action);
		if(action == Plugin_Handled)
			return Plugin_Handled;

		ClientCommand(client, "playgamesound TFPlayer.CritPain");
		ClientCommand(attacker, "playgamesound TFPlayer.CritPain");

		float gameTime = GetGameTime();
		float delay = Boss[attacker].Active ? gameTime+1.5 : gameTime+2.0;
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", delay;
		SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", delay);
		SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", delay);

		health = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
		if(health>MaxClients && IsValidEntity(health) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
		{
			switch(index)
			{
				case 225, 356, 423, 461, 574, 649, 1071, 30758:
					team = 16;

				case 638:
					team = 32;

				default:
					team = 42;
			}
			SetEntProp(health, Prop_Send, "m_nSequence", team);
		}

		if(!(Client[attacker].Pref[Pref_Hud] & HUD_MESSAGE))
		{
			KvGetLang(Special[Boss[client].Special].Kv, "name", buffer, sizeof(buffer));
			CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Player Backstab", buffer);
		}

		if(Boss[attacker].Active || (index!=225 && index!=574))  //Your Eternal Reward, Wanga Prick
		{
			ClientCommand(client, "playgamesound Player.Spy_Shield_Break");
			ClientCommand(attacker, "playgamesound Player.Spy_Shield_Break");

			if(!(Client[client].Pref[Pref_Hud] & HUD_MESSAGE))
			{
				if(Boss[attacker].Active)
				{
					KvGetLang(Special[Boss[attacker].Special].Kv, "name", buffer, sizeof(buffer));
				}
				else
				{
					GetClientName(attacker, buffer, sizeof(buffer));
				}

				CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", GetClientAimTarget(attacker, true)==client ? "Player Backstabbed" : "Player Trickstabbed", buffer);
			}

			PlayBossSound(client, "sound_stabbed");
			HealthBarFor = gameTime+1.0;
		}

		if(!Boss[attacker].Active)
		{
			switch(index)
			{
				case 225, 574:
				{
					CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
				}
				case 356:
				{
					int health = GetClientHealth(attacker);
					if(health < 600)
					{
						int add = Weapon[attacker][2].Stale<6 ? 100 : 225-(Weapon[attacker][2].Stale*25);
						if(health+add > 600)
							add = health-add;

						SetEntityHealth(attacker, health+add);
						HealMessage(attacker, attacker, add);
					}
				}
				case 461:
				{
					SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);
					if(Weapon[attacker][2].Stale < 11)
						TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0-(Weapon[attacker][2].Stale*0.25));
				}
			}

			if(GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 525)
				SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+2);
		}

		Bosses_AbilitySlot(boss, 6);
		return (action == Plugin_Stop) ? Plugin_Handled : Plugin_Changed;
	}
	else if(damagecustom == TF_CUSTOM_TELEFRAG)
	{
		if(!IsPlayerAlive(attacker))
		{
			damage = 1.0;
			return Plugin_Changed;
		}

		int owner = FindTeleOwner(attacker);
		if(IsValidClient(owner) && owner!=attacker)
		{
			if(Boss[attacker].Active)
			{
				#if defined FF2_TIMESTEN
				damage = 3600.0*(1.0+(0.5*(TimesTen_Value()-1.0)));
				#else
				damage = 3600.0;
				#endif
			}
			else
			{
				#if defined FF2_TIMESTEN
				damage = 2400.0*(1.0+(0.5*(TimesTen_Value()-1.0)));
				#else
				damage = 2400.0;
				#endif
			}

			if(GetClientTeam(owner) == GetClientTeam(attacker))
				Client[owner].Damage += RoundFloat(damage*2);
		}
		else
		{
			#if defined FF2_TIMESTEN
			damage = 1800.0*(1.0+(0.5*(TimesTen_Value()-1.0)));
			#else
			damage = 1800.0;
			#endif
		}
		damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;

		if(!(Client[attacker].Pref[Pref_Hud] & HUD_MESSAGE))
		{
			KvGetLang(Special[Boss[client].Special].Kv, "name", buffer, sizeof(buffer));
			CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Player Telefrag", buffer);
		}

		if(!(Client[client].Pref[Pref_Hud] & HUD_MESSAGE))
		{
			if(Boss[attacker].Active)
			{
				KvGetLang(Special[Boss[attacker].Special].Kv, "name", buffer, sizeof(buffer));
			}
			else
			{
				GetClientName(attacker, buffer, sizeof(buffer));
			}

			CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Player Telefraged", buffer);
		}

		PlayBossSound(client, "sound_telefraged", 1);
		HealthBarFor = GetGameTime()+1.0;
		return Plugin_Changed;
	}

	if(Boss[attacker].Active || Client[attacker].Minion)
		return Plugin_Continue;

	int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)==weapon ? TFWeaponSlot_Primary : GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)==weapon ? TFWeaponSlot_Secondary : GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)==weapon ? TFWeaponSlot_Melee : -1;
	if(slot == -1)
	{
		if(!(damagetype & DMG_BLAST) || inflictor<=MaxClients || !IsValidEntity(inflictor) || !GetEntityClassname(inflictor, buffer, sizeof(buffer)) || !StrEqual(buffer, "obj_sentrygun"))
			return Plugin_Continue;

		damagetype |= DMG_PREVENT_PHYSICS_FORCE;
		return Plugin_Changed;
	}

	if(Enabled != Game_Arena)
		return Plugin_Continue;

	bool changed, stale;
	if(Weapon[attacker][slot].Crit > 1)
	{
		damagetype |= DMG_CRIT;
		changed = true;
	}

	if(Weapon[attacker][slot].NoForce)
	{
		damagetype |= DMG_PREVENT_PHYSICS_FORCE;
		changed = true;
	}

	if(Weapon[attacker][slot].Stun>0 && !TF2_IsPlayerInCondition(client, TFCond_Dazed))
	{
		stale = true;
		if(!Weapon[attacker][slot].Stale)
		{
			TF2_StunPlayer(client, Weapon[attacker][slot].Stun, 0.25, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
		}
		else
		{
			if(Weapon[attacker][slot].Stun >= 0.75)
			{
				float duration = Weapon[attacker][slot].Stun-((Weapon[attacker][slot].Stale-1)*0.25);
				if(duration < 0.5)
					duration = 0.5;

				TF2_StunPlayer(client, duration, 0.25, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
			}
			else
			{
				TF2_StunPlayer(client, Weapon[attacker][slot].Stun, 0.25, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
			}
		}
	}

	if(Weapon[attacker][slot].Uber)
	{
		int[] healers = new int[MaxClients];
		int count;
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && IsPlayerAlive(target) && GetHealingTarget(target, true)==attacker)
				healers[count++] = healer;
		}

		for(int i; i<count; i++)
		{
			int medigun = GetPlayerWeaponSlot(healers[i], TFWeaponSlot_Secondary);
			if(!IsValidEntity(medigun))
				continue;

			GetEntityClassname(medigun, buffer, sizeof(buffer));
			if(!StrEqual(buffer, "tf_weapon_medigun", false))
				continue;

			float uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(Weapon[attacker][slot].Uber/100/count);
			if(uber > 1.0)
				uber = 1.0;

			SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
		}
	}

	if(Weapon[attacker][slot].HealthKit)
	{
		stale = true;
		SpawnSmallHealthPackAt(client, GetClientTeam(attacker), attacker, Weapon[attacker][slot].Stale);
	}

	if(damagetype & DMG_CRIT)
	{
		if(Weapon[attacker][slot].Damage[2] != 1)
		{
			damage *= Weapon[attacker][slot].Damage[2];
			changed = true;
		}
	}
	else if(IsPlayerMiniCritBuffed(client))
	{
		if(Weapon[attacker][slot].Damage[1] != 1)
		{
			damage *= Weapon[attacker][slot].Damage[1];
			changed = true;
		}
	}
	else if(Weapon[attacker][slot].Damage[0] != 1)
	{
		damage *= Weapon[attacker][slot].Damage[0];
		changed = true;
	}

	switch(index)
	{
		case 132, 266, 482, 1082:
		{
			if(Weapon[attacker][slot].Special)
			{
				stale = true;
				IncrementHeadCount(attacker, RoundFloat(Weapon[attacker][slot].Special));
			}
		}
		case 307:
		{
			if(Weapon[attacker][slot].Special < 1)
				Weapon[attacker][slot].Special = 1.0;

			stale = true;
			if(Weapon[attacker][slot].Stab && Weapon[attacker][slot].Special<3 && !GetEntProp(weapon, Prop_Send, "m_iDetonated"))
			{
				float health;
				int team = GetClientTeam(client);
				for(int i=1; i<=MaxClients; i++)
				{
					if(i==client || (Boss[i].Active && GetClientTeam(i)==team))
						health += Boss[i].MaxHealth*Boss[i].MaxLives;
				}

				#if defined FF2_TIMESTEN
				damage = Pow(health, 0.67-(Weapon[attacker][slot].Stale*0.02)-(Weapon[attacker][slot].Special*0.5))*Weapon[attacker][slot].Stab*(1.0+(0.5*(TimesTen_Value()-1.0)));
				#else
				damage = Pow(health, 0.67-(Weapon[attacker][slot].Stale*0.02)-(Weapon[attacker][slot].Special*0.5))*Weapon[attacker][slot].Stab;
				#endif
				damagetype |= DMG_CRIT;

				if(!(Client[attacker].Pref[Pref_Hud] & HUD_MESSAGE))
				{
					KvGetLang(Special[Boss[client].Special].Kv, "name", buffer, sizeof(buffer));
					CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Player Caber", buffer);
				}

				if(!(Client[client].Pref[Pref_Hud] & HUD_MESSAGE))
				{
					if(Boss[attacker].Active)
					{
						KvGetLang(Special[Boss[attacker].Special].Kv, "name", buffer, sizeof(buffer));
					}
					else
					{
						GetClientName(attacker, buffer, sizeof(buffer));
					}

					CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Player Cabered", buffer);
				}

				ClientCommand(attacker, "playgamesound Halloween.LightsOff");
				ClientCommand(client, "playgamesound Halloween.LightsOn");

				PlayBossSound(client, "sound_cabered");
				HealthBarFor = GetGameTime()+2.0;
				changed = true;
			}
		}
		case 357:
		{
			if(Weapon[attacker][slot].Special > 0)
			{
				int health = GetClientHealth(attacker);
				int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth")*2;
				if(Weapon[attacker][slot].Stale>24 || GetEntProp(weapon, Prop_Send, "m_bIsBloody"))
				{
					if(health < max)
					{
						int add = RoundFloat(Weapon[attacker][slot].Special);
						if(health+add > max)
							add = max-health;

						SetEntityHealth(attacker, health+add);
						HealMessage(attacker, attacker, add);
					}
				}
				else
				{
					if(health < max)
					{
						int add = RoundToFloor(max/(4.0+Weapon[attacker][slot].Stale));
						if(health+add > max)
							add = max-health;

						SetEntityHealth(attacker, health+add);
						HealMessage(attacker, attacker, add);
					}

					stale = true;
					if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						TF2_RemoveCondition(attacker, TFCond_OnFire);
				}

				SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
				if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
					SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
			}
		}
		case 416:
		{
			if(Weapon[attacker][slot].Stab && RemoveCond(attacker, TFCond_BlastJumping))
			{
				float health;
				int team = GetClientTeam(client);
				for(int i=1; i<=MaxClients; i++)
				{
					if(i==client || (Boss[i].Active && GetClientTeam(i)==team))
						health += Boss[i].MaxHealth*Boss[i].MaxLives;
				}

				#if defined FF2_TIMESTEN
				damage = Pow(health, 0.625-(Weapon[attacker][slot].Stale*0.015))*Weapon[attacker][slot].Stab*(1.0+(0.5*(TimesTen_Value()-1.0)));
				#else
				damage = Pow(health, 0.625-(Weapon[attacker][slot].Stale*0.015))*Weapon[attacker][slot].Stab;
				#endif
				damagetype |= DMG_CRIT;

				if(RemoveCond(attacker, TFCond_Parachute))
					damage *= 0.85;

				if(!(Client[attacker].Pref[Pref_Hud] & HUD_MESSAGE))
				{
					KvGetLang(Special[Boss[client].Special].Kv, "name", buffer, sizeof(buffer));
					CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Player Market", buffer);
				}

				if(!(Client[client].Pref[Pref_Hud] & HUD_MESSAGE))
				{
					if(Boss[attacker].Active)
					{
						KvGetLang(Special[Boss[attacker].Special].Kv, "name", buffer, sizeof(buffer));
					}
					else
					{
						GetClientName(attacker, buffer, sizeof(buffer));
					}

					CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Player Marketed", buffer);
				}

				ClientCommand(attacker, "playgamesound TFPlayer.DoubleDonk");
				ClientCommand(client, "playgamesound TFPlayer.DoubleDonk");

				PlayBossSound(client, "sound_marketed");
				Bosses_AbilitySlot(client, 7);
				HealthBarFor = GetGameTime()+1.0;
				changed = true;
				stale = true;
			}
		}
		case 525, 595:  //Diamondback, Manmelter
		{
			if(Weapon[attacker][slot].Special && GetEntProp(attacker, Prop_Send, "m_iRevengeCrits"))
			{
				damage *= Weapon[attacker][slot].Special;
				changed = true;
			}
		}
		case 594:  //Phlogistinator
		{
			if(Weapon[attacker][slot].Special && !TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
			{
				damage *= Weapon[attacker][slot].Special;
				changed = true;
			}
		}
		case 752:
		{
			if(Weapon[attacker][slot].Special > 0)
			{
				float focus = (10+(GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage")/10))*Weapon[attacker][slot].Special;
				if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
					focus /= 3;

				float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
				SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
			}
		}
	}

	if(stale)
		Weapon[attacker][slot].Stale++;

	return changed ? Plugin_Changed : Plugin_Continue;
}

public Action OnTakeDamageAlive(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(Enabled<=Game_Disabled || damage<=0 || !IsValidClient(client))
		return Plugin_Continue;

	static char buffer[64];
	if(!IsValidClient(attacker))
	{
		if(!IsValidEntity(attacker) || !Boss[client].Active || !GetEntityClassname(attacker, buffer, sizeof(buffer)) || !StrEqual(buffer, "trigger_hurt", false))
			return Plugin_Continue;

		Action action = Plugin_Continue;
		Call_StartForward(OnTriggerHurt);
		Call_PushCell(Boss[client].Leader ? 0 : client);
		Call_PushCell(attacker);
		float damage2 = damage;
		Call_PushFloatRef(damage2);
		Call_Finish(action);
		if(action==Plugin_Stop || action==Plugin_Handled)
			return action;

		if(action == Plugin_Changed)
			damage = damage2;

		if(damage > 600.0)
			damage = 600.0;


		#if defined FF2_TTS
		TTS_Add(client, damage);
		#endif

		Boss[client].Charge[0] += damage*90.0/Boss[client].RageDamage;
		if(Boss[client].Charge[0] > Boss[client].RageMax)
			Boss[client].Charge[0] = Boss[client].RageMax;

		return Plugin_Changed;
	}

	if(!Boss[client].Active)
	{
		if(Enabled==Game_Arena && !Client[client].Minion && !IsInvuln(client))
		{
			for(int i; i<3; i++)
			{
				if(!Weapon[client][i].Shield)
					continue;

				if(GetClientHealth(client) > damage*1.15)
					break;

				RemoveShield(client, attacker, Weapon[client][i].Shield);
				Weapon[client][i].Shield = 0;
				return Plugin_Handled;
			}
		}
		return Plugin_Continue;
	}

	if(IsInvuln(client))
		return Plugin_Continue;

	Boss[client].Charge[0] += damage*100.0/Boss[client].RageDamage;
	if(Boss[client].Charge[0] > Boss[client].RageMax)
		Boss[client].Charge[0] = Boss[client].RageMax;

	if(Boss[attacker].Active || Client[attacker].Minion)
		return Plugin_Continue;

	int add = RoundToFloor(damage/500.0);
	if((damage%500.0)+(Client[attacker].Damage%500.0) >= 500)
		add++;

	Client[attacker].Damage += RoundFloat(damage);
	if(add)
		SetEntProp(attacker, Prop_Send, "m_nStreaks", GetEntProp(attacker, Prop_Send, "m_nStreaks")+add);

	if(Enabled!=Game_Arena || weapon<=MaxClients || !IsValidEntity(weapon) || !HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
		return Plugin_Continue;

	int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)==weapon ? TFWeaponSlot_Primary : GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)==weapon ? TFWeaponSlot_Secondary : GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)==weapon ? TFWeaponSlot_Melee : -1;
	if(slot == -1)
		return Plugin_Continue;

	if(Boss[client].Active && Weapon[attacker][slot].Outline)
	{
		float gameTime = GetGameTime();
		if(gameTime > Client[client].GlowFor)
		{
			Client[client].GlowFor = (damage/100*Weapon[attacker][slot].Outline)+gameTime;
		}
		else
		{
			Client[client].GlowFor += (damage/100*Weapon[attacker][slot].Outline);
		}

		if(Client[client].GlowFor > gameTime+30.0)
			Client[client].GlowFor = gameTime+30.0;
	}

	int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	switch(index)
	{
		case 306:
		{
			if(Weapon[attacker][slot].Special > Weapon[attacker][slot].Stale)
			{
				SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
				SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
			}
		}
		case 1104:
		{
			if(Weapon[attacker][slot].Special > 0)
			{
				Weapon[attacker][slot].Stab += damage;

				int i;
				while(i<5 && Weapon[attacker][slot].Stab>Weapon[attacker][slot].Special)
				{
					Weapon[attacker][slot].Stab -= Weapon[attacker][slot].Special;
					i++;
				}

				if(i)
					SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+i);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnGetMaxHealth(int client, int &health)
{
	if(!IsValidClient(client) || !Boss[client].Active)
		return Plugin_Continue;

	// Context: Some players have HUDs with flashy low health, make it so it happens at a lesser amount of health (25% Boss Health = 50% Visual Health)
	health = Boss[client].MaxHealth-GetClientHealth(client);
	health = health>0 ? Boss[client].MaxHealth-(health*2/3) : Boss[client].MaxHealth;
	return Plugin_Changed;
}
