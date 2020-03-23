/*
	Functions:
	bool IsValidClient(int client, bool replaycheck=true)
	int OnlyScoutsLeft(int team)
	int GetIndexOfWeaponSlot(int client, int slot)
	bool RemoveCond(int client, TFCond cond)
	int GetClientCloakIndex(int client)
	void SpawnSmallHealthPackAt(int client, int team=0, int attacker)
	void IncrementHeadCount(int client)
	void HealMessage(int patient, int healer, int amount)
	int FindTeleOwner(int client)
	bool IsPlayerCritBuffed(int client)
	bool IsPlayerMiniCritBuffed(int client)
	void RandomlyDisguise(int client)
	void AssignTeam(int client, int team)
	TFClassType KvGetClass(Handle kv, const char[] string)
	SectionType KvGetSectionType(Handle kv, char[] buffer, int length)
	int KvGetBossAccess(Handle kv, int client, bool force=false)
	bool KvGetBossAccess2(Handle kv, int client, char[] buffer, int length)
	void KvGetLang(Handle kv, const char[] key, char[] buffer, int length, int client=0, const char[] defaul="=Failed name=")
	bool ConfigureWorldModelOverride(int entity, const char[] model, bool wearable=false)
	void MultiClassname(TFClassType class, char[] name, int length)
	int GetHealingTarget(int client, bool checkgun=false)
	void LogError2(const char[] buffer, any ...)
	int GetRandBlockCell(ArrayList array, int &index, int block=0, bool byte=false, int defaul=0)
	int GetRandBlockCellEx(ArrayList array, int block=0, bool byte=false, int defaul=0)
*/

#define FF2_STOCKS

static const TFCond CritConditions[] =
{
	TFCond_Kritzkrieged,
	TFCond_HalloweenCritCandy,
	TFCond_CritCanteen,
	TFCond_CritOnFirstBlood,
	TFCond_CritOnWin,
	TFCond_CritOnFlagCapture,
	TFCond_CritOnKill,
	TFCond_CritMmmph,
	TFCond_CritOnDamage,
	TFCond_CritRuneTemp
};

static const TFCond MiniCritConditions[] =
{
	TFCond_Buffed,
	TFCond_CritCola,
	TFCond_NoHealingDamageBuff,
	TFCond_MiniCritOnKill
};

enum SectionType
{
	Section_Unknown = 0,
	Section_Ability,	// ability | Ability Name
	Section_Map,		// map_
	Section_Weapon,		// tf_ | saxxy
	Section_Sound,		// sound_ | catch_
	Section_Download,	// download
	Section_Model,		// mod_download
	Section_Material,	// mat_download
	Section_Precache	// mod_precache
};

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<1 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}

stock int OnlyScoutsLeft(int team)
{
	int scouts;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client)==team)
			continue;

		if(!Boss[client].Active && TF2_GetPlayerClass(client)!=TFClass_Scout)
			return 0;

		scouts++;
	}
	return scouts;
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon)) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
}

stock bool RemoveCond(int client, TFCond cond)
{
	if(!TF2_IsPlayerInCondition(client, cond))
		return false;

	TF2_RemoveCondition(client, cond);
	return true;	
}

stock int GetClientCloakIndex(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 4);
	if(!IsValidEntity(weapon))
		return -1;

	static char classname[8];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if(!StrContains(classname, "tf_wea", false))
		return -1;

	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

stock void SpawnSmallHealthPackAt(int client, int team=0, int attacker)
{
	if(Weapon[attacker][2].Stale > 14)
		return;

	int entity = CreateEntityByName(Weapon[attacker][2].Stale ? "item_healthkit_small" : "item_healthkit_medium");
	if(!IsValidEntity(entity))
		return;

	DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Send, "m_iTeamNum", team, 4);
	SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	static float velocity[3] = {0.0, 0.0, 50.0};
	velocity[0] = float(GetRandomInt(-10, 10));
	velocity[1] = float(GetRandomInt(-10, 10));

	static float position[3];
	GetClientAbsOrigin(client, position);
	position[2] += 20.0;
	TeleportEntity(entity, position, NULL_VECTOR, velocity);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", attacker);
}

stock void IncrementHeadCount(int client, int amount)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);

	SetEntProp(client, Prop_Send, "m_iDecapitations", GetEntProp(client, Prop_Send, "m_iDecapitations")+1);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);

	int health = GetClientHealth(client);
	int max = GetEntProp(client, Prop_Data, "m_iMaxHealth")*2;
	if(health >= max)
		return;

	int add = amount-Weapon[client][2].Stale;
	if(add < 5)
		add = 5;

	if(health+add > max)
		add = max-health;

	SetEntityHealth(client, health);
	HealMessage(client, client, add);
}

stock void HealMessage(int patient, int healer, int amount)
{
	Event event = CreateEvent("player_healed", true);
	event.SetInt("patient", patient);
	event.SetInt("healer", healer);
	event.SetInt("amount", amount);
	event.FireToClient(patient);
	event.Cancel();
}

stock int FindTeleOwner(int client)
{
	int entity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	if(!IsValidEntity(entity))
		return -1;

	static char classname[32];
	if(!GetEntityClassname(entity, classname, sizeof(classname)) || !StrEqual(classname, "obj_teleporter", false))
		return -1;

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	return IsValidClient(owner, false) ? owner : -1;
}

stock bool IsPlayerCritBuffed(int client)
{
	for(int i; i<sizeof(CritConditions); i++)
	{
		if(TF2_IsPlayerInCondition(client, CritConditions[i]))
			return true;
	}
	return false;
}

stock bool IsPlayerMiniCritBuffed(int client)
{
	for(int i; i<sizeof(MiniCritConditions); i++)
	{
		if(TF2_IsPlayerInCondition(client, MiniCritConditions[i]))
			return true;
	}
	return false;
}

public Action Timer_DisguiseBackstab(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
		RandomlyDisguise(client);

	return Plugin_Continue;
}

stock void RandomlyDisguise(int client)
{
	int target = client;
	int team = GetClientTeam(client);

	ArrayList list = new ArrayList();
	for(int victim=1; victim<=MaxClients; victim++)
	{
		if(victim!=client && IsValidClient(victim) && GetClientTeam(victim)==team)
			list.Push(victim);
	}

	if(list.Length > 0)
	{
		int victim = list.Get(GetRandomInt(0, list.Length-1));
		if(!IsValidClient(victim))
			target = victim;
	}
	delete list;

	TFClassType class = TF2_GetPlayerClass(target);
	if(class == TFClass_Unknown)
		class = GetRandomInt(0, 1) ? TFClass_Medic : TFClass_Scout;

	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		TF2_DisguisePlayer(client, view_as<TFTeam>(team), class, target);
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 320.0);
	}
	else
	{
		TF2_AddCondition(client, TFCond_Disguised, -1.0);
		SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
		SetEntProp(client, Prop_Send, "m_nDisguiseClass", class);
		SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", target);
		SetEntProp(client, Prop_Send, "m_iDisguiseHealth", GetRandomInt(1, 300));
	}
}

stock void AssignTeam(int client, int team)
{
	if(Boss[client].Active && !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(Boss[client].Class));

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(!GetEntProp(client, Prop_Send, "m_iObserverMode") || !IsPlayerAlive(client))
		return;

	TF2_SetPlayerClass(client, Boss[client].Active ? Boss[client].Class : TFClass_Heavy);
	TF2_RespawnPlayer(client);
}

stock TFClassType KvGetClass(Handle kv, const char[] string)
{
	static char buffer[24];
	KvGetString(kv, string, buffer, sizeof(buffer), "1");
	TFClassType class = view_as<TFClassType>(StringToInt(buffer));
	if(class != TFClass_Unknown)
		return class;

	class = TF2_GetClass(buffer);
	if(class == TFClass_Unknown)
		class = TFClass_Scout;

	return class;
}

stock SectionType KvGetSectionType(Handle kv, char[] buffer="", int length=16)
{
	if(!KvGetSectionName(kv, buffer, length))
		return Section_Unknown;

	if(!StrContains(buffer, "sound_") || !StrContains(buffer, "catch_"))
		return Section_Sound;

	if(StrEqual(buffer, "mod_download"))
		return Section_Model;

	if(StrEqual(buffer, "mod_precache"))
		return Section_Precache;

	if(StrEqual(buffer, "mat_download"))
		return Section_Material;

	if(StrEqual(buffer, "download"))
		return Section_Download;

	if(!StrContains(buffer, "map_"))
		return Section_Map;

	if(!StrContains(buffer, "weapon") || !StrContains(buffer, "wearable") || !StrContains(buffer, "tf_") || StrEqual(buffer, "saxxy"))
		return Section_Weapon;

	return Section_Ability;
}

// -2: Blocked, -1: No Access, 0: Hidden, 1: Visible
stock int KvGetBossAccess(Handle kv, int client, bool force=false)
{
	if(!force && KvGetNum(kv, "blocked"))
		return -2;

	bool donator = KvGetNum(kv, "donator");
	int admin = KvGetNum(kv, "admin");
	bool owner = KvGetNum(kv, "owner");
	if(!(donator || admin || owner))
		return KvGetNum(kv, "hidden") ? 0 : 1;

	if(!((donator && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION)) ||
	     (owner && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT)) ||
	     (admin && !CheckCommandAccess(client, "ff2_admin_bosses", admin, true))))
		return 1;

	return KvGetNum(kv, "hidden", owner ? 1 : 0) ? -2 : -1;
}

stock bool KvGetBossAccess2(Handle kv, int client, char[] buffer, int length)
{
	if(KvGetNum(kv, "blocked"))
	{
		FormatEx(buffer, length, "%T", "Deny Unknown", client);
		return false;
	}

	bool donator = KvGetNum(kv, "donator");
	int admin = KvGetNum(kv, "admin");
	bool owner = KvGetNum(kv, "owner");
	if(!(donator || admin>0 || owner))
	{
		if(!KvGetNum(kv, "hidden"))
			return true;

		FormatEx(buffer, length, "%T", "Deny Unknown", client);
		return false;
	}

	if(!((donator && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION)) ||
	     (owner && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT)) ||
	     (admin>0 && !CheckCommandAccess(client, "ff2_admin_bosses", admin, true))))
		return true;

	FormatEx(buffer, length, "%T", KvGetNum(kv, "hidden", owner ? 1 : 0) ? "Deny Unknown" : "Deny Access", client);
	return false;
}

stock void KvGetLang(Handle kv, const char[] key, char[] buffer, int length, int client=0, const char[] defaul="=Failed name=")
{
	static char language[20];
	GetLanguageInfo(client ? GetClientLanguage(client) : GetServerLanguage(), language, sizeof(language), buffer, sizeof(buffer));
	Format(language, sizeof(language), "%s_%s", key, language);

	KvGetString(kv, language, buffer, length);
	if(buffer[0])
		return;

	if(client)
	{
		GetLanguageInfo(GetServerLanguage(), language, sizeof(language), buffer, sizeof(buffer));
		Format(language, sizeof(language), "%s_%s", key, language);
		KvGetString(kv, language, buffer, length);
	}

	if(!buffer[0])
		KvGetString(kv, key, buffer, length, defaul);
}

stock bool ConfigureWorldModelOverride(int entity, const char[] model, bool wearable=false)
{
	if(!FileExists(model, true))
		return false;

	int index = PrecacheModel(model);
	SetEntProp(entity, Prop_Send, "m_nModelIndex", index);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", index, _, 1);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", index, _, 2);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", index, _, 3);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (wearable ? index : GetEntProp(entity, Prop_Send, "m_iWorldModelIndex")), _, 0);
	return true;
}

stock void MultiClassname(TFClassType class, char[] name, int length)
{
	if(StrEqual(name, "saxxy"))
	{ 
		switch(class)
		{
			case TFClass_Scout:	strcopy(name, length, "tf_weapon_bat");
			case TFClass_Pyro:	strcopy(name, length, "tf_weapon_fireaxe");
			case TFClass_DemoMan:	strcopy(name, length, "tf_weapon_bottle");
			case TFClass_Heavy:	strcopy(name, length, "tf_weapon_fists");
			case TFClass_Engineer:	strcopy(name, length, "tf_weapon_wrench");
			case TFClass_Medic:	strcopy(name, length, "tf_weapon_bonesaw");
			case TFClass_Sniper:	strcopy(name, length, "tf_weapon_club");
			case TFClass_Spy:	strcopy(name, length, "tf_weapon_knife");
			default:		strcopy(name, length, "tf_weapon_shovel");
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun"))
	{
		switch(class)
		{
			case TFClass_Pyro:	strcopy(name, length, "tf_weapon_shotgun_pyro");
			case TFClass_Heavy:	strcopy(name, length, "tf_weapon_shotgun_hwg");
			case TFClass_Engineer:	strcopy(name, length, "tf_weapon_shotgun_primary");
			default:		strcopy(name, length, "tf_weapon_shotgun_soldier");
		}
	}
}

stock int GetHealingTarget(int client, bool checkgun=false)
{
	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");

		return -1;
	}

	if(IsValidEntity(medigun))
	{
		static char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

stock void LogError2(const char[] buffer, any ...)
{
	char message[192];
	VFormat(message, sizeof(message), buffer, 2);

	static File file;
	if(file==null || file==INVALID_HANDLE)
	{
		char path[PLATFORM_MAX_PATH];
		FormatTime(path, sizeof(path), "%Y%m%d");
		BuildPath(Path_SM, path, sizeof(path), "logs/freak_fortress_2/errors_%s.log", path);
		file = OpenFile(path, "a");
		if(file == null)
		{
			LogError(message);
			return;
		}
	}

	LogToOpenFileEx(file, message);
	PrintToServer(message);
}

stock int GetRandBlockCell(ArrayList array, int &index, int block=0, bool byte=false, int defaul=0)
{
	int size = array.Length;
	if(size < 0)
	{
		index = GetRandomInt(0, size-1);
		return array.Get(index, iBlock, byte);
	}
	index = -1;
	return defaul;
}

stock int GetRandBlockCellEx(ArrayList array, int block=0, bool byte=false, int defaul=0)
{
	int index;
	return GetRandBlockCell(array, index, block, byte, defaul);
}