/*
	Requirement:
*/

#define FF2_NATIVES

void Native_Setup()
{
	// Official Natives
	CreateNative("FF2_IsFF2Enabled", Native_IsEnabled);
	CreateNative("FF2_GetFF2Version", Native_FF2Version);
	CreateNative("FF2_GetBossUserId", Native_GetBoss);
	CreateNative("FF2_GetBossIndex", Native_GetIndex);
	CreateNative("FF2_GetBossTeam", Native_GetTeam);
	CreateNative("FF2_GetBossSpecial", Native_GetSpecial);
	CreateNative("FF2_GetBossHealth", Native_GetBossHealth);
	CreateNative("FF2_SetBossHealth", Native_SetBossHealth);
	CreateNative("FF2_GetBossMaxHealth", Native_GetBossMaxHealth);
	CreateNative("FF2_SetBossMaxHealth", Native_SetBossMaxHealth);
	CreateNative("FF2_GetBossLives", Native_GetBossLives);
	CreateNative("FF2_SetBossLives", Native_SetBossLives);
	CreateNative("FF2_GetBossMaxLives", Native_GetBossMaxLives);
	CreateNative("FF2_SetBossMaxLives", Native_SetBossMaxLives);
	CreateNative("FF2_GetBossCharge", Native_GetBossCharge);
	CreateNative("FF2_SetBossCharge", Native_SetBossCharge);
	CreateNative("FF2_GetBossRageDamage", Native_GetBossRageDamage);
	CreateNative("FF2_SetBossRageDamage", Native_SetBossRageDamage);
	CreateNative("FF2_GetClientDamage", Native_GetDamage);
	CreateNative("FF2_GetRoundState", Native_GetRoundState);
	CreateNative("FF2_GetSpecialKV", Native_GetSpecialKV);
	CreateNative("FF2_StartMusic", Native_StartMusic);
	CreateNative("FF2_StopMusic", Native_StopMusic);
	CreateNative("FF2_GetRageDist", Native_GetRageDist);
	CreateNative("FF2_HasAbility", Native_HasAbility);
	CreateNative("FF2_DoAbility", Native_DoAbility);
	CreateNative("FF2_GetAbilityArgument", Native_GetAbilityArgument);
	CreateNative("FF2_GetAbilityArgumentFloat", Native_GetAbilityArgumentFloat);
	CreateNative("FF2_GetAbilityArgumentString", Native_GetAbilityArgumentString);
	CreateNative("FF2_GetArgNamedI", Native_GetArgNamedI);
	CreateNative("FF2_GetArgNamedF", Native_GetArgNamedF);
	CreateNative("FF2_GetArgNamedS", Native_GetArgNamedS);
	CreateNative("FF2_RandomSound", Native_RandomSound);
	CreateNative("FF2_GetFF2flags", Native_GetFF2flags);
	CreateNative("FF2_SetFF2flags", Native_SetFF2flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_GetClientGlow", Native_GetClientGlow);
	CreateNative("FF2_SetClientGlow", Native_SetClientGlow);

	// Unofficial Natives
	CreateNative("FF2_IsBossVsBoss", Native_IsVersus);
	CreateNative("FF2_GetForkVersion", Native_ForkVersion);
	CreateNative("FF2_GetBossName", Native_GetName);
	CreateNative("FF2_EmitVoiceToAll", Native_EmitVoiceToAll);
	CreateNative("FF2_GetClientShield", Native_GetClientShield);
	CreateNative("FF2_SetClientShield", Native_SetClientShield);
	CreateNative("FF2_RemoveClientShield", Native_RemoveClientShield);
	CreateNative("FF2_LogError", Native_LogError);
	CreateNative("FF2_Debug", Native_Debug);
	CreateNative("FF2_SetCheats", Native_SetCheats);
	CreateNative("FF2_GetCheats", Native_GetCheats);
	CreateNative("FF2_MakeBoss", Native_MakeBoss);
	CreateNative("FF2_SelectBoss", Native_ChooseBoss);
}

public any Native_IsEnabled(Handle plugin, int numParams)
{
	return Enabled>Game_Disabled;
}

public any Native_FF2Version(Handle plugin, int numParams)
{
	static int ver[3];
	if(!ver[0])
	{
		ver[0] = StringToInt(MAJOR_REVISION);
		ver[1] = StringToInt(MINOR_REVISION);
		ver[2] = StringToInt(STABLE_REVISION);
	}
	SetNativeArray(1, ver, sizeof(ver));
	#if defined DEV_REVISION
	return true;
	#else
	return false;
	#endif
}

public any Native_IsVersus(Handle plugin, int numParams)
{
	return false;
}

public any Native_ForkVersion(Handle plugin, int numParams)
{
	static int ver[3];
	if(!ver[0])
	{
		ver[0] = StringToInt(FORK_MAJOR_REVISION);
		ver[1] = StringToInt(FORK_MINOR_REVISION);
		ver[2] = StringToInt(FORK_STABLE_REVISION);
	}
	SetNativeArray(1, ver, sizeof(ver));
	#if defined FORK_DEV_REVISION
	return true;
	#else
	return false;
	#endif
}

public any Native_GetBoss(Handle plugin, int numParams)
{
	int boss = GetNativeCell(1);
	if(!boss)
	{
		boss = GetZeroBoss();
		if(IsValidClient(boss))
			return GetClientUserId(boss);
	}
	else if(IsValidClient(boss) && Boss[boss].Active)
	{
		return GetClientUserId(boss);
	}
	return -1;
}

public any Native_GetIndex(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 && client>=MAXTF2PLAYERS)
		return -1;

	return Boss[client].Active ? Boss[client].Leader ? 0 : client : -1;
}

public any Native_GetTeam(Handle plugin, int numParams)
{
	int client = GetZeroBoss();
	return client==-1 ? view_as<int>(TFTeam_Blue) : view_as<int>(Client[client].Team);
}

public any Native_GetSpecial(Handle plugin, int numParams)
{
	int index = GetNativeCell(1);
	if(index < 0)
		return false;

	int length = GetNativeCell(3);
	char[] buffer = new char[length];
	if(GetNativeCell(4))
	{
		if(index >= Specials)
			return false;
	}
	else
	{
		if(!index)
		{
			index = GetZeroBoss();
			if(index == -1)
				return false;
		}
		else if(index>=MAXTF2PLAYERS || !Boss[index].Active)
		{
			return false;
		}

		index = Boss[index].Special;
	}

	Special[index].Kv.Rewind();
	Special[index].Kv.GetString("name", buffer, length);
	SetNativeString(2, buffer, length);
	return true;
}

public any Native_GetName(Handle plugin, int numParams)
{
	int index = GetNativeCell(1);
	if(index < 0)
		return false;

	int length = GetNativeCell(3);
	char[] buffer = new char[length];
	if(GetNativeCell(4))
	{
		if(index >= Specials)
			return false;
	}
	else
	{
		if(!index)
		{
			index = GetZeroBoss();
			if(index == -1)
				return false;
		}
		else if(index>=MAXTF2PLAYERS || !Boss[index].Active)
		{
			return false;
		}

		index = Boss[index].Special;
	}

	Special[index].Kv.Rewind();
	KvGetLang(Special[index].Kv, "name", buffer, length, GetNativeCell(5));
	SetNativeString(2, buffer, length);
	return true;
}

public any Native_GetBossHealth(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(!IsValidClient(client))
		return 0;

	return Boss[client].Health(client);
}

public any Native_SetBossHealth(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return;

	int health = GetNativeCell(2);
	if(health < 1)
	{
		if(IsValidClient(client))
			ForcePlayerSuicide(client);

		return;
	}

	int newHealth = health;
	int extra = Boss[client].MaxHealth*(Boss[client].Lives-1);
	while(health > extra)
	{
		newHealth -= Boss[client].MaxHealth;
		extra -= Boss[client].MaxHealth;
		Boss[client].Lives--;
	}

	if(IsValidClient(client))
		SetEntityHealth(client, newHealth-(Boss[client].MaxHealth*(Boss[client].Lives-1)));
}

public any Native_GetBossMaxHealth(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return 0;

	return Boss[client].MaxHealth;
}

public any Native_SetBossMaxHealth(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return;

	Boss[client].MaxHealth = GetNativeCell(2);
}

public any Native_GetBossLives(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return 0;

	return Boss[client].Lives;
}

public any Native_SetBossLives(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return;

	Boss[client].Lives = GetNativeCell(2);
}

public any Native_GetBossMaxLives(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return 0;

	return Boss[client].MaxLives;
}

public any Native_SetBossMaxLives(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return;

	Boss[client].MaxLives = GetNativeCell(2);
}

public any Native_GetBossCharge(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return 0;

	int charge = GetNativeCell(2);
	if(charge<0 || charge>3)
		return 0;

	return Boss[client].Charge[charge];
}

public any Native_SetBossCharge(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return;

	int charge = GetNativeCell(2);
	if(charge>=0 && charge<4)
		Boss[client].Charge[charge] = GetNativeCell(3);
}

public any Native_GetBossRageDamage(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return 0;

	return Boss[client].RageDamage;
}

public any Native_SetBossRageDamage(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return;

	Boss[client].RageDamage = GetNativeCell(2);
}

public any Native_GetRoundState(Handle plugin, int numParams)
{
	int state = CheckRoundState();
	return state<1 ? 0 : state;
}

public any Native_GetRageDist(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return 0.0;

	static char ability[64];
	GetNativeString(3, ability, sizeof(ability));
	if(ability[0])
	{
		char name[64];
		for(int i=1; i<=MAXRANDOMS; i++)
		{
			FormatEx(name, sizeof(name), "ability%i", i);
			if(!Special[Boss[client].Special].Kv.JumpToKey(name))
				continue;

			Special[Boss[client].Special].Kv.GetString("name", name, sizeof(name));
			if(!StrEqual(ability, name))
			{
				Special[Boss[client].Special].Kv.GoBack();
				continue;
			}

			float see = Special[Boss[client].Special].Kv.GetFloat("dist", -1.0);
			if(see < 0)
				break;

			return see;
		}
	}

	Special[Boss[client].Special].Kv.Rewind();
	return Special[Boss[client].Special].Kv.GetFloat("ragedist", 400.0);
}

public any Native_HasAbility(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client == -1)
		return false;

	static char plugin[64], ability[64];
	GetNativeString(2, plugin, sizeof(plugin));
	GetNativeString(3, ability, sizeof(ability));

	Special[Boss[client].Special].Kv.Rewind();
	Special[Boss[client].Special].Kv.GotoFirstSubKey();
	do
	{
		static char name[64];
		if(KvGetSectionType(Special[Boss[client].Special].Kv, name, sizeof(name)) != Section_Ability)
			continue;

		if(!StrContains(name, "ability"))
			Special[Boss[client].Special].Kv.GetString("name", name, sizeof(name));

		if(!StrEqual(ability, name))
			continue;

		if(!plugin[0])
			return true;

		Special[Boss[client].Special].Kv.GetString("plugin_name", name, sizeof(name));
		if(!name[0] || StrEqual(plugin, name))
			return true;
	} while(Special[Boss[client].Special].Kv.GotoNextKey());
	return false;
}

public any Native_DoAbility(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	UseAbility(ability_name, plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

public any Native_GetAbilityArgument(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	return GetAbilityArgument(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5));
}

public any Native_GetAbilityArgumentFloat(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	return GetAbilityArgumentFloat(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5));
}

public any Native_GetAbilityArgumentString(Handle plugin, int numParams)
{
	static char plugin_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	static char ability_name[64];
	GetNativeString(3, ability_name, sizeof(ability_name));
	int dstrlen = GetNativeCell(6);
	char[] s = new char[dstrlen+1];
	GetAbilityArgumentString(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), s, dstrlen);
	SetNativeString(5, s, dstrlen);
}

public any Native_GetArgNamedI(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	return GetArgumentI(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5));
}

public any Native_GetArgNamedF(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	return GetArgumentF(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5));
}

public any Native_GetArgNamedS(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	int dstrlen = GetNativeCell(6);
	char[] s = new char[dstrlen+1];
	GetArgumentS(GetNativeCell(1), plugin_name, ability_name, argument, s, dstrlen);
	SetNativeString(5, s, dstrlen);
}

public any Native_GetDamage(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return 0;

	return Client[client].Damage;
}

public any Native_GetFF2flags(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return 0;

	int flags = FF2FLAG_CLASSHELPED|FF2FLAG_HASONGIVED;
	if(Client[client].Minion)
	{
		flags |= FF2FLAG_CLASSTIMERDISABLED|FF2FLAG_ALLOWSPAWNINBOSSTEAM;
	}
	else if(Boss[client].Active)
	{
		if(IsFakeClient(client) && Boss[client].Charge[0]>=Boss[client].RageMin)
			flags |= FF2FLAG_BOTRAGE;

		if(Boss[client].HealthKits)
			flags |= FF2FLAG_ALLOW_HEALTH_PICKUPS;

		if(Boss[client].AmmoKits)
			flags |= FF2FLAG_ALLOW_AMMO_PICKUPS;

		if(Boss[client].Cosmetics)
			flags |= FF2FLAG_ALLOW_BOSS_WEARABLES;
	}
	else
	{
		static char buffer[64];
		int i = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(i) && GetEntityClassname(i, buffer, sizeof(buffer)) && !StrContains(buffer, "tf_weapon_medigun", false) && GetEntPropFloat(i, Prop_Send, "m_flChargeLevel")==1)
			flags |= FF2FLAG_UBERREADY;

		if(TF2_IsPlayerInCondition(client, TFCond_BlastJumping))
			flags |= FF2FLAG_ROCKET_JUMPING;

		flags |= FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS|FF2FLAG_ALLOW_BOSS_WEARABLES;
	}

	if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
		flags |= FF2FLAG_ISBUFFED;

	if(Client[client].DisableHud)
		flags |= FF2FLAG_HUDDISABLED;

	return flags;
}

public any Native_SetFF2flags(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return;

	int flags = GetNativeCell(2);
	if(Boss[client].Active)
	{
		Boss[client].HealthKits = (flags & FF2FLAG_ALLOW_HEALTH_PICKUPS);
		Boss[client].AmmoKits = (flags & FF2FLAG_ALLOW_AMMO_PICKUPS);
		Boss[client].Cosmetics = (flags & FF2FLAG_ALLOW_BOSS_WEARABLES);
	}
	else
	{
		if(flags & FF2FLAG_ALLOWSPAWNINBOSSTEAM)
		{
			Client[client].Minion = true;
		}
		else if(!(flags & FF2FLAG_CLASSTIMERDISABLED) && !(flags & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
		{
			Client[client].Minion = false;
		}

		if(IsValidClient(client))
		{
			if(flags & FF2FLAG_ROCKET_JUMPING)
			{
				if(!TF2_IsPlayerInCondition(client, TFCond_BlastJumping))
					TF2_AddCondition(client, TFCond_BlastJumping, _, client);
			}
			else if(TF2_IsPlayerInCondition(client, TFCond_BlastJumping))
			{
				TF2_RemoveCondition(client, TFCond_BlastJumping);
			}
		}
	}

	Client[client].DisableHud = (flags & FF2FLAG_HUDDISABLED);
}

public any Native_GetQueuePoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return 0;

	return Client[client].Queue;
}

public any Native_SetQueuePoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client>=0 && client<MAXTF2PLAYERS)
		Client[client].Queue = GetNativeCell(1);
}

public any Native_GetSpecialKV(Handle plugin, int numParams)
{
	int index = GetNativeCell(1);
	if(index < 0)
		return INVALID_HANDLE;

	if(GetNativeCell(2))
	{
		if(index >= MAXSPECIALS)
			return INVALID_HANDLE;
	}
	else
	{
		if(!index)
		{
			index = GetZeroBoss();
			if(index < 1)
				return INVALID_HANDLE;
		}
		else if(index>=MAXTF2PLAYERS || !Boss[index].Active)
		{
			return INVALID_HANDLE;
		}

		index = Boss[index].Special;
	}

	return view_as<Handle>(Special[index].Kv);
}

public any Native_StartMusic(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client))
		Music_Play(client, GetEngineTime(), -1);
}

public any Native_StopMusic(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client))
		Music_Stop(client);
}

public any Native_RandomSound(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(4));
	if(client == -1)
		return false;

	int length = GetNativeCell(3)+1;
	char[] sound = new char[length];

	int kvLength;
	GetNativeStringLength(1, kvLength);

	char[] keyvalue = new char[++kvLength];
	GetNativeString(1, keyvalue, kvLength);

	bool soundExists;
	if(!StrContains(keyvalue, "sound_ability", false))
	{
		int slot = GetNativeCell(5);
		soundExists = RandomSoundAbility(keyvalue, sound, length, boss, slot);
	}
	else
	{
		soundExists = RandomSound(keyvalue, sound, length, boss);
	}
	SetNativeString(2, sound, length);
	return soundExists;
}

public any Native_EmitVoiceToAll(Handle plugin, int numParams)
{
	int kvLength;
	GetNativeStringLength(1, kvLength);
	kvLength++;
	char[] keyvalue = new char[kvLength];
	GetNativeString(1, keyvalue, kvLength);

	float origin[3], dir[3];
	GetNativeArray(9, origin, 3);
	GetNativeArray(10, dir, 3);

	EmitSoundToAllExcept(keyvalue, GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8), origin, dir, GetNativeCell(11), GetNativeCell(12));
}

public any Native_GetClientGlow(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return -1.0;

	float time = Client[client].GlowFor-GetGameTime();
	return time>0 ? time : 0.0;
}

public any Native_SetClientGlow(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return;

	float time = GetNativeCell(3);
	if(time >= 0)
	{	
		Client[client].GlowFor = time+GetGameTime();
		return;
	}

	time = GetNativeCell(2);
	float gameTime = GetGameTime();
	Client[client].GlowFor = Client[client].GlowFor>gameTime ? Client[client].GlowFor+time : gameTime+time);
}

public any Native_GetClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return -1;

	for(int i; i<3; i++)
	{
		if(Weapon[client][i].Shield)
			return 100;
	}
	return -1;
}

public any Native_SetClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return;

	any value = GetNativeCell(3);
	if(!value || (value<0 && !Weapon[client][1].Shield))
		return;

	value = GetNativeCell(2);
	if(value > 0)
		Weapon[client][1].Shield = view_as<int>(value);
}

public any Native_RemoveClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return;

	for(int i; i<3; i++)
	{
		if(!Weapon[client][i].Shield)
			continue;

		RemoveShield(client, 0, Weapon[client][i].Shield);
		Weapon[client][i].Shield = 0;
	}
}

public any Native_LogError(Handle plugin, int numParams)
{
	char buffer[256];
	int error = FormatNativeString(0, 1, 2, sizeof(buffer), _, buffer);
	if(error != SP_ERROR_NONE)
	{
		ThrowNativeError(error, "FormatNativeString Failed");
		return;
	}
	LogError2(buffer);
}

public any Native_Debug(Handle plugin, int numParams)
{
	return CvarDebug.BoolValue;
}

public any Native_SetCheats(Handle plugin, int numParams)
{
	#if defined FF2_STATTRAK
	StatEnabled = GetNativeCell(1);
	#endif
}

public any Native_GetCheats(Handle plugin, int numParams)
{
	#if defined FF2_STATTRAK
	return StatEnabled;
	#else
	return false;
	#endif
}

public any Native_MakeBoss(Handle plugin, int numParams)
{
	/*int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return;

	int boss = GetNativeCell(2);
	if(boss == -1)
	{
		boss = GetBossIndex(client);
		if(boss < 0)
			return;

		Boss[boss] = 0;
		BossSwitched[boss] = false;
		CreateTimer(0.1, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	int special = GetNativeCell(3);
	if(special >= 0)
		Incoming[boss] = special;

	Boss[boss] = client;
	HasEquipped[boss] = false;
	BossSwitched[boss] = GetNativeCell(4);
	PickCharacter(boss, boss);
	CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);*/
}

public any Native_ChooseBoss(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return false;

	static char buffer[64];
	GetNativeString(2, buffer, sizeof(buffer));

	for(int i; i<Specials; i++)
	{
		if(Special[i].Charset != Charset)
			continue;

		static char buffer2[64];
		Special[i].Kv.GetString(buffer2, sizeof(buffer2));
		if(!StrEqual(buffer, buffer2))
			continue;

		Client[client].Selection = i;
		return KvGetBossAccess(Special[i].Kv, client)>=0;
	}
	Client[client].Selection = -1;
	return false;
}

static int BossToClient(int boss)
{
	if(!boss)
		return GetZeroBoss();

	if(boss>0 && boss<MAXTF2PLAYERS)
		return boss;

	return -1;
}