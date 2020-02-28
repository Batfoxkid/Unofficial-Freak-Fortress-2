/*
	Requirement:
	sdkhooks.sp

	Optional:
	convars.sp
	tf2items.sp

	Functions:
	void Bosses_Setup()
	void Bosses_Config()
	void Bosses_Prepare(int boss)
	void Bosses_Equip(int client, int boss)
*/

#define FF2_BOSSES

#define CONFIG_PATH		"config/freak_fortress_2"
#define CHARSET_PATH		"data/freak_fortress_2/characters.cfg"
#define DEFAULT_ATTRIBUTES	"2 ; 3.1 ; 68 ; %i ; 275 ; 1"
#define MAX_CLASSNAME_LENGTH	36
#define MAX_CHARSET_LENGTH	42
#define MAXSPECIALS		1024

enum struct BossEnum
{
	bool Leader;
	char Name[MAX_TARGET_LENGTH];
	TFClassType Class;
	TFTeam Team;

	int MaxHealth;
	int Lives;
	int MaxLives;
	float MaxSpeed;

	int RageDamage;
	int RageMode;
	float Charge[4];

	int Killstreak;
	int RPSHealth;
	int RPSCount;

	bool Voice;
	bool Triple;
	bool Knockback;
	bool Crits;
	bool Healing;
	bool Sapper;
	bool AmmoKits;
	bool HealthKits;
	bool Cosmetics;

	int Health(int client)
	{
		return GetClientHealth(client)+((this.Lives-1)*this.MaxHealth);
	}

	float Speed(int client)
	{
		return this.MaxSpeed+0.7*(100.0-Health(client)*100.0/this.MaxLives/this.MaxHealth));
	}
}

enum struct SpecialEnum
{
	KeyValues Kv;
	int Charset;
	bool Precached;
}

ConVar CvarCharset;

BossEnum Boss[MAXTF2PLAYERS];
SpecialEnum Special[MAXSPECIALS];
ArrayList BossList;
int Specials;

ArrayList Charsets;
int Charset;

void Bosses_Setup()
{
	CvarCharset = CreateConVar("ff2_current", "0", "Freak Fortress 2 Current Boss Pack", FCVAR_SPONLY|FCVAR_DONTRECORD);
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

	if(Charsets == INVALID_HANDLE)
	{
		Charsets = new ArrayList(MAX_CHARSET_LENGTH, 0);
	}
	else
	{
		Charsets.Clear();
	}

	if(BossList == INVALID_HANDLE)
	{
		BossList = new ArrayList(5, 0);
	}
	else
	{
		BossList.Clear();
	}

	char filepath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, CHARSET_PATH);

	if(!FileExists(filepath))
	{
		Charsets.SetString(0, "Freak Fortress 2");
		BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, CONFIG_PATH);
		ProcessDirectory(filepath, "", "", 0);
		return;
	}

	KeyValues kv = new KeyValues("");
	kv.ImportFromFile(filepath);

	Charset = CvarCharset.IntValue;
	char config[PLATFORM_MAX_PATH];
	int i = Charset;
	Action action = Plugin_Continue;
	Call_StartForward(OnLoadCharacterSet);
	Call_PushCellRef(i);
	Call_PushStringEx(config, sizeof(config), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	if(action == Plugin_Changed)
		Charset = i;

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
	if(CvarNameChange.IntValue == 2)
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
	isCharSetSelected = false;
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

	char key[PLATFORM_MAX_PATH];
	while(Special[Specials].Kv.GotoNextKey())
	{
		KvGetSectionName(Special[Specials].Kv, section, sizeof(section));
		if(StrEqual(section, "download"))
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
				}
				else
				{
					LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", character, config, section);
				}
			}
		}
		else if(StrEqual(section, "mod_download"))
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
		else if(StrEqual(section, "mat_download"))
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
				}
				else
				{
					LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", character, key, section);
				}
			}
		}
	}
	Specials++;
	return Special[Specials].Kv;
}

void Bosses_Prepare(int boss)
{
	if(Special[boss].Precached)
		return;

	Special[boss].Kv.Rewind();
	static char bossName[MAX_TARGET_LENGTH];
	Special[boss].Kv.GetString("filename", bossName, sizeof(bossName));
	Special[boss].Kv.GoFirstSubKey();
	char filePath[PLATFORM_MAX_PATH], key[8];
	while(Special[boss].Kv.GotoNextKey())
	{
		static char file[PLATFORM_MAX_PATH], section[16]
		Special[boss].Kv.GetSectionName(section, sizeof(section));
		if(StrEqual(section, "sound_bgm"))
		{
			for(int i=1; ; i++)
			{
				FormatEx(key, sizeof(key), "path%d", i);
				Special[boss].Kv.GetString(key, file, sizeof(file));
				if(!file[0])
					break;

				FormatEx(filePath, sizeof(filePath), "sound/%s", file);
				if(FileExists(filePath, true))
				{
					PrecacheSound(file);
				}
				else
				{
					LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
				}
			}
		}
		else if(StrEqual(section, "mod_precache"))
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

				LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
			}
		}
		else if(!StrContains(section, "sound_") || !StrContains(section, "catch_"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				Special[boss].Kv.GetString(key, file, sizeof(file));
				if(!file[0])
					break;

				FormatEx(filePath, sizeof(filePath), "sound/%s", file);
				if(FileExists(filePath, true))
				{
					PrecacheSound(file);
					continue;
				}

				LogError2("[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
			}
		}
	}
	Special[boss].Precached = true;
}

void Bosses_Equip(int client, int boss)
{
	TF2_RemoveAllWeapons(client);
	Special[boss].Kv.Rewind();
	Special[boss].Kv.GotoFirstSubKey();
	char attributes[256];
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
		else
		{
			wearable = view_as<bool>(StrContains(classname, "tf_weap"));
		}

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
				if(overridewep)
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
				if(overridewep)
				{
					FormatEx(attributes, sizeof(attributes), "214 ; %f", view_as<float>(kills));
				}
				else
				{
					FormatEx(attributes, sizeof(attributes), "%s ; 214 ; %f", DEFAULT_ATTRIBUTES, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, view_as<float>(kills));
				}
			}
		}
		else if(!overridewep)
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

static bool ConfigureWorldModelOverride(int entity, const char[] model, bool wearable=false)
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
