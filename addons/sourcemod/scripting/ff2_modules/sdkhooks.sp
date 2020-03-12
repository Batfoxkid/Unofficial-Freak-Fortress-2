/*
	Optional:
	tf2attributes.sp
*/

#define FF2_SDKHOOKS

static Handle SDKEquipWearable;

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
	if(!StrContains(name, "tf_weap"))
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
	if(!Enabled || damage<=0 || !IsValidClient(client))
		return Plugin_Continue;

	if((attacker<1 || client==attacker) && Boss[client].Active && Boss[client].Knockback<2)
		return (damagetype & DMG_FALL) ? Plugin_Handled : Boss[client].Knockback==1 ? Plugin_Continue : Plugin_Handled;

	static char buffer[PLATFORM_MAX_PATH];
	if(!IsValidClient(attacker) && IsValidEntity(attacker))
	{
		if(GetEntityClassname(attacker, buffer, sizeof(buffer)) && StrEqual(buffer, "trigger_hurt", false))
		{
			if(SpawnTeleOnTriggerHurt && IsBoss(client) && CheckRoundState()==1)
			{
				HazardDamage[client] += damage;
				if(HazardDamage[client] >= cvarDamageToTele.FloatValue)
				{
					TeleportToMultiMapSpawn(client);
					HazardDamage[client] = 0.0;
				}
			}

			Action action = Plugin_Continue;
			Call_StartForward(OnTriggerHurt);
			Call_PushCell(boss);
			Call_PushCell(attacker);
			float damage2 = damage;
			Call_PushFloatRef(damage2);
			Call_Finish(action);
			if(action!=Plugin_Stop && action!=Plugin_Handled)
			{
				if(action == Plugin_Changed)
					damage = damage2;

				if(damage > 600.0)
					damage = 600.0;

				BossHealth[boss] -= RoundFloat(damage);
				BossCharge[boss][0] += damage*100.0/BossRageDamage[boss];
				if(BossHealth[boss] < 1)
					damage *= 5;

				if(BossCharge[boss][0] > rageMax[client])
					BossCharge[boss][0] = rageMax[client];

				return Plugin_Changed;
			}
			else
			{
				return action;
			}
		}
	}
	else if(IsInvuln(client))
	{
	}
	else if(!Boss[client].Active)
	{
		if(Boss[attacker].Active && !TF2_IsPlayerInCondition(client, TFCond_Bonked))
		{
			if(shield[client] && cvarShieldType.IntValue==1)
			{
				RemoveShield(client, attacker);
				return Plugin_Handled;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage /= 2.0;
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage /= 3.0;
				return Plugin_Changed;
			}

			if(damage<=160.0 && Boss[attacker].Triple)
			{
				damage *= 3;
				return Plugin_Changed;
			}
		}
	}
	else
	{
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

			EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
			EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);

			float delay = Boss[attacker].Active ? GetGameTime()+1.5 : GetGameTime()+2.0;
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

			if(!(Client[attacker].Hud & HUD_MESSAGE))
			{
				KvGetLang(Special[Boss[client].Special].Kv, "name", buffer, sizeof(buffer));
				CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Player Backstab", buffer);
			}

			if(index!=225 && index!=574)  //Your Eternal Reward, Wanga Prick
			{
				EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
				EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);

				if(!(Client[client].Hud & HUD_MESSAGE))
				{
					if(Boss[attacker].Active)
					{
						KvGetLang(Special[Boss[attacker].Special].Kv, "name", buffer, sizeof(buffer));
					}
					else
					{
						GetClientName(attacker, buffer, sizeof(buffer));
					}

					CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Player Backstabbed", buffer);
				}

				if(Boss[client].Health() > damage*3)
				{
					if(RandomSound("sound_stabbed", buffer, sizeof(buffer), client))
						EmitSoundToAllExcept(buffer, _, _, _, _, _, _, attacker);
				}

				HealthBarFor = delay;
			}

			switch(index)
			{
				case 225, 574:	//Your Eternal Reward, Wanga Prick
				{
					CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
				}
				case 356:	//Conniver's Kunai
				{
					int health = GetClientHealth(attacker);
					if(health < 600)
					{
						health += Weapon[attacker][2].Stale<6 ? 100 : 225-(Weapon[attacker][2].Stale*25);
						if(health > 600)
							health = 600;

						SetEntityHealth(attacker, health);
					}
				}
				case 461:	//Big Earner
				{
					SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);
					if(Weapon[attacker][2].Stale < 11)
						TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0-(Weapon[attacker][2].Stale*0.25));
				}
			}

			if(GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 525)  //Diamondback
				SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+2);

			ActivateAbilitySlot(boss, 6);

			if(action == Plugin_Handled)
			{
				damage = 0.0;
				return Plugin_Handled;
			}
			return Plugin_Changed;
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
					Damage[owner] += damage*2;
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

			if(!(Client[attacker].Hud & HUD_MESSAGE))
			{
				KvGetLang(Special[Boss[client].Special].Kv, "name", buffer, sizeof(buffer));
				CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Player Telefrag", buffer);
			}

			if(!(Client[attacker].Hud & HUD_MESSAGE))
			{
				if(Boss[attacker].Active)
				{
					KvGetLang(Special[Boss[attacker].Special].Kv, "name", buffer, sizeof(buffer));
				}
				else
				{
					GetClientName(attacker, buffer, sizeof(buffer));
				}

				CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Player Telefraged", buffer);
			}

			if(RandomSound("sound_telefraged", buffer, sizeof(buffer), client))
				EmitSoundToAllExcept(sound);

			HealthBarFor = GetGameTime()+2.0;
			return Plugin_Changed;
		}

		if(Boss[attacker].Active)
			return Plugin_Continue;

		int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)==weapon ? TFWeaponSlot_Primary : GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)==weapon ? TFWeaponSlot_Secondary : GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)==weapon ? TFWeaponSlot_Melee : -1;
		if(slot == -1)
		{
			if(!(damagetype & DMG_BLAST) || inflictor<=MaxClients || !IsValidEntity(inflictor) || !GetEntityClassname(inflictor, buffer, sizeof(buffer)) || !StrEqual(buffer, "obj_sentrygun"))
				return Plugin_Continue;

			damagetype |= DMG_PREVENT_PHYSICS_FORCE;
			return Plugin_Changed;
		}

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

		if(Weapon[attacker][slot].Outline)
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
			SpawnSmallHealthPackAt(client, GetClientTeam(attacker), attacker);
		}

		if(!StrContains(buffer, "tf_weapon_sniperrifle"))
		{
			if(CheckRoundState() == 1)
			{
				if(index == 752)  //Hitman's Heatmaker
				{
					float focus = 10+(GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage")/10);
					if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
						focus /= 3;

					float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
					SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
				}
				else if(index!=230 && index!=402 && index!=526 && index!=30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
				{
					float gameTime = GetGameTime();
					float time = (Client[client].GlowFor>10+gameTime ? 1.0 : 2.0);
					time += (time==1 ? (Client[client].GlowFor>20 ? 1.0 : 2.0) : 4.0)*(GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage")/100.0);
					Client[client].GlowFor = GetGameTime()+time;
					if(time > 25.0)
						time = 25.0;
				}

				if(!(damagetype & DMG_CRIT))
				{
					if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
					{
						damage *= SniperMiniDamage;
					}
					else if(index!=230 || BossCharge[boss][0]>90.0)  //Sydney Sleeper
					{
						damage *= SniperDamage;
					}
					else
					{
						damage *= (SniperDamage*0.8);
					}
					return Plugin_Changed;
				}
			}
		}
		else if(!StrContains(buffer, "tf_weapon_compound_bow"))
		{
			if(CheckRoundState() != 2)
			{
				if((damagetype & DMG_CRIT))
				{
					damage *= BowDamage;
					return Plugin_Changed;
				}
				else if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
				{
					if(BowDamageMini > 0)
					{
						damage *= BowDamageMini;
						return Plugin_Changed;
					}
				}
				else if(BowDamageNon>0)
				{
					damage *= BowDamageNon;
					return Plugin_Changed;
				}
			}
		}

		if(Weapon[attacker][slot].Special)
		{
		switch(index)
		{
			case 132, 266, 482, 1082:  //Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander
			{
				if(Weapon[attacker][slot].Special)
				{
					stale = true;
					IncrementHeadCount(attacker, Weapon[attacker][slot].Special);
				}
			}
			case 307:  //Ullapool Caber
			{
				if(Weapon[attacker][slot].Stab && Weapon[attacker][slot].Special<4 && !GetEntProp(weapon, Prop_Send, "m_iDetonated"))
				{
					if(TimesTen)
					{
						damage = ((Pow(float(BossHealthMax[boss]), 0.74074)-(Cabered[client]/128.0*float(BossHealthMax[boss])))/(3+(cvarTimesTen.FloatValue*allowedDetonations*3)))*bosses;
					}
					else if(cvarLowStab.BoolValue)
					{
						damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+(2000.0/float(playing))+206.0-(Cabered[client]/128.0*float(BossHealthMax[boss])))/(3+(allowedDetonations*3)))*bosses;
					}
					else
					{
						damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+512.0-(Cabered[client]/128.0*float(BossHealthMax[boss])))/(3+(allowedDetonations*3)))*bosses;
					}
					damagetype |= DMG_CRIT;

					if(Weapon[attacker][slot].Special < 3)
					{
						if(!HudSettings[attacker][2] && !(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
						{
							GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
							CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Player Caber", spcl);

				case 2:
					ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Caber Player", spcl);

				default:
					PrintHintText(attacker, "%t", "Caber Player", spcl);
								}
							}
							else
							{
								switch(Annotations)
								{
				case 1:
					CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Caber");

				case 2:
					ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Caber");

				default:
					PrintHintText(attacker, "%t", "Caber");
								}
							}
						}
						if(!HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
						{
							if(TellName)
							{
								switch(Annotations)
								{
				case 1:
					CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Cabered Player", attacker);

				case 2:
					ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Cabered Player", attacker);

				default:
					PrintHintText(client, "%t", "Cabered Player", attacker);
								}
							}
							else
							{
								switch(Annotations)
								{
				case 1:
					CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Cabered");

				case 2:
					ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Cabered");

				default:
					PrintHintText(client, "%t", "Cabered");
								}
							}
						}

						EmitSoundToClient(attacker, "ambient/lightsoff.wav", _, _, _, _, 0.6, _, _, position, _, false);
						EmitSoundToClient(client, "ambient/lightson.wav", _, _, _, _, 0.6, _, _, position, _, false);

						if(BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1) > damage*3)
						{
							static char sound[PLATFORM_MAX_PATH];
							if(RandomSound("sound_cabered", sound, sizeof(sound)))
								EmitSoundToAllExcept(sound);
						}

						HealthBarMode = true;
						CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
					}
					return Plugin_Changed;
				}
			}
			case 310:  //Warrior's Spirit
			{
				if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
				{
					int health = GetClientHealth(attacker);
					int newhealth = health+50;
					if(newhealth <= GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						SetEntityHealth(attacker, newhealth);
				}
			}
			case 317:  //Candycane
			{
				SpawnSmallHealthPackAt(client, GetClientTeam(attacker), attacker);
			}
			case 327:  //Claidheamh Mor
			{
				if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
				{
					float charge=GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
					if(charge+25.0 >= 100.0)
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", 100.0);
					}
					else
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", charge+25.0);
					}
				}
			}
			case 348:  //Sharpened Volcano Fragment
			{
				if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
				{
					int health = GetClientHealth(attacker);
					int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
					int newhealth = health+5;
					if(health < max+60)
					{
						if(newhealth > max+60)
							newhealth=max+60;

						SetEntityHealth(attacker, newhealth);
					}
				}
			}
			case 357:  //Half-Zatoichi
			{
				int health = GetClientHealth(attacker);
				int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
				int max2 = RoundToFloor(max*2.0);
				int newhealth;
				if(GetEntProp(weapon, Prop_Send, "m_bIsBloody"))	// Less effective used more than once
				{
					newhealth = health+25;
					if(health < max2)
					{
						if(newhealth > max2)
							newhealth = max2;

						SetEntityHealth(attacker, newhealth);
					}
				}
				else	// Most effective on first hit
				{
					newhealth = health + RoundToFloor(max/2.0);
					if(health < max2)
					{
						if(newhealth > max2)
							newhealth = max2;

						SetEntityHealth(attacker, newhealth);
					}
					if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						TF2_RemoveCondition(attacker, TFCond_OnFire);
				}
				SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
				if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
					SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
			}
			case 416:  //Market Gardener (courtesy of Chdata)
			{
				if(RemoveCond(attacker, TFCond_BlastJumping) && cvarMarket.FloatValue)	// New way to check explosive jumping status
				//if((FF2flags[attacker] & FF2FLAG_ROCKET_JUMPING) && cvarMarket.FloatValue)
				{
					if(TimesTen)
					{
						damage = ((Pow(float(BossHealthMax[boss]), 0.74074)-(Marketed[client]/128.0*float(BossHealthMax[boss])))/(cvarTimesTen.FloatValue*3))*bosses*cvarMarket.FloatValue;
					}
					else if(cvarLowStab.BoolValue)
					{
						damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+(1750.0/float(playing))+206.0-(Marketed[client]/128.0*float(BossHealthMax[boss])))/3)*bosses*cvarMarket.FloatValue;
					}
					else
					{
						damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+512.0-(Marketed[client]/128.0*float(BossHealthMax[boss])))/3)*bosses*cvarMarket.FloatValue;
					}
					damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;

					if(RemoveCond(attacker, TFCond_Parachute))	// If you parachuted to do this, remove your parachute.
						damage *= 0.8;	// And nerf your damage

					if(Marketed[client] < 5)
						Marketed[client]++;

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							static char spcl[64];
							GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
							switch(Annotations)
							{
								case 1:
				CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Market Gardener Player", spcl);

								case 2:
				ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Market Gardener Player", spcl);

								default:
				PrintHintText(attacker, "%t", "Market Gardener Player", spcl);
							}
						}
						else
						{
							switch(Annotations)
							{
								case 1:
				CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Market Gardener");

								case 2:
				ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Market Gardener");

								default:
				PrintHintText(attacker, "%t", "Market Gardener");
							}
						}
					}

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							switch(Annotations)
							{
								case 1:
				CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Market Gardened Player", attacker);

								case 2:
				ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Market Gardened Player", attacker);

								default:
				PrintHintText(client, "%t", "Market Gardened Player", attacker);
							}
						}
						else
						{
							switch(Annotations)
							{
								case 1:
				CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Market Gardened");

								case 2:
				ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Market Gardened");

								default:
				PrintHintText(client, "%t", "Market Gardened");
							}
						}
					}

					EmitSoundToClient(attacker, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
					EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);

					if(BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1) > damage*3)
					{
						static char sound[PLATFORM_MAX_PATH];
						if(RandomSound("sound_marketed", sound, sizeof(sound)))
							EmitSoundToAllExcept(sound);
					}

					ActivateAbilitySlot(boss, 7);
					HealthBarMode = true;
					CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
					return Plugin_Changed;
				}
			}
			case 525, 595:  //Diamondback, Manmelter
			{
				if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
				{
					if(GetEntProp(attacker, Prop_Send, "m_iRevengeCrits"))  //If a revenge crit was used, give a damage bonus
					{
						damage = 85.0;  //255 final damage
						return Plugin_Changed;
					}
				}
			}
			case 528:  //Short Circuit
			{
				if(circuitStun)
				{
					TF2_StunPlayer(client, circuitStun, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
					EmitSoundToAll("weapons/barret_arm_zap.wav", client);
					EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
				}
			}
			case 593:  //Third Degree
			{
				int healers[MAXTF2PLAYERS];
				int healerCount;
				for(int healer; healer<=MaxClients; healer++)
				{
					if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true)==attacker))
					{
						healers[healerCount]=healer;
						healerCount++;
					}
				}

				for(int healer; healer<healerCount; healer++)
				{
					if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
					{
						int medigun = GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
						if(IsValidEntity(medigun))
						{
							static char medigunClassname[64];
							GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
							if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
							{
								float uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healerCount);
								if(uber > 1.0)
				uber = 1.0;

								SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
							}
						}
					}
				}
			}
			case 594:  //Phlogistinator
			{
				if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
				{
					if(!TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
					{
						damage/=2.0;
						return Plugin_Changed;
					}
				}
			}
		}

		if((damagetype & DMG_CLUB) && CritBoosted[client][2]!=0 && CritBoosted[client][2]!=1 && (TF2_GetPlayerClass(attacker)!=TFClass_Spy || CritBoosted[client][2]>1))
		{
			int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
			if(CritBoosted[client][2]>1 || (melee!=416 && melee!=307 && melee!=44))
			{
				damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
				return Plugin_Changed;
			}
		}

		if(
	}
	else
	{
		char classname[64];
	}
	if(BossCharge[boss][0] > rageMax[client])
		BossCharge[boss][0] = rageMax[client];
		}
		else
		{
			if(allowedDetonations != 1)
			{
				int index = (IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && attacker<=MaxClients) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
				if(index == 307)  //Ullapool Caber
				{
					if(allowedDetonations<1 || allowedDetonations-detonations[attacker]>1)
					{
						detonations[attacker]++;
						if(allowedDetonations > 1)
							PrintHintText(attacker, "%t", "Detonations Left", allowedDetonations-detonations[attacker]);
	
						SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
						SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
					}
				}
			}

			if(IsValidClient(client, false) && TF2_GetPlayerClass(client)==TFClass_Soldier)  //TODO: LOOK AT THIS
			{
				if(damagetype & DMG_FALL)
				{
					int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(secondary<1 || !IsValidEntity(secondary))
					{
						damage /= 10.0;
						return Plugin_Changed;
					}
				}
			}

			if(Enabled3 && cvarBvBMerc.FloatValue!=1 && RedAliveBosses && BlueAliveBosses)
			{
				if(IsValidClient(client) && IsValidClient(attacker) && GetClientTeam(attacker)!=GetClientTeam(client))
				{
					damage *= cvarBvBMerc.FloatValue;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}
