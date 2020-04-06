/*
	Client Stocks:
	bool IsValidClient(int client, bool replaycheck=true)
	bool IsInvuln(int client)
	int GetIndexOfWeaponSlot(int client, int slot)
	bool RemoveCond(int client, TFCond cond)
	int GetClientCloakIndex(int client)
	void SpawnSmallHealthPackAt(int client, int team=0, int attacker, int stale)
	void IncrementHeadCount(int client)
	void HealMessage(int patient, int healer, int amount)
	int FindTeleOwner(int client)
	bool IsPlayerCritBuffed(int client)
	bool IsPlayerMiniCritBuffed(int client)
	bool IsPlayerInvis(int client)
	void RandomlyDisguise(int client)
	void AssignTeam(int client, int team)
	int GetHealingTarget(int client, bool checkgun=false)
	Action Timer_RemoveOverlay(Handle timer)
	void DoOverlay(int client, const char[] overlay)
	int CreateAttachedAnnotation(int client, int entity, bool effect=true, float time, const char[] buffer, any ...)
	void ShowGameText(int client, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)

	KeyValues Stocks:
	TFClassType KvGetClass(Handle kv, const char[] string)
	SectionType KvGetSectionType(Handle kv, char[] buffer, int length)
	int KvGetBossAccess(Handle kv, int client, bool force=false)
	bool KvGetBossAccess2(Handle kv, int client, char[] buffer, int length)
	void KvGetLang(Handle kv, const char[] key, char[] buffer, int length, int client=0, const char[] defaul="=Failed name=")

	ConfigMap Stocks:
	TFClassType CfgGetClass(ConfigMap cfg, const char[] string)
	int CfgGetBossAccess(ConfigMap cfg, int client, bool force=false)
	bool CfgGetBossAccess2(ConfigMap cfg, int client, char[] buffer, int length)
	void CfgGetLang(ConfigMap cfg, const char[] key, char[] buffer, int length, int client=0)

	Entity Stocks:
	bool ConfigureWorldModelOverride(int entity, const char[] model, bool wearable=false)
	int FindEntityByClassname2(int startEnt, const char[] classname)

	Array Stocks:
	int GetRandBlockCell(ArrayList array, int &index, int block=0, bool byte=false, int defaul=0)
	int GetRandBlockCellEx(ArrayList array, int block=0, bool byte=false, int defaul=0)

	Sound Stocks:
	void EmitVoice(const int[] clients, int numClients, const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=true, float soundtime=0.0)
	void EmitVoiceToAll(const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=true, float soundtime=0.0)
	void EmitVoiceToClient(int numClients, const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=true, float soundtime=0.0)
	void EmitVoiceSound(const int[] clients, int numClients, const char[] sample, bool canStop=true, bool stopLast=true)
	void EmitVoiceSoundToAll(const char[] sample, bool canStop=true, bool stopLast=true)
	void EmitVoiceSoundToClient(int client, const char[] sample, bool canStop=true, bool stopLast=true)
	void EmitMusic(const int[] clients, int numClients, const char[] sample)
	void EmitMusicToAll(const char[] sample)
	void EmitMusicToClient(int client, const char[] sample)
	bool PlayBossSound(int client, const char[] key, int mode=0, const char[] matching="", bool canStop=true, bool stopLast=true)
	bool GetBossSound(int client, const char[] key, int &type, char[] buffer, int bufferL, const char[] matching="", char[] name="", int nameL=32, char[] artist="", int artistL=32, float &duration=0.0)

	Other Stocks:
	int OnlyScoutsLeft(int team)
	SectionType GetSectionType(const char[] buffer)
	void MultiClassname(TFClassType class, char[] name, int length)
	void LogError2(const char[] buffer, any ...)
	int GetZeroBoss()
	int CheckRoundState()
*/

#define FF2_STOCKS

#define FAR_FUTURE	100000000.0
#define MAX_CLASSNAME_LENGTH	36

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

static const TFCond InvisConditions[] =
{
	TFCond_Cloaked,
	TFCond_Stealthed,
	TFCond_StealthedUserBuffFade
};

static const TFCond InvulnConditions[] =
{
	TFCond_Ubercharged,
	TFCond_UberchargeFading,
	TFCond_Bonked,
	TFCond_UberchargedHidden,
	TFCond_UberchargedCanteen,
	TFCond_UberchargedOnTakeDamage,
	TFCond_HalloweenGhostMode,
	
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

stock void SpawnSmallHealthPackAt(int client, int team=0, int attacker, int stale)
{
	if(stale > 14)
		return;

	int entity = CreateEntityByName(stale ? "item_healthkit_small" : "item_healthkit_medium");
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

stock bool IsPlayerInvis(int client)
{
	for(int i; i<sizeof(InvisConditions); i++)
	{
		if(TF2_IsPlayerInCondition(client, InvisConditions[i]))
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
	ChangeClientTeamEx(client, team);
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

stock TFClassType CfgGetClass(ConfigMap cfg, const char[] string)
{
	static char buffer[24];
	cfg.Get(string, buffer, sizeof(buffer));
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

	return GetSectionType(buffer);
}

stock SectionType GetSectionType(const char[] buffer)
{
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

	bool donator = view_as<bool>(KvGetNum(kv, "donator"));
	int admin = KvGetNum(kv, "admin");
	bool owner = view_as<bool>(KvGetNum(kv, "owner"));
	if(!(donator || admin || owner))
		return KvGetNum(kv, "hidden") ? 0 : 1;

	if(!((donator && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION)) ||
	     (owner && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT)) ||
	     (admin && !CheckCommandAccess(client, "ff2_admin_bosses", admin, true))))
		return 1;

	return KvGetNum(kv, "hidden", owner ? 1 : 0) ? -2 : -1;
}

stock int CfgGetBossAccess(ConfigMap cfg, int client, bool force=false)
{
	static char buffer[16];
	if(!force && cfg.GetInt("blocked"))
		return -2;

	bool donator = view_as<bool>(cfg.GetInt("donator"));
	int admin = cfg.GetInt("admin");
	bool owner = view_as<bool>(cfg.GetInt("owner"));
	if(!(donator || admin || owner))
		return cfg.GetInt("hidden") ? 0 : 1;

	if(!((donator && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION)) ||
	     (owner && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT)) ||
	     (admin && !CheckCommandAccess(client, "ff2_admin_bosses", admin, true))))
		return 1;

	return cfg.GetInt("hidden", owner ? 1 : 0) ? -2 : -1;
}

stock bool KvGetBossAccess2(Handle kv, int client, char[] buffer, int length)
{
	if(KvGetNum(kv, "blocked"))
	{
		FormatEx(buffer, length, "%T", "Deny Unknown", client);
		return false;
	}

	bool donator = view_as<bool>(KvGetNum(kv, "donator"));
	int admin = KvGetNum(kv, "admin");
	bool owner = view_as<bool>(KvGetNum(kv, "owner"));
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

stock bool CfgGetBossAccess2(ConfigMap cfg, int client, char[] buffer, int length)
{
	if(cfg.GetInt("blocked"))
	{
		FormatEx(buffer, length, "%T", "Deny Unknown", client);
		return false;
	}

	bool donator = view_as<bool>(cfg.GetInt("donator"));
	int admin = cfg.GetInt("admin");
	bool owner = view_as<bool>(cfg.GetInt("owner"));
	if(!(donator || admin>0 || owner))
	{
		if(!cfg.GetInt("hidden"))
			return true;

		FormatEx(buffer, length, "%T", "Deny Unknown", client);
		return false;
	}

	if(!((donator && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION)) ||
	     (owner && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT)) ||
	     (admin>0 && !CheckCommandAccess(client, "ff2_admin_bosses", admin, true))))
		return true;

	FormatEx(buffer, length, "%T", cfg.GetInt("hidden", owner ? 1 : 0) ? "Deny Unknown" : "Deny Access", client);
	return false;
}

stock void KvGetLang(Handle kv, const char[] key, char[] buffer, int length, int client=0, const char[] defaul="=Failed name=")
{
	static char language[20];
	GetLanguageInfo(client ? GetClientLanguage(client) : GetServerLanguage(), language, sizeof(language), buffer, length);
	Format(language, sizeof(language), "%s_%s", key, language);

	KvGetString(kv, language, buffer, length);
	if(buffer[0])
		return;

	if(client)
	{
		GetLanguageInfo(GetServerLanguage(), language, sizeof(language), buffer, length);
		Format(language, sizeof(language), "%s_%s", key, language);
		KvGetString(kv, language, buffer, length);
	}

	if(!buffer[0])
		KvGetString(kv, key, buffer, length, defaul);
}

stock void CfgGetLang(ConfigMap cfg, const char[] key, char[] buffer, int length, int client=0)
{
	static char language[20];
	GetLanguageInfo(client ? GetClientLanguage(client) : GetServerLanguage(), language, sizeof(language), buffer, length);
	Format(language, sizeof(language), "%s_%s", key, language);

	cfg.Get(language, buffer, length);
	if(buffer[0])
		return;

	if(client)
	{
		GetLanguageInfo(GetServerLanguage(), language, sizeof(language), buffer, length);
		Format(language, sizeof(language), "%s_%s", key, language);
		cfg.Get(language, buffer, length);
	}

	if(!buffer[0])
		cfg.Get(key, buffer, length);
}

stock int CfgGetNum(ConfigMap cfg, const char[] key, int defaul=0)
{
	static char buffer[32];
	if(!cfg.Get(key, buffer, sizeof(buffer)))
		return defaul;

	return StringToInt(buffer);
}

stock float CfgGetFloat(ConfigMap cfg, const char[] key, float defaul=0.0)
{
	static char buffer[32];
	if(!cfg.Get(key, buffer, sizeof(buffer)))
		return defaul;

	return StringToFloat(buffer);
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
		return array.Get(index, block, byte);
	}
	index = -1;
	return defaul;
}

stock int GetRandBlockCellEx(ArrayList array, int block=0, bool byte=false, int defaul=0)
{
	int index;
	return GetRandBlockCell(array, index, block, byte, defaul);
}

stock void EmitVoice(const int[] clients, int numClients, const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=true, float soundtime=0.0)
{
	for(int i; i<numClients; i++)
	{
		if(Client[clients[i]].Pref[Pref_Voice] < Pref_Off)
			EmitSoundToClient(clients[i], sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	}
}

stock void EmitVoiceToAll(const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=true, float soundtime=0.0)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && Client[client].Pref[Pref_Voice]<Pref_Off)
			EmitSoundToClient(client, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	}
}

stock void EmitVoiceToClient(int client, const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=true, float soundtime=0.0)
{
	if(Client[client].Pref[Pref_Voice] < Pref_Off)
		EmitSoundToClient(client, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

stock void EmitVoiceSound(const int[] clients, int numClients, const char[] sample, bool canStop=true, bool stopLast=true)
{
	for(int i; i<numClients; i++)
	{
		EmitVoiceSoundToClient(client, sample, canStop, stopLast);
	}
}

stock void EmitVoiceSoundToAll(const char[] sample, bool canStop=true, bool stopLast=true)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
			EmitVoiceSoundToClient(client, sample, canStop, stopLast);
	}
}

stock void EmitVoiceSoundToClient(int client, const char[] sample, bool canStop=true, bool stopLast=true)
{
	if(Client[client].Pref[Pref_Voice] > Pref_On)
		return;

	if(stopLast && Client[client].Voice[0])
	{
		StopSound(client, SNDCHAN_AUTO, Client[client].Voice);
		if(!canStop)
			Client[client].Voice[0] = 0;
	}

	if(canStop)
		strcopy(Client[client].Voice, PLATFORM_MAX_PATH, sample);

	ClientCommand(client, "playgamesound \"%s\"", sample);
}

stock void EmitMusic(const int[] clients, int numClients, const char[] sample)
{
	for(int i; i<numClients; i++)
	{
		if(Client[client].Pref[Pref_Music] < Pref_Off)
			ClientCommand(client, "playgamesound \"#%s\"", sample);
	}
}

stock void EmitMusicToAll(const char[] sample)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && Client[client].Pref[Pref_Music]<Pref_Off)
			ClientCommand(client, "playgamesound \"#%s\"", sample);
	}
}

stock void EmitMusicToClient(int client, const char[] sample)
{
	if(Client[client].Pref[Pref_Music] < Pref_Off)
		ClientCommand(client, "playgamesound \"#%s\"", sample);
}

stock int GetZeroBoss()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(Boss[client].Active && Boss[client].Leader)
			return client;
	}
	return -1;
}

public Action Timer_RemoveOverlay(Handle timer)
{
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsValidClient(target))
			ClientCommand(target, "r_screenoverlay off");
	}
	SetCommandFlags("r_screenoverlay", flags);
	return Plugin_Continue;
}

stock void DoOverlay(int client, const char[] overlay)
{
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	if(overlay[0])
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	}
	else
	{
		ClientCommand(client, "r_screenoverlay off");
	}
	SetCommandFlags("r_screenoverlay", flags);
}

stock int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
			return -1;

		case RoundState_StartGame, RoundState_Preround:
			return 0;

		case RoundState_RoundRunning, RoundState_Stalemate:
			return 1;
	}
	return 2;
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

stock int CreateAttachedAnnotation(int client, int entity, bool effect=true, float time, const char[] buffer, any ...)
{
	static char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 6);
	ReplaceString(message, sizeof(message), "\n", "");  //Get rid of newlines

	Event event = CreateEvent("show_annotation");
	if(event == INVALID_HANDLE)
		return -1;

	event.SetInt("follow_entindex", entity);
	event.GetFloat("lifetime", time);
	event.SetInt("visibilityBitfield", (1<<client));
	event.SetBool("show_effect", effect);
	event.SetString("text", message);
	event.SetString("play_sound", "vo/null.wav");
	event.SetInt("id", entity); //What to enter inside? Need a way to identify annotations by entindex!
	event.Fire();
	return entity;
}

stock void ShowGameText(int client, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)
{
	BfWrite bf;
	if(!client)
	{
		bf = view_as<BfWrite>(StartMessageAll("HudNotifyCustom"));
	}
	else
	{
		bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	}

	if(bf == null)
		return;

	static char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 5);
	ReplaceString(message, sizeof(message), "\n", "");

	bf.WriteString(message);
	bf.WriteString(icon);
	bf.WriteByte(color);
	EndMessage();
}

// 0: Local, 1: Global, 2: Music
stock bool PlayBossSound(int client, const char[] key, int mode=0, const char[] matching="", bool canStop=true, bool stopLast=true)
{
	float duration;
	int type = mode;
	static char buffer[PLATFORM_MAX_PATH], name[32], artist[32];
	if(!GetBossSound(client, key, type, buffer, sizeof(buffer), matching, name, sizeof(name), artist, sizeof(artist), duration))
		return false;

	switch(type)
	{
		case 1:
			EmitVoiceSoundToAll(buffer, canStop, stopLast);

		case 2:
			EmitMusicToAll(buffer);

		case 3:
			Music_Override(client, buffer, duration, name, artist);

		default:
			EmitVoiceToAll(buffer, client);
	}
	return true;
}

stock bool GetBossSound(int client, const char[] key, int &type, char[] buffer, int bufferL, const char[] matching="", char[] name="", int nameL=32, char[] artist="", int artistL=32, float &duration=0.0)
{
	ConfigMap cfg = Special[Boss[client].Special].Cfg.GetSection(key);
	if(cfg == null)
		return false;

	bool phrase = !StrContains(key, "catch_");
	StringMapSnapshot snap = cfg.Snapshot();
	if(!snap)
		return false;

	int entries = snap.Length;
	if(!entries)
	{
		delete snap;
		return false;
	}

	static char buffer3[7];
	ArrayList list = new ArrayList();
	for(int i; i<entries; i++)
	{
		int length = snap.KeyBufferSize(i)+1;
		char[] buffer2 = new char[length];
		snap.GetKey(i, buffer2, length);
		PackVal val;
		cfg.GetArray(buffer2, val, sizeof(val));
		switch(val.tag)
		{
			case KeyValType_Value:
			{
				val.data.Reset();
				val.data.ReadString(buffer3, sizeof(buffer3));

				if(!IsCharNumeric(buffer3[0]) && StrContains(buffer3, "path"))	// "1", "2", "path1", "path2"
					continue;

				if(matching[0])
				{
					ReplaceString(buffer3, sizeof(buffer3), "path", "");	// "1", "2", "1", "2"
					Format(buffer3, sizeof(buffer3), phrase ? "vo%s" : "slot%s", buffer3);	// "vo1", "vo2", "slot1", "slot2"

					if(cfg.Get(buffer3, buffer, bufferL))
					{
						if(StrContains(buffer, matching, false))
							continue;
					}
					else
					{
						if(!StrEqual(matching, "0"))
							continue;
					}
				}

				list.Push(val);
			}
			case KeyValType_Section:
			{
				if(matching[0])
				{
					if(!section.Get(phrase ? "vo" : "slot", buffer, bufferL))
						strcopy(buffer, bufferL, "0");

					if(StrContains(buffer, matching, false))
						continue;
				}

				val.data.Reset();
				val.data.WriteString(buffer2);
				list.Push(val);
			}
		}
	}

	if(list.Length < 1)
		return false;

	val = list.Get(GetRandomInt(0, list.Length-1));
	if(val.tag == KeyValType_Value)
	{
		val.data.Reset();
		val.data.ReadString(buffer3, sizeof(buffer3));
		cfg.Get(buffer3, buffer, bufferL);

		if(phrase)
			return true;

		ReplaceString(buffer3, sizeof(buffer3), "path", "");	// "1", "2"

		char buffer2[PLATFORM_MAX_PATH];
		FormatEx(buffer2, sizeof(buffer2), "%s_overlay", buffer3);	// "1_overlay", "2_overlay"
		if(cfg.Get(buffer2, buffer2, sizeof(buffer2)))
		{
			TFTeam team = TF2_GetClientTeam(client);
			int flags = GetCommandFlags("r_screenoverlay");
			SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && TF2_GetClientTeam(target)!=team)
					ClientCommand(target, "r_screenoverlay \"%s\"", buffer2);
			}
			SetCommandFlags("r_screenoverlay", flags);

			FormatEx(buffer2, sizeof(buffer2), "%s_overlay_time", buffer3);	// "1_overlay_time", "2_overlay_time"
			float time = CfgGetFloat(cfg, buffer2);
			if(time > 0)
				CreateTimer(time, Timer_RemoveOverlay, _, TIMER_FLAG_NO_MAPCHANGE);
		}

		FormatEx(buffer2, sizeof(buffer2), "%dmusic", i);	// "1music", "2music"
		duration = CfgGetFloat(cfg, buffer2, -1.0);
		if(duration >= 0)
			type = 3;

		if(type == 3)
		{
			FormatEx(buffer2, sizeof(buffer2), "%dname", i);
			Special[Boss[client].Special].Kv.GetString(buffer2, name, nameL);

			FormatEx(buffer2, sizeof(buffer2), "%dartist", i);
			Special[Boss[client].Special].Kv.GetString(buffer2, artist, artistL);
		}
		return true;
	}

	val.data.Reset();
	val.data.ReadString(buffer, bufferL);

	if(phrase)
		return true;

	char buffer2[PLATFORM_MAX_PATH];
	FormatEx(buffer2, sizeof(buffer2), "%s.overlay", buffer);
	if(cfg.Get(buffer2, buffer2, sizeof(buffer2)))
	{
		TFTeam team = TF2_GetClientTeam(client);
		int flags = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && TF2_GetClientTeam(target)!=team)
				ClientCommand(target, "r_screenoverlay \"%s\"", buffer2);
		}
		SetCommandFlags("r_screenoverlay", flags);

		FormatEx(buffer2, sizeof(buffer2), "%s.duration", buffer);
		float time = CfgGetFloat(cfg, buffer2);
		if(time > 0)
			CreateTimer(time, Timer_RemoveOverlay, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	FormatEx(buffer2, sizeof(buffer2), "%s.type", buffer);
	type = CfgGetNum(buffer2, type);

	FormatEx(buffer2, sizeof(buffer2), "%s.time", buffer);
	duration = CfgGetNum(buffer2, 0.0);
	if(type == 3)
	{
		FormatEx(buffer2, sizeof(buffer2), "%s.name", buffer);
		cfg.Get(buffer2, name, nameL);

		FormatEx(buffer2, sizeof(buffer2), "%s.artist", buffer);
		cfg.Get(buffer2, artist, artistL);
	}
	return true;
}

stock bool IsInvuln(int client)
{
	for(int i; i<sizeof(InvulnConditions); i++)
	{
		if(TF2_IsPlayerInCondition(client, InvulnConditions[i]))
			return true;
	}
	return !GetEntProp(client, Prop_Data, "m_takedamage");
}

stock int GetNextBossPlayer()
{
	int winner;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !Boss[client].Active && Client[client].Pref[Pref_Boss]<Pref_Off && GetClientTeam(client)>view_as<int>(TFTeam_Spectator) && (!winner || Client[client].Queue>=Client[winner].Queue))
			winner = client;
	}

	if(!winner)	// Ignore the boss toggle pref if we can't find available clients
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !Boss[client].Active && GetClientTeam(client)>view_as<int>(TFTeam_Spectator) && (!winner || Client[client].Queue>=Client[winner].Queue))
				winner = client;
		}
	}
	return winner;
}

stock int GetRandBossClient()
{
	int winner;
	int[] winners = new int[MaxClients];
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !Boss[client].Active && Client[client].Pref[Pref_Boss]<Pref_Off && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
			winners[winner++] = client;
	}

	if(winner)
		return winners[GetRandomInt(0, winner-1)];

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !Boss[client].Active && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
			winners[winner++] = client;
	}
	return winner ? winners[GetRandomInt(0, winner-1)] : 0;
}
