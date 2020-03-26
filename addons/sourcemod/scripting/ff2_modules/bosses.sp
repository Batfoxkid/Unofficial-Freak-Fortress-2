/*
	Requirement:
	sdkhooks.sp

	Optional:
	tf2items.sp

	Functions:
	void Bosses_Setup()
	void Bosses_Config()
	void Bosses_Prepare(int boss)
	void Bosses_Create(int client, int boss=-1)
	void Bosses_Equip(int client, int boss)
*/

#define FF2_BOSSES

#define CONFIG_PATH		"config/freak_fortress_2"
#define CHARSET_FILE		"data/freak_fortress_2/characters.cfg"
#define DEFAULT_ATTRIBUTES	"2 ; 3.1 ; 68 ; %i ; 275 ; 1"
#define DEFAULT_RAGEDAMAGE	"1900"
#define DEFAULT_HEALTH		""
#define MAX_CLASSNAME_LENGTH	36
#define MAX_CHARSET_LENGTH	42

ConVar CvarCharset;
static ConVar CvarTriple;
static ConVar CvarKnockback;
static ConVar CvarCrits;
static ConVar CvarHealing;

void Bosses_Setup()
{
	CvarCharset = CreateConVar("ff2_current", "0", "Freak Fortress 2 Next Boss Pack", FCVAR_DONTRECORD);

	CvarTriple = CreateConVar("ff2_boss_triple", "1", "If to triple damage against players if initial damage is less than 160", _, true, 0.0, true, 1.0);
	CvarKnockback = CreateConVar("ff2_boss_knockback", "0", "If bosses can knockback themselves, 2 to also allow self-damaging", _, true, 0.0, true, 2.0);
	CvarCrits = CreateConVar("ff2_boss_crits", "0", "If bosses can perform random crits", _, true, 0.0, true, 1.0);
	CvarHealing = CreateConVar("ff2_boss_healing", "0", "If bosses can be healed by Medics, packs, etc.", _, true, 0.0, true, 1.0);
}

void Bosses_Config()
{
	Specials = 0;
	Charset = 0;
	for(int i; i<MAXSPECIALS; i++)
	{
		if(Special[i].Kv != INVALID_HANDLE)
			delete Special[i].Kv;

		Special[i].Kv = INVALID_HANDLE;
		Special[i].Charset = -1;
	}

	if(Charsets != INVALID_HANDLE)
		delete Charsets;

	if(BossList != INVALID_HANDLE)
		delete BossList;

	Charsets = new ArrayList(MAX_CHARSET_LENGTH, 0);
	BossList = new ArrayList(5, 0);

	char filepath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, CHARSET_FILE);

	if(!FileExists(filepath))
	{
		Charsets.SetString(0, "Freak Fortress 2");
		BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, CONFIG_PATH);
		if(Enabled <= Game_Disabled)
			Charset = -1;

		ProcessDirectory(filepath, "", "", 0);
		return;
	}

	if(Enabled > Game_Disabled)
	{
		Charset = CvarCharset.IntValue;
		char config[PLATFORM_MAX_PATH];
		int i = Charset;
		Action action = Plugin_Continue;
		Call_StartForward(OnLoadCharacterSet);
		Call_PushCellRef(i);
		Call_PushStringEx(config, sizeof(config), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_Finish(action);
		if(action == Plugin_Changed)
		{
			if(i < 0)
			{
				Charset = 0;
			}
			else
			{
				Charset = i;
			}
		}
	}
	else
	{
		Charset = -1;
	}

	KeyValues kv = new KeyValues("");
	kv.ImportFromFile(filepath);

	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, ConfigPath);
	int charset;
	do
	{
		kv.GetSectionName(config, sizeof(config));
		Charsets.SetString(charset, config);

		kv.GetString("1", config, PLATFORM_MAX_PATH);
		if(config[0])
		{
			for(i=2; Specials<MAXSPECIALS && i<=MAXSPECIALS; i++)
			{
				if(config[0])
				{
					if(StrContains(config, "*") != -1)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						ProcessDirectory(filepath, "", config, charset);
						continue;
					}
					else
					{
						LoadCharacter(config, charset);
					}
				}

				IntToString(i, key, sizeof(key));
				kv.GetString(key, config, PLATFORM_MAX_PATH);
			}
			charset++;
			continue;
		}

		kv.SavePosition();
		kv.GotoFirstSubKey();
		do
		{
			if(!kv.GetSectionName(config, PLATFORM_MAX_PATH))
				break;

			if(StrContains(config, "*") >= 0)
			{
				ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
				ProcessDirectory(filepath, "", config, charset, kv);
				continue;
			}

			KeyValues bosskv = LoadCharacter(config, charset);
			if(bosskv != INVALID_HANDLE)
				bosskv.Import(kv);
		} while(Specials<MAXSPECIALS && kv.GotoNextKey());
		kv.GoBack();
		charset++;
	} while(kv.GotoNextKey())

	delete kv;

	#if defined FF2_CONVARS
	if(Charset!=-1 && CvarNameChange.IntValue==2)
		Convars_NameSuffix(Charsets.GetString(Charset));
	#endif

	if(FileExists("sound/saxton_hale/9000.wav", true))
	{
		AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
		PrecacheSound("saxton_hale/9000.wav", true);
	}

	PrecacheScriptSound("Announcer.AM_CapEnabledRandom");
	PrecacheScriptSound("Announcer.AM_CapIncite01.mp3");
	PrecacheScriptSound("Announcer.AM_CapIncite02.mp3");
	PrecacheScriptSound("Announcer.AM_CapIncite03.mp3");
	PrecacheScriptSound("Announcer.AM_CapIncite04.mp3");
	PrecacheScriptSound("Announcer.RoundEnds5minutes");
	PrecacheScriptSound("Announcer.RoundEnds2minutes");
	PrecacheSound("weapons/barret_arm_zap.wav", true);
	PrecacheSound("player/doubledonk.wav", true);
	PrecacheSound("ambient/lightson.wav", true);
	PrecacheSound("ambient/lightsoff.wav", true);
}

static void ProcessDirectory(const char[] base, const char[] current, const char[] matching, int pack, KeyValues kv=INVALID_HANDLE)
{
	char file[PLATFORM_MAX_PATH];
	FormatEx(file, PLATFORM_MAX_PATH, "%s/%s", base, current);
	if(!DirExists(file))
		return;

	DirectoryListing listing = OpenDirectory(file);
	if(listing == null)
		return;

	FileType type;
	while(Specials<MAXSPECIALS && listing.GetNext(file, PLATFORM_MAX_PATH, type))
	{
		if(type == FileType_File)
		{
			if(ReplaceString(file, PLATFORM_MAX_PATH, ".cfg", "", false) != 1)
				continue;

			if(current[0])
			{
				ReplaceString(file, PLATFORM_MAX_PATH, "\\", "/");
				Format(file, PLATFORM_MAX_PATH, "%s/%s", current, file);
			}

			if(!StrContains(file, matching))
			{
				if(kv == INVALID_HANDLE)
				{
					LoadCharacter(file, pack);
					continue;
				}

				KeyValues bosskv = LoadCharacter(file, pack);
				if(bosskv != INVALID_HANDLE)
					bosskv.Import(kv);
			}
			continue;
		}

		if(type!=FileType_Directory || !StrContains(file, "."))
			continue;

		if(current[0])
			Format(file, PLATFORM_MAX_PATH, "%s/%s", current, file);

		ProcessDirectory(base, file, matching, pack, kv);
	}
	delete listing;
}

static KeyValues LoadCharacter(const char[] character, int charset)
{
	static char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s.cfg", ConfigPath, character);
	if(!FileExists(config))
	{
		LogError2("[Characters] Character %s does not exist!", character);
		return INVALID_HANDLE;
	}

	Special[Specials].Kv = new KeyValues("character");
	if(!Special[Specials].Kv.ImportFromFile(config))
	{
		LogError2("[Characters] Character %s failed to be imported for KeyValues!", character);
		return INVALID_HANDLE;
	}

	int version = Special[Specials].Kv.GetNum("version", StringToInt(MAJOR_REVISION));
	if(version!=StringToInt(MAJOR_REVISION) && version!=99) // 99 for bosses made ONLY for this fork
	{
		LogError2("[Boss] Character %s is only compatible with FF2 v%i!", character, version);
		return INVALID_HANDLE;
	}

	version = Special[Specials].Kv.GetNum("version_minor", StringToInt(MINOR_REVISION));
	int version2 = Special[Specials].Kv.GetNum("version_stable", StringToInt(STABLE_REVISION));
	if(version>StringToInt(MINOR_REVISION) || (version2>StringToInt(STABLE_REVISION) && version==StringToInt(MINOR_REVISION)))
	{
		LogError2("[Boss] Character %s requires newer version of FF2 (at least %s.%i.%i)!", character, MAJOR_REVISION, version, version2);
		return INVALID_HANDLE;
	}

	version = Special[Specials].Kv.GetNum("fversion", StringToInt(FORK_MAJOR_REVISION));
	if(version != StringToInt(FORK_MAJOR_REVISION))
	{
		LogError2("[Boss] Character %s is only compatible with %s FF2 v%i!", character, FORK_SUB_REVISION, version);
		return INVALID_HANDLE;
	}

	version = Special[Specials].Kv.GetNum("fversion_minor", StringToInt(FORK_MINOR_REVISION));
	version2 = Special[Specials].Kv.GetNum("fversion_stable", StringToInt(FORK_STABLE_REVISION));
	if(version>StringToInt(FORK_MINOR_REVISION) || (version2>StringToInt(FORK_STABLE_REVISION) && version==StringToInt(FORK_MINOR_REVISION)))
	{
		LogError2("[Boss] Character %s requires newer version of %s FF2 (at least %s.%i.%i)!", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, version, version2);
		return INVALID_HANDLE;
	}

	if(Charset!=charset || Enabled<=Game_Disabled)
	{
		Special[Specials].Kv.SetString("filename", character);
		Specials++;
		return Special[Specials-1].Kv;
	}

	static char section[64];
	if(charset != Charset)
	{
		if(Special[Specials].Kv.JumpToKey("map_whitelist"))
		{
			bool found;
			char item[4];
			for(int i=1; ; i++)
			{
				IntToString(i, item, sizeof(item));
				Special[Specials].Kv.GetString(item, section, sizeof(section));
				if(!buffer[0])
					break;

				if(StrContains(MapName, section))
					continue;

				found = true;
				break;
			}

			if(!found)
				return INVALID_HANDLE;

			Special[Specials].Kv.Rewind();
		}
		else if(Special[Specials].Kv.JumpToKey("map_blacklist"))
		{
			char item[4];
			for(int i=1; ; i++)
			{
				IntToString(i, item, sizeof(item));
				Special[Specials].Kv.GetString(item, section, sizeof(section));
				if(!buffer[0])
					break;

				if(!StrContains(MapName, buffer))
					return INVALID_HANDLE;
			}
			Special[Specials].Kv.Rewind();
		}
		else if(Special[Specials].Kv.JumpToKey("map_exclude"))
		{
			char item[6];
			for(int i=1; ; i++)
			{
				FormatEx(item, sizeof(item), "map%d", i);
				Special[Specials].Kv.GetString(item, section, sizeof(section));
				if(!buffer[0])
					break;

				if(!StrContains(MapName, buffer))
					return INVALID_HANDLE;
			}
			Special[Specials].Kv.Rewind();
		}
	}

	Special[Specials].Kv.SetString("filename", character);
	Special[Specials].Kv.GetString("name", config, sizeof(config));
	Special[Specials].Kv.GotoFirstSubKey();
	BossList.Push(Specials);

	char key[PLATFORM_MAX_PATH];
	while(Special[Specials].Kv.GotoNextKey())
	{
		static char section[16];
		SectionType type = KvGetSectionType(Special[Specials].Kv, section, sizeof(section));
		switch(type)
		{
			case Section_Download:
			{
				for(int i=1; ; i++)
				{
					IntToString(i, key, sizeof(key));
					Special[Specials].Kv.GetString(key, config, sizeof(config));
					if(!config[0])
						break;

					if(FileExists(config, true))
					{
						AddFileToDownloadsTable(config);
						continue;
					}

					LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", character, config, section);
				}
			}
			case Section_Model:
			{
				for(int i=1; ; i++)
				{
					IntToString(i, key, sizeof(key));
					Special[Specials].Kv.GetString(key, config, sizeof(config));
					if(!config[0])
						break;

					static const char extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy"};
					for(int extension; extension<sizeof(extensions); extension++)
					{
						FormatEx(key, PLATFORM_MAX_PATH, "%s%s", config, extensions[extension]);
						if(FileExists(key, true))
						{
							AddFileToDownloadsTable(key);
						}
						else if(StrContains(key, ".phy") == -1)
						{
							LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", character, key, section);
						}
					}
				}
			}
			case Section_Material:
			{
				for(int i=1; ; i++)
				{
					IntToString(i, key, sizeof(key));
					Special[Specials].Kv.GetString(key, config, sizeof(config));
					if(!config[0])
						break;

					FormatEx(key, sizeof(key), "%s.vtf", config);
					if(FileExists(key, true))
					{
						AddFileToDownloadsTable(key);
					}
					else
					{
						LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", character, key, section);
					}

					FormatEx(key, sizeof(key), "%s.vmt", config);
					if(FileExists(key, true))
					{
						AddFileToDownloadsTable(key);
						continue;
					}
					
					LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", character, key, section);
				}
			}
		}
	}
	return Special[Specials++].Kv;
}

void Bosses_Prepare(int boss)
{
	if(Special[boss].Precached)
		return;

	Special[boss].Kv.Rewind();
	Special[boss].Kv.GoFirstSubKey();
	char filePath[PLATFORM_MAX_PATH], key[8];
	while(Special[boss].Kv.GotoNextKey())
	{
		static char file[PLATFORM_MAX_PATH], section[16];
		SectionType type = KvGetSectionType(Special[Specials].Kv, section, sizeof(section));
		switch(type)
		{
			case Section_Sound:
			{
				for(int i=1; ; i++)
				{
					IntToString(i, key, sizeof(key));
					Special[boss].Kv.GetString(key, file, sizeof(file));
					if(!file[0])
					{
						FormatEx(key, sizeof(key), "path%d", i);
						Special[boss].Kv.GetString(key, file, sizeof(file));
						if(!file[0])
							break;
					}

					FormatEx(filePath, sizeof(filePath), "sound/%s", file);
					if(FileExists(filePath, true))
					{
						PrecacheSound(file);
						continue;
					}

					char bossName[MAX_TARGET_LENGTH];
					Special[boss].Kv.GetString("filename", bossName, sizeof(bossName));
					LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
				}
			}
			case Section_Precache:
			{
				for(int i=1; ; i++)
				{
					IntToString(i, key, sizeof(key));
					Special[boss].Kv.GetString(key, file, sizeof(file));
					if(!file[0])
						break;

					if(FileExists(file, true))
					{
						PrecacheModel(file);
						continue;
					}

					char bossName[MAX_TARGET_LENGTH];
					Special[boss].Kv.GetString("filename", bossName, sizeof(bossName));
					LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
				}
			}
		}
	}
	Special[boss].Precached = true;
}

void Bosses_Create(int client, int boss=-1)
{
	if(boss < 0)
	{
		if(!Boss[client].Active)
			return;

		Boss[client].Active = false;
		SDKUnhook(client, SDKHook_GetMaxHealth, SDK_OnGetMaxHealth);
		if(IsPlayerAlive(client))
			TF2_RegeneratePlayer(client);
	}

	Bosses_Prepare(boss);

	Boss[client].RageDamage = RoundFloat(ParseFormula(boss, "ragedamage", DEFAULT_RAGEDAMAGE));
	Boss[client].Lives = Special[boss].Kv.GetNum("lives", 1);
	if(Boss[client].Lives < 1)
		Boss[client].Lives = 1;

	Boss[client].MaxLives = Boss[client].Lives;
	Boss[client].MaxHealth = RoundFloat(ParseFormula(boss, "health_formula", DEFAULT_HEALTH));
	if(Boss[client].MaxHealth < 1)
		Boss[client].MaxHealth = RoundFloat(Pow((760.8+float(Players))*(float(Players)-1.0), 1.0341)+2046.0);

	Boss[client].Health = Boss[client].MaxHealth*Boss[client].Lives;

	Boss[client].Triple = view_as<bool>(Special[boss].Kv.GetNum("triple", CvarTriple.IntValue));
	Boss[client].Knockback = Special[boss].Kv.GetNum("knockback", Special[boss].Kv.GetNum("rocketjump", CvarKnockback.IntValue));
	Boss[client].Crits = Special[boss].Kv.GetNum("crits", CvarCrits.IntValue);
	Boss[client].Healing = view_as<bool>(Special[boss].Kv.GetNum("healing", CvarHealing.IntValue));

	Boss[client].Voice = !Special[boss].Kv.GetNum("sound_block_vo");
	Boss[client].RageMode = Special[boss].Kv.GetNum("ragemode");
	Boss[client].RageMax = Special[boss].Kv.GetFloat("ragemax", 100.0);
	Boss[client].RageMin = Special[boss].Kv.GetFloat("ragemin", 100.0);
	Boss[client].Class = KvGetClass(Special[boss].Kv, "class");
	Boss[client].MaxSpeed = Special[boss].Kv.GetFloat("maxspeed", 340.0);
	Boss[client].Team = view_as<TFTeam>(Special[boss].Kv.GetNum("bossteam"));
	if(Boss[client].Team == TFTeam_Unassigned)
	{
		switch(CvarTeam.IntValue)
		{
			case 1:		Boss[client].Team = GetRandomInt(0, 1) ? TFTeam_Red : TFTeam_Blue;
			case 2:		Boss[client].Team = TFTeam_Red;
			default:	Boss[client].Team = TFTeam_Blue;
		}	
	}
	else if(Boss[client].Team == TFTeam_Spectator)
	{
		Boss[client].Team = GetRandomInt(0, 1) ? TFTeam_Red : TFTeam_Blue;
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	TF2_RemovePlayerDisguise(client);
	TF2_SetPlayerClass(client, Boss[client].Class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	SDKHook(client, SDKHook_GetMaxHealth, SDK_OnGetMaxHealth);

	int i = Special[boss].Kv.GetNum("sapper", CvarSapper.IntValue);
	Boss[client].Sapper = (i==1 || i>2);

	i = Special[boss].Kv.GetNum("pickups");
	Boss[client].HealthKits = (i==1 || i>2);
	Boss[client].AmmoKits = i>1;

	Boss[client].Killstreak = 0;
	Boss[client].RPSHealth = 0;
	Boss[client].RPSCount = 0;
	Boss[client].Charge[0] = 0.0;
	Boss[client].Hazard = 0.0;

	Boss[client].Cosmetics = view_as<bool>(Special[boss].Kv.GetNum("cosmetics"));
	i = -1;
	while((i=FindEntityByClassname2(i, "tf_wear*")) != -1)
	{
		if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") != client)
			continue;

		switch(GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex"))
		{
			case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
			{
				//NOOP
			}
			case 131, 133, 405, 406, 444, 608, 1099, 1144:	// Wearable weapons
			{
				TF2_RemoveWearable(client, i);
			}
			default:
			{
				if(!Boss[client].Cosmetics)
					TF2_RemoveWearable(client, i);
			}
		}
	}

	i = -1;
	while((i=FindEntityByClassname2(i, "tf_powerup_bottle")) != -1)
	{
		if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
			TF2_RemoveWearable(client, i);
	}

	Bosses_Equip(client, boss);

	bool var;
	for(int target=1; target<=MaxClients; target++)
	{
		if(!Boss[target].Active || !Boss[target].Leader)
			continue;

		var = true;
		break;
	}

	Boss[client].Leader = !var;
}

void Bosses_Equip(int client, int boss)
{
	TF2_RemoveAllWeapons(client);
	Special[boss].Kv.Rewind();
	Special[boss].Kv.GotoFirstSubKey();
	char attributes[PLATFORM_MAX_PATH];
	do
	{
		static char classname[MAX_CLASSNAME_LENGTH];
		if(!Special[boss].Kv.GetSectionName(classname, sizeof(classname))
			continue;

		bool wearable;
		if(StrContains(classname, "tf_") && !StrEqual(classname, "saxxy"))
		{
			if(StrContains(classname, "weapon"))
			{
				if(StrContains(classname, "wearable"))
					continue;

				wearable = true;
			}

			Special[boss].Kv.GetString("name", classname, sizeof(classname), wearable ? "tf_wearable" : "saxxy");
		}

		MultiClassname(TF2_GetPlayerClass(client), classname, sizeof(classname));
		wearable = view_as<bool>(StrContains(classname, "tf_weap"));

		if(wearable && SDKEquipWearable==null)
			continue;

		int index = Special[boss].Kv.GetNum("index");
		int level = Special[boss].Kv.GetNum("level", -1);
		bool override = view_as<bool>(Special[boss].Kv.GetNum("override"));
		int rank = Special[boss].Kv.GetNum("rank", (level==-1 || override) ? -1 : 21);
		int kills = GetRankingKills(rank, index, wearable);

		if(level < 0)
			level = 101;

		Special[boss].Kv.GetString("attributes", attributes, sizeof(attributes));
		if(kills >= 0)
		{
			if(attributes[0])
			{
				if(override)
				{
					Format(attributes, sizeof(attributes), "214 ; %f ; %s", view_as<float>(kills), attributes);
				}
				else
				{
					Format(attributes, sizeof(attributes), "%s ; 214 ; %f ; %s", DEFAULT_ATTRIBUTES, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, view_as<float>(kills), attributes);
				}
			}
			else
			{
				if(override)
				{
					FormatEx(attributes, sizeof(attributes), "214 ; %f", view_as<float>(kills));
				}
				else
				{
					FormatEx(attributes, sizeof(attributes), "%s ; 214 ; %f", DEFAULT_ATTRIBUTES, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, view_as<float>(kills));
				}
			}
		}
		else if(!override)
		{
			if(attributes[0])
			{
				Format(attributes, sizeof(attributes), "%s ; %s", DEFAULT_ATTRIBUTES, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, attributes);
			}
			else
			{
				FormatEx(attributes, sizeof(attributes), DEFAULT_ATTRIBUTES, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);
			}
		}

		#if defined FF2_TF2ITEMS
		index = (TF2Items && !wearable) ? TF2Items_SpawnWeapon(client, classname, index, level, Special[boss].Kv.GetNum("quality", 5), attributes) : SDK_SpawnWeapon(client, classname, index, level, Special[boss].Kv.GetNum("quality", 5), attributes);
		#else
		index = SDK_SpawnWeapon(client, classname, index, level, Special[boss].Kv.GetNum("quality", 5), attributes);
		#endif
		if(index == -1)
			continue;

		if(!wearable)
		{
			FF2_SetAmmo(client, index, Special[boss].Kv.GetNum("ammo", -1), Special[boss].Kv.GetNum("clip", -1));
			if(index!=735 && StrEqual(classname, "tf_weapon_builder", false))
			{
				SetEntProp(index, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
				SetEntProp(index, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
				SetEntProp(index, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
				SetEntProp(index, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
			}
			else if(index==735 || StrEqual(classname, "tf_weapon_sapper", false))
			{
				SetEntProp(index, Prop_Send, "m_iObjectType", 3);
				SetEntProp(index, Prop_Data, "m_iSubType", 3);
				SetEntProp(index, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
				SetEntProp(index, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
				SetEntProp(index, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
				SetEntProp(index, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
			}
		}

		if(Special[boss].Kv.GetNum("show", wearable ? 1 : 0))
		{
			Special[boss].Kv.GetString("worldmodel", attributes, sizeof(attributes));
			if(attributes[0])
				ConfigureWorldModelOverride(index, attributes, wearable);

			SetEntProp(index, Prop_Send, "m_bValidatedAttachedEntity", 1);
		}
		else
		{
			SetEntProp(index, Prop_Send, "m_bValidatedAttachedEntity", 0);
			SetEntProp(index, Prop_Send, "m_iWorldModelIndex", -1);
			SetEntPropFloat(index, Prop_Send, "m_flModelScale", 0.001);
			SetEntProp(index, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
		}

		static int rgba[4];
		rgba[0] = Special[boss].Kv.GetNum("alpha", 255);
		rgba[1] = Special[boss].Kv.GetNum("red", 255);
		rgba[2] = Special[boss].Kv.GetNum("green", 255);
		rgba[3] = Special[boss].Kv.GetNum("blue", 255);

		for(level=0; level<4; level++)
		{
			if(rgba[level] == 255)
				continue;

			SetEntityRenderMode(index, RENDER_TRANSCOLOR);
			SetEntityRenderColor(index, rgba[1], rgba[2], rgba[3], rgba[0]);
			break;
		}

		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", index);
	} while(Special[boss].Kv.GotoNextKey());
}

bool Bosses_GetSound(const char[] key, char[] buffer, int length, int client, int slot=-2)
{
	Special[Boss[client].Special].Kv.Rewind();
	if(!Special[Boss[client].Special].Kv.JumpToKey(key))
		return false;

	if(Boss[client].Special < 0)
		return false;

	char buffer[2];
	if(Special[Boss[client].Special].Kv.GotoFirstSubKey())
	{
		do
		{
			if(KvGetSectionType(Special[Boss[client].Special].Kv) == Section_Sound)
				continue;

		} while(Special[Boss[client].Special].Kv.GotoNextKey());
	}
}

// 0: Local Default, 1: Global Default, 2: Music Default
bool Bosses_PlaySound(const char[] key, int client, int mode=0, const char[] matching="")
{
	if(Boss[client].Special < 0)
		return false;

	Special[Boss[client].Special].Kv.Rewind();
	if(!Special[Boss[client].Special].Kv.JumpToKey(key))
		return false;

	static char buffer[PLATFORM_MAX_PATH], name[32], artist[32];
	int type = mode;
	float duration;
	bool catch = !StrContains(key, "catch_");
	if(matching[0])
	{
		ArrayList list = new ArrayList();
		if(Special[Boss[client].Special].Kv.GotoFirstSubKey())
		{
			for(int i; ; i++)
			{
				Special[Boss[client].Special].Kv.GetString(catch ? "vo" : "slot", buffer, sizeof(buffer))
				if(!StrContains(buffer, matching, false))
					list.Push(i);

				if(!Special[Boss[client].Special].Kv.GotoNextKey())
					break;
			}

			int choosen = list.Length;
			if(choosen < 1)
			{
				delete list;
				return false;
			}

			choosen = list.Get(GetRandomInt(0, choosen-1));
			delete list;
			Special[Boss[client].Special].Kv.Rewind();
			if(!Special[Boss[client].Special].Kv.JumpToKey(key))
				return false;

			while(choosen>0 && Special[Boss[client].Special].Kv.GotoNextKey())
			{
				choosen--;
			}

			if(!Special[Boss[client].Special].Kv.GetSectionName(buffer, sizeof(buffer)))
				return false;

			if(!mode)
			{
				type = Special[Boss[client].Special].Kv.GetNum("type", type);
				duration = Special[Boss[client].Special].Kv.GetFloat("time");
				if(type == 3)
				{
					Special[Boss[client].Special].Kv.GetString("name", name, sizeof(name));
					Special[Boss[client].Special].Kv.GetString("artist", artist, sizeof(artist));
				}
			}
		}
		else
		{
			char key[8];
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				Special[Boss[client].Special].Kv.GetString(key, key, sizeof(key));
				if(key[0])
				{
					Special[Boss[client].Special].Kv.GetString(type==-1 ? "vo" : "slot", buffer, sizeof(buffer))
					if(!StrContains(buffer, matching, false))
						list.Push(i);

					continue;
				}

				if(list.Length)
				{
					version = 1;
					break;
				}

				for(i=1; ; i++)
				{
					FormatEx(key, sizeof(key), "path%d", i);
					Special[Boss[client].Special].Kv.GetString(key, key, sizeof(key));
					if(!key[0])
						break;

					Special[Boss[client].Special].Kv.GetString(type==-1 ? "vo" : "slot", buffer, sizeof(buffer))
					if(!StrContains(buffer, matching, false))
						list.Push(i);
				}
			}
		}
		delete list;
	}
	else
	{
		int count;
		version = Special[Boss[client].Special].Kv.GotoFirstSubKey();
		if(version)
		{
			do
			{
				count++;
			} while(Special[Boss[client].Special].Kv.GotoNextKey());
			return count ? GetRandomInt(0, count-1) : -1;
		}

		char key[8];
		for(int i=1; ; i++)
		{
			IntToString(i, key, sizeof(key));
			Special[Boss[client].Special].Kv.GetString(key, key, sizeof(key));
			if(key[0])
			{
				count++;
				continue;
			}

			if(count)
				return GetRandomInt(0, count-1);

			for(i=1; ; i++)
			{
				FormatEx(key, sizeof(key), "path%d", i);
				Special[Boss[client].Special].Kv.GetString(key, key, sizeof(key));
				if(!key[0])
					return count ? GetRandomInt(0, count-1) : -1;

				count++;
			}
		}
		return -1;
	}
}

static bool KvGetRandomSlotSound(Handle kv, const char[] key, int slot, char[] sound, int &type, float &time)
{
	Special[Boss[client].Special].Kv.Rewind();
	if(!Special[Boss[client].Special].Kv.JumpToKey(key))
		return false;


	
}

static int GetRankingKills(int rank, int index, bool wearable)
{
	case -1:
	{
		return -1;
	}
	case 0:
	{
		if(index==133 || index==444 || index==655)	// Gunboats, Mantreads, or Spirit of Giving
			return 0;

		return wearable ? GetRandomInt(0, 14) : GetRandomInt(0, 9);
	}
	case 1:
	{
		if(index==133 || index==444 || index==655)
			return GetRandomInt(1, 2);

		return wearable ? GetRandomInt(15, 29) : GetRandomInt(10, 24);
	}
	case 2:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(3, 4);

			case 655:
				return GetRandomInt(3, 6);

			default:
				return wearable ? GetRandomInt(30, 49) : GetRandomInt(25, 44);
		}
	}
	case 3:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(5, 6);

			case 655:
				return GetRandomInt(7, 11);

			default:
				return wearable ? GetRandomInt(50, 74) : GetRandomInt(45, 69);
		}
	}
	case 4:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(7, 9);

			case 655:
				return GetRandomInt(12, 19);

			default:
				return wearable ? GetRandomInt(75, 99) : GetRandomInt(70, 99);
		}
	}
	case 5:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(10, 13);

			case 655:
				return GetRandomInt(20, 27);

			default:
				return GetRandomInt(100, 134);
		}
	}
	case 6:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(14, 17);

			case 655:
				return GetRandomInt(28, 36);

			default:
				return GetRandomInt(135, 174);
		}
	}
	case 7:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(18, 22);

			case 655:
				return GetRandomInt(37, 46);

			default:
				return wearable ? GetRandomInt(175, 249) : GetRandomInt(175, 224);
		}
	}
	case 8:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(23, 27);

			case 655:
				return GetRandomInt(47, 56);

			default:
				return wearable ? GetRandomInt(250, 374) : GetRandomInt(225, 274);
		}
	}
	case 9:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(28, 34);

			case 655:
				return GetRandomInt(57, 67);

			default:
				return wearable ? GetRandomInt(375, 499) : GetRandomInt(275, 349);
		}
	}
	case 10:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(35, 49);

			case 655:
				return GetRandomInt(68, 78);

			default:
				return wearable ? GetRandomInt(500, 724) : GetRandomInt(350, 499);
		}
	}
	case 11:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(50, 74);

			case 655:
				return GetRandomInt(79, 90);

			case 656:
				return GetRandomInt(500, 748);

			default:
				return wearable ? GetRandomInt(725, 999) : GetRandomInt(500, 749);
		}
	}
	case 12:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(75, 98);

			case 655:
				return GetRandomInt(91, 103);

			case 656:
				return 749;

			default:
				return wearable ? GetRandomInt(1000, 1499) : GetRandomInt(750, 998);
		}
	}
	case 13:
	{
		switch(index)
		{
			case 133, 444:
				return 99;

			case 655:
				return GetRandomInt(104, 119);

			case 656:
				return GetRandomInt(750, 999);

			default:
				return wearable ? GetRandomInt(1500, 1999) : 999;
		}
	}
	case 14:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(100, 149);

			case 655:
				return GetRandomInt(120, 137);

			default:
				return wearable ? GetRandomInt(2000, 2749) : GetRandomInt(1000, 1499);
		}
	}
	case 15:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(150, 249);

			case 655:
				return GetRandomInt(138, 157);

			default:
				return wearable ? GetRandomInt(2750, 3999) : GetRandomInt(1500, 2499);
		}
	}
	case 16:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(250, 499);

			case 655:
				return GetRandomInt(158, 178);

			default:
				return wearable ? GetRandomInt(4000, 5499) : GetRandomInt(2500, 4999);
		}
	}
	case 17:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(500, 749);

			case 655:
				return GetRandomInt(179, 209);

			default:
				return wearable ? GetRandomInt(5500, 7499) : GetRandomInt(5000, 7499);
		}
	}
	case 18:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(750, 783);

			case 655:
				return GetRandomInt(210, 249);

			case 656:
				return GetRandomInt(7500, 7922);

			default:
				return wearable ? GetRandomInt(7500, 9999) : GetRandomInt(7500, 7615);
		}
	}
	case 19:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(784, 849);

			case 655:
				return GetRandomInt(250, 299);

			case 656:
				return GetRandomInt(7923, 8499);

			default:
				return wearable ? GetRandomInt(10000, 14999) : GetRandomInt(7616, 8499);
		}
	}
	case 20:
	{
		switch(index)
		{
			case 133, 444:
				return GetRandomInt(850, 999);

			case 655:
				return GetRandomInt(300, 399);

			default:
				return wearable ? GetRandomInt(15000, 19999) : GetRandomInt(8500, 9999);
		}
	}
	default:
	{
		return GetRankingKills(GetRandomInt(0, 20), index, wearable);
	}
}
