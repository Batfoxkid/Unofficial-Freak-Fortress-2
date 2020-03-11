/*
	Requirement:
*/

#define FF2_NATIVES

public int Native_IsEnabled(Handle plugin, int numParams)
{
	return Enabled;
}

public int Native_FF2Version(Handle plugin, int numParams)
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

public int Native_IsVersus(Handle plugin, int numParams)
{
	return false;
}

public int Native_ForkVersion(Handle plugin, int numParams)
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

public int Native_GetBoss(Handle plugin, int numParams)
{
	int boss = GetNativeCell(1);
	if(!boss)
	{
		boss = GetZeroBoss();
		return boss==-1 ? -1 : GetClientUserId(boss);
	}
	else if(boss>0 && boss<MAXTF2PLAYERS && Boss[boss].Active)
	{
		return GetClientUserId(boss);
	}
	return -1;
}

public int Native_GetIndex(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 && client>=MAXTF2PLAYERS)
		return -1;

	return Boss[client].Active ? -1 : Boss[client].Leader ? 0 : client;
}

public int Native_GetTeam(Handle plugin, int numParams)
{
	int client = GetZeroBoss();
	return client<1 ? view_as<int>(TFTeam_Blue) : view_as<int>(Client[client].Team);
}

public int Native_GetSpecial(Handle plugin, int numParams)
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
			if(index < 1)
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

public int Native_GetName(Handle plugin, int numParams)
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
			if(index < 1)
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

public int Native_GetBossHealth(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return 0;

	return Boss[client].Health(client);
}

public int Native_SetBossHealth(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return;

	int health = GetNativeCell(2);
	if(health < 1)
	{
		ForcePlayerSuicide(client);
		return;
	}

	int newHealth = health;
	int extra = Client[client].MaxHealth*(Client[client].Lives-1);
	while(health > extra)
	{
		newHealth -= Client[client].MaxHealth;
		extra -= Client[client].MaxHealth;
		Client[client].Lives--;
	}

	SetEntityHealth(client, newHealth-(Client[client].MaxHealth*(Client[client].Lives-1)));
}

public int Native_GetBossMaxHealth(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return 0;

	return Boss[client].MaxHealth;
}

public int Native_SetBossMaxHealth(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return;

	Boss[client].MaxHealth = GetNativeCell(2);
}

public int Native_GetBossLives(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return 0;

	return Boss[client].Lives;
}

public int Native_SetBossLives(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return;

	Boss[client].Lives = GetNativeCell(2);
}

public int Native_GetBossMaxLives(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return 0;

	return Boss[client].MaxLives;
}

public int Native_SetBossMaxLives(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return;

	Boss[client].MaxLives = GetNativeCell(2);
}

public int Native_GetBossCharge(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return 0;

	int charge = GetNativeCell(2);
	if(charge<0 || charge>3)
		return 0;

	return Boss[client].Charge[charge];
}

public int Native_SetBossCharge(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return;

	int charge = GetNativeCell(2);
	if(charge>=0 && charge<4)
		Boss[client].Charge[charge] = GetNativeCell(3);
}

public int Native_GetBossRageDamage(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return 0;

	return Boss[client].RageDamage;
}

public int Native_SetBossRageDamage(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return;

	Boss[client].RageDamage = GetNativeCell(2);
}

public int Native_GetRoundState(Handle plugin, int numParams)
{
	int state = CheckRoundState();
	return state<1 ? 0 : state;
}

public int Native_GetRageDist(Handle plugin, int numParams)
{
	int client = BossToClient(GetNativeCell(1));
	if(client < 1)
		return view_as<int>(0.0);

	static char ability[64];
	GetNativeString(3, ability, sizeof(ability));
	if(ability[0])
	{
		static char plugin[64];
		GetNativeString(2, plugin, sizeof(plugin));

		char s[10];
		for(int i=1; i<=MAXRANDOMS; i++)
		{
			FormatEx(s, sizeof(s), "ability%i", i);
			if(Special[Boss[client].Special].Kv.JumpToKey(s))
			{
				static char ability2[64];
				Special[Boss[client].Special].Kv.GetString("name", ability2, sizeof(ability2));
				if(!StrEqual(ability, ability2))
				{
					Special[Boss[client].Special].Kv.GoBack();
					continue;
				}

				float see = Special[Boss[client].Special].Kv.GetFloat("dist", -1.0);
				if(see >= 0)
					return view_as<int>(see);

				break;
			}
		}
	}

	Special[Boss[client].Special].Kv.Rewind();
	return view_as<int>(Special[Boss[client].Special].Kv.GetFloat("ragedist", 400.0));
}

public int Native_HasAbility(Handle plugin, int numParams)
{
	static char pluginName[64], abilityName[64];

	int boss = GetNativeCell(1);
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	if(boss==-1 || boss>=MAXTF2PLAYERS || Special[boss]==-1 || !BossKV[Special[boss]])
		return false;

	KvRewind(BossKV[Special[boss]]);
	if(!BossKV[Special[boss]])
	{
		LogToFile(eLog, "[Boss] Failed KV: %i %i", boss, Special[boss]);
		return false;
	}

	char ability[12];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		FormatEx(ability, sizeof(ability), "ability%i", i);
		if(KvJumpToKey(BossKV[Special[boss]], ability))  //Does this ability number exist?
		{
			static char abilityName2[64];
			KvGetString(BossKV[Special[boss]], "name", abilityName2, sizeof(abilityName2));
			if(StrEqual(abilityName, abilityName2))  //Make sure the ability names are equal
			{
				static char pluginName2[64];
				KvGetString(BossKV[Special[boss]], "plugin_name", pluginName2, sizeof(pluginName2));
				if(!pluginName[0] || !pluginName2[0] || StrEqual(pluginName, pluginName2))  //Make sure the plugin names are equal
					return true;
			}
			KvGoBack(BossKV[Special[boss]]);
		}
	}
	return false;
}

public int Native_DoAbility(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	UseAbility(ability_name, plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

public int Native_GetAbilityArgument(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	return GetAbilityArgument(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5));
}

public int Native_GetAbilityArgumentFloat(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	return view_as<int>(GetAbilityArgumentFloat(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5)));
}

public int Native_GetAbilityArgumentString(Handle plugin, int numParams)
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

public int Native_GetArgNamedI(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	return GetArgumentI(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5));
}

public int Native_GetArgNamedF(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	return view_as<int>(GetArgumentF(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5)));
}

public int Native_GetArgNamedS(Handle plugin, int numParams)
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

public int Native_GetDamage(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return 0;

	return Damage[client];
}

public int Native_GetFF2flags(Handle plugin, int numParams)
{
	return FF2flags[GetNativeCell(1)];
}

public int Native_SetFF2flags(Handle plugin, int numParams)
{
	FF2flags[GetNativeCell(1)] = GetNativeCell(2);
}

public int Native_GetQueuePoints(Handle plugin, int numParams)
{
	return QueuePoints[GetNativeCell(1)];
}

public int Native_SetQueuePoints(Handle plugin, int numParams)
{
	QueuePoints[GetNativeCell(1)] = GetNativeCell(2);
}

public int Native_GetSpecialKV(Handle plugin, int numParams)
{
	int index = GetNativeCell(1);
	bool isNumOfSpecial = view_as<bool>(GetNativeCell(2));
	if(isNumOfSpecial)
	{
		if(index!=-1 && index<Specials)
		{
			if(BossKV[index] != INVALID_HANDLE)
				KvRewind(BossKV[index]);

			return view_as<int>(BossKV[index]);
		}
	}
	else
	{
		if(index!=-1 && index<=MaxClients && Special[index]!=-1 && Special[index]<MAXSPECIALS)
		{
			if(BossKV[Special[index]] != INVALID_HANDLE)
				KvRewind(BossKV[Special[index]]);

			return view_as<int>(BossKV[Special[index]]);
		}
	}
	return view_as<int>(INVALID_HANDLE);
}

public int Native_StartMusic(Handle plugin, int numParams)
{
	StartMusic(GetNativeCell(1));
}

public int Native_StopMusic(Handle plugin, int numParams)
{
	StopMusic(GetNativeCell(1));
}

public int Native_RandomSound(Handle plugin, int numParams)
{
	int length = GetNativeCell(3)+1;
	int boss = GetNativeCell(4);
	int slot = GetNativeCell(5);
	char[] sound = new char[length];
	int kvLength;

	GetNativeStringLength(1, kvLength);
	kvLength++;

	char[] keyvalue = new char[kvLength];
	GetNativeString(1, keyvalue, kvLength);

	bool soundExists;
	if(!StrContains(keyvalue, "sound_ability", false))
	{
		soundExists = RandomSoundAbility(keyvalue, sound, length, boss, slot);
	}
	else
	{
		soundExists = RandomSound(keyvalue, sound, length, boss);
	}
	SetNativeString(2, sound, length);
	return soundExists;
}

public int Native_EmitVoiceToAll(Handle plugin, int numParams)
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

public int Native_GetClientGlow(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client))
	{
		return view_as<int>(GlowTimer[client]);
	}
	else
	{
		return view_as<int>(-1.0);
	}
}

public int Native_SetClientGlow(Handle plugin, int numParams)
{
	SetClientGlow(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public int Native_GetClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client) && hadshield[client])
	{
		if(shield[client])
		{
			if(cvarShieldType.IntValue > 2)
			{
				return RoundToFloor(shieldHP[client]/cvarShieldHealth.FloatValue*100.0);
			}
			else
			{
				return 100;
			}
		}
		return 0;
	}
	return -1;
}

public int Native_SetClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client))
	{
		if(GetNativeCell(2) > 0)
			shield[client] = GetNativeCell(2);

		if(GetNativeCell(3) >= 0)
			shieldHP[client] = GetNativeCell(3)*cvarShieldHealth.FloatValue/100.0;

		if(GetNativeCell(4) > 0)
		{
			shDmgReduction[client] = (1.0-GetNativeCell(4));
		}
		else if(GetNativeCell(3) > 0)
		{
			shDmgReduction[client] = shieldHP[client]/cvarShieldHealth.FloatValue*(1.0-cvarShieldResist.FloatValue);
		}
	}
}

public int Native_RemoveClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client))
	{
		TF2_RemoveWearable(client, shield[client]);
		shieldHP[client] = 0.0;
		shield[client] = 0;
	}
}

public int Native_LogError(Handle plugin, int numParams)
{
	char buffer[256];
	int error = FormatNativeString(0, 1, 2, sizeof(buffer), _, buffer);
	if(error != SP_ERROR_NONE)
	{
		ThrowNativeError(error, "Failed to format");
		return;
	}
	LogToFile(eLog, buffer);
}

public int Native_Debug(Handle plugin, int numParams)
{
	return cvarDebug.BoolValue;
}

public int Native_SetCheats(Handle plugin, int numParams)
{
	CheatsUsed = GetNativeCell(1);
}

public int Native_GetCheats(Handle plugin, int numParams)
{
	return (CheatsUsed || SpecialRound);
}

public int Native_MakeBoss(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
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
	CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
}

public int Native_ChooseBoss(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<1 || client>=MAXTF2PLAYERS)
	{
		GetNativeString(2, xIncoming[0], sizeof(xIncoming[]));
		return CheckValidBoss(0, xIncoming[0]);
	}

	GetNativeString(2, xIncoming[client], sizeof(xIncoming[]));
	IgnoreValid[client] = GetNativeCell(3);
	return CheckValidBoss(client, xIncoming[client]);
}

static int BossToClient(int boss)
{
	if(!boss)
		return GetZeroBoss();

	if(boss>0 && boss<MAXTF2PLAYERS)
		return boss;

	return -1;
}

static int GetZeroBoss()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(Boss[client].Active && Boss[client].Leader)
			return client;
	}
}
