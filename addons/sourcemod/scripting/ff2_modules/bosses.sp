/*
	Requirement:
	sdkhooks

	Optional:
	tf2items

	Functions:
	void Bosses_Setup()
	void Bosses_Config(const char[] map)
	void Bosses_Prepare(int boss)
	void Bosses_Create(int client)
	void Bosses_Equip(int client)
	void Bosses_Model(int userid)
	void Bosses_AbilitySlot(int client, int slot)
	void Bosses_Ability(int client, const char[] ability, const char[] plugin, int slot, int buttonMode)
	int Bosses_ArgI(int client, const char[] ability, const char[] plugin, const char[] arg="", int index=-1, int defaul=0)
	float Bosses_ArgF(int client, const char[] ability, const char[] plugin, const char[] arg="", int index=-1, float defaul=0.0)
	bool Bosses_ArgS(int client, const char[] ability, const char[] plugin, const char[] arg="", int index=-1, char[] buffer, int length)
	ConfigMap Bosses_ArgC(int client, const char[] ability, const char[] plugin)
*/

#define FF2_BOSSES

#define CONFIG_PATH		"config/freak_fortress_2"
#define CHARSET_FILE		"data/freak_fortress_2/characters.cfg"
#define DEFAULT_ATTRIBUTES	"2 ; 3.1 ; 68 ; %d ; 275 ; 1"
#define DEFAULT_RAGEDAMAGE	1900.0
#define DEFAULT_HEALTH		(Pow((760.8+float(Players))*(Players-1.0), 1.0341)+2046.0)
#define MAX_CHARSET_LENGTH	42

ConVar CvarCharset;
static ConVar CvarTriple;
static ConVar CvarKnockback;
static ConVar CvarCrits;
static ConVar CvarHealing;
static ConVar CvarSapper;
static ConVar CvarSewerSlide;
static ConVar CvarTeam;

void Bosses_Setup()
{
	CvarCharset = CreateConVar("ff2_current", "0", "Freak Fortress 2 Next Boss Pack", FCVAR_DONTRECORD);

	CvarTriple = CreateConVar("ff2_boss_triple", "1", "If to triple damage against players if initial damage is less than 160", _, true, 0.0, true, 1.0);
	CvarKnockback = CreateConVar("ff2_boss_knockback", "0", "If bosses can knockback themselves, 2 to also allow self-damaging", _, true, 0.0, true, 2.0);
	CvarCrits = CreateConVar("ff2_boss_crits", "0", "If bosses can perform random crits", _, true, 0.0, true, 1.0);
	CvarHealing = CreateConVar("ff2_boss_healing", "0", "If bosses can be healed by Medics, packs, etc. (Requires DHooks to disable)", _, true, 0.0, true, 1.0);
	CvarSapper = CreateConVar("ff2_boss_sapper", "0", "Add 1 if the boss can be sapped, add 2 if minions can be sapped", _, true, 0.0, true, 3.0);
	CvarSewerSlide = CreateConVar("ff2_boss_suicide", "0", "If bosses can suicide during the round", _, true, 0.0, true, 1.0);
	CvarTeam = CreateConVar("ff2_boss_team", "3", "Default boss team, 4 for random team", _, true, 0.0, true, 4.0);

	AddCommandListener(Bosses_Rage, "voicemenu");
	AddCommandListener(Bosses_KermitSewerSlide, "kill");
	AddCommandListener(Bosses_KermitSewerSlide, "explode");
	AddCommandListener(Bosses_KermitSewerSlide, "spectate");
}

void Bosses_Config(const char[] map)
{
	Specials = 0;
	Charset = 0;
	FirstPlayable = -1;
	LastPlayable = -1;
	for(int i; i<MAXSPECIALS; i++)
	{
		if(Special[i].Cfg != INVALID_HANDLE)
			DeleteCfg(Special[i].Cfg);

		Special[i].Cfg = null;
		Special[i].Charset = -1;
	}

	if(Charsets != INVALID_HANDLE)
		delete Charsets;

	Charsets = new ArrayList(MAX_CHARSET_LENGTH, 0);

	char filepath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, CHARSET_FILE);

	if(!FileExists(filepath))
	{
		Charsets.SetString(0, "Freak Fortress 2");
		BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, CONFIG_PATH);
		if(Enabled <= Game_Disabled)
		{
			Charset = -1;
			CvarCharset.IntValue = -1;
		}
		else
		{
			Charset = 0;
			CvarCharset.IntValue = 0;
		}

		ProcessDirectory(filepath, "", "", 0, map);
		return;
	}

	char config[PLATFORM_MAX_PATH];
	if(Enabled > Game_Disabled)
	{
		Charset = CvarCharset.IntValue;
		if(Charset < 0)
			Charset = 0;

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
		CvarCharset.IntValue = -1;
	}

	ConfigMap cfg = new ConfigMap(filepath);
	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, CONFIG_PATH);

	int charset;
	StringMapSnapshot snap = cfg.Snapshot();

	int entries = snap.Length;
	for(int i; i<entries; i++)
	{
		int length = snap.KeyBufferSize(i)+1;
		char[] buffer = new char[length];
		snap.GetKey(i, buffer, length);
		PackVal val;
		cfg.GetArray(buffer, val, sizeof(val));
		if(val.tag != KeyValType_Section)
			continue;

		val.data.Reset();
		ConfigMap pack = val.data.ReadCell();
		if(pack == null)
			continue;

		StringMapSnapshot snap2 = cfg.Snapshot();
		if(snap2 == null)
			continue;

		int entries2 = snap2.Length;
		if(entries2)
		{
			Charsets.SetString(charset, buffer);
			for(int i2; i2<entries2; i2++)
			{
				length = snap.KeyBufferSize(i2)+1;
				char[] buffer2 = new char[length];
				snap.GetKey(i2, buffer2, length);
				PackVal val2;
				cfg.GetArray(buffer2, val2, sizeof(val2));
				switch(val2.tag)
				{
					case KeyValType_Value:
					{
						val2.data.Reset();
						val2.data.ReadString(config, sizeof(config));
						if(StrContains(config, "*") == -1)
						{
							LoadCharacter(config, charset, map);
						}
						else
						{
							ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
							ProcessDirectory(filepath, "", config, charset, map);
						}
					}
					case KeyValType_Section:
					{
						if(StrContains(buffer2, "*") == -1)
						{
							LoadCharacter(buffer2, charset, map);
						}
						else
						{
							ReplaceString(buffer2, PLATFORM_MAX_PATH, "*", "");
							ProcessDirectory(filepath, "", buffer2, charset, map);
						}
					}
				}
			}
			charset++;
		}
		delete snap2;
	}
	delete snap;

	#if defined FF2_CONVARS
	if(Charset!=-1 && CvarNameChange.IntValue==2)
	{
		Charsets.GetString(Charset, config, sizeof(config));
		Convars_NameSuffix(config);
	}
	#endif
}

static void ProcessDirectory(const char[] base, const char[] current, const char[] matching, int pack, const char[] map)
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

			if(!matching[0] || !StrContains(file, matching))
				LoadCharacter(file, pack, map);

			continue;
		}

		if(type!=FileType_Directory || !StrContains(file, "."))
			continue;

		if(current[0])
			Format(file, PLATFORM_MAX_PATH, "%s/%s", current, file);

		ProcessDirectory(base, file, matching, pack, map);
	}
	delete listing;
}

static void LoadCharacter(const char[] character, int charset, const char[] map)
{
	char config[PLATFORM_MAX_PATH];
	FormatEx(config, sizeof(config), "%s/%s.cfg", CONFIG_PATH, character);
	Special[Specials].Cfg = new ConfigMap(config);
	if(Special[Specials].Cfg == null)
		return;

	ConfigMap cfg = Special[Specials].Cfg.GetSection("character");
	if(cfg == null)
	{
		LogError2("[Boss] %s is not a boss character", character);
		DeleteCfg(Special[Specials].Cfg);
		return;
	}

	int i;
	if(cfg.GetInt("version", i) && i!=StringToInt(MAJOR_REVISION) && i!=99)	// 99 is Unofficial-only bosses
	{
		LogError2("[Boss] %s is only compatible with FF2 v%i", character, i);
		DeleteCfg(Special[Specials].Cfg);
		return;
	}

	if(cfg.GetInt("version_minor", i) && i>StringToInt(MINOR_REVISION))
	{
		int x;
		if(cfg.GetInt("version_stable", x))
		{
			LogError2("[Boss] %s requires newer version of FF2 (at least %s.%i.%i)", character, MAJOR_REVISION, i, x);
		}
		else
		{
			LogError2("[Boss] %s requires newer version of FF2 (at least %s.%i)", character, MAJOR_REVISION, i);
		}
		DeleteCfg(Special[Specials].Cfg);
		return;
	}

	if(cfg.GetInt("version_stable", i) && i>StringToInt(STABLE_REVISION))
	{
		int x;
		if(cfg.GetInt("version_minor", x))
		{
			LogError2("[Boss] %s requires newer version of FF2 (at least %s.%i.%i)", character, MAJOR_REVISION, x, i);
		}
		else
		{
			LogError2("[Boss] %s requires newer version of FF2 (at least %s.%s.%i)", character, MAJOR_REVISION, MINOR_REVISION, i);
		}
		DeleteCfg(Special[Specials].Cfg);
		return;
	}

	if(cfg.GetInt("fversion", i) && i!=StringToInt(MAJOR_REVISION))
	{
		LogError2("[Boss] %s is only compatible with %s FF2 v%i", character, FORK_SUB_REVISION, i);
		DeleteCfg(Special[Specials].Cfg);
		return;
	}

	if(cfg.GetInt("fversion_minor", i) && i>StringToInt(MINOR_REVISION))
	{
		int x;
		if(cfg.GetInt("fversion_stable", x))
		{
			LogError2("[Boss] %s requires newer version of %s FF2 (at least %s.%i.%i)", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, i, x);
		}
		else
		{
			LogError2("[Boss] %s requires newer version of %s FF2 (at least %s.%i)", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, i);
		}
		DeleteCfg(Special[Specials].Cfg);
		return;
	}

	if(cfg.GetInt("fversion_stable", i) && i>StringToInt(FORK_STABLE_REVISION))
	{
		int x;
		if(cfg.GetInt("fversion_minor", x))
		{
			LogError2("[Boss] %s requires newer version of %s FF2 (at least %s.%i.%i)", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, x, i);
		}
		else
		{
			LogError2("[Boss] %s requires newer version of %s FF2 (at least %s.%s.%i)", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, FORK_MINOR_REVISION, i);
		}
		DeleteCfg(Special[Specials].Cfg);
		return;
	}

	if(Charset==charset && Enabled>Game_Disabled)
	{
		ConfigMap cfg2 = cfg.GetSection("map_whitelist");
		if(cfg2 == null)
		{
			cfg2 = cfg.GetSection("map_blacklist");
			if(cfg2 == null)
				cfg2 = cfg.GetSection("map_exclude");

			if(cfg2 != null)
			{
				StringMapSnapshot snap = cfg2.Snapshot();
				if(snap)
				{
					int entries = snap.Length;
					if(entries)
					{
						for(i=0; i<entries; i++)
						{
							int length = snap.KeyBufferSize(i)+1;
							char[] buffer = new char[length];
							snap.GetKey(i, buffer, length);
							PackVal val;
							cfg2.GetArray(buffer, val, sizeof(val));
							if(val.tag==KeyValType_Null || StrContains(map, buffer, false))
								continue;

							Special[Specials].Blocked = true;
							delete snap;
							return;
						}
					}
					delete snap;
				}
			}
		}
		else
		{
			StringMapSnapshot snap = cfg2.Snapshot();
			if(snap)
			{
				int entries = snap.Length;
				if(entries)
				{
					bool found;
					for(i=0; i<entries; i++)
					{
						int length = snap.KeyBufferSize(i)+1;
						char[] buffer = new char[length];
						snap.GetKey(i, buffer, length);
						PackVal val;
						cfg2.GetArray(buffer, val, sizeof(val));
						if(val.tag==KeyValType_Null || StrContains(map, buffer, false))
							continue;

						found = true;
						break;
					}

					if(!found)
					{
						Special[Specials].Blocked = true;
						delete snap;
						return;
					}
				}
				delete snap;
			}
		}

		LastPlayable = Specials;
		if(FirstPlayable == -1)
			FirstPlayable = Specials;

		StringMapSnapshot snap = cfg.Snapshot();
		if(snap)
		{
			int entries = snap.Length;
			if(entries)
			{
				for(i=0; i<entries; i++)
				{
					int length = snap.KeyBufferSize(i)+1;
					char[] buffer = new char[length];
					snap.GetKey(i, buffer, length);
					PackVal val;
					cfg.GetArray(buffer, val, sizeof(val));
					if(val.tag != KeyValType_Section)
						continue;

					SectionType type = GetSectionType(buffer);
					if(type < Section_Download)
						continue;

					val.data.Reset();
					DownloadSection(val.data.ReadCell(), type, character);
				}
			}
			delete snap;
		}
	}

	strcopy(Special[Specials].File, PLATFORM_MAX_PATH, character);
	Specials++;
}

static void DownloadSection(ConfigMap cfg, SectionType type, const char[] character)
{
	StringMapSnapshot snap = cfg.Snapshot();
	if(!snap)
		return;

	int entries = snap.Length;
	if(entries)
	{
		char key[PLATFORM_MAX_PATH];
		for(int i; i<entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] buffer = new char[length];
			snap.GetKey(i, buffer, length);
			PackVal val;
			cfg.GetArray(buffer, val, sizeof(val));
			if(val.tag == KeyValType_Null)
				continue;

			switch(type)
			{
				case Section_Download:
				{
					if(FileExists(buffer, true))
					{
						AddFileToDownloadsTable(buffer);
						continue;
					}

					LogError2("[Boss] %s is missing file '%s' in section 'download'", character, buffer);
				}
				case Section_Model:
				{
					static const char extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy"};
					for(int x=0; x<sizeof(extensions); x++)
					{
						FormatEx(key, sizeof(key), "%s%s", buffer, extensions[x]);
						if(FileExists(key, true))
						{
							AddFileToDownloadsTable(key);
						}
						else if(StrContains(key, ".phy") == -1)
						{
							LogError2("[Boss] %s is missing file '%s' in section 'mod_download'", character, key);
						}
					}
				}
				case Section_Material:
				{
					FormatEx(key, sizeof(key), "%s.vtf", buffer);
					if(FileExists(key, true))
					{
						AddFileToDownloadsTable(key);
					}
					else
					{
						LogError2("[Boss] %s is missing file '%s' in section 'mat_download'", character, key);
					}

					FormatEx(key, sizeof(key), "%s.vmt", buffer);
					if(FileExists(key, true))
					{
						AddFileToDownloadsTable(key);
						continue;
					}

					LogError2("[Boss] %s is missing file '%s' in section 'mat_download'", character, key);
				}
			}
		}
	}
	delete snap;
}

void Bosses_Create(int client, int team)
{
	ConfigMap cfg = Special[Boss[client].Special].Cfg.GetSection("character");

	int i;
	Boss[client].Triple = cfg.GetInt("triple", i) ? view_as<bool>(i) : CvarTriple.BoolValue;
	Boss[client].Crits = cfg.GetInt("crits", i) ? view_as<bool>(i) : CvarCrits.BoolValue;
	Boss[client].Healing = cfg.GetInt("healing", i) ? view_as<bool>(i) : CvarHealing.BoolValue;
	Boss[client].Knockback = cfg.GetInt("knockback", i) ? i : cfg.GetInt("rocketjump", i) ? i : CvarKnockback.IntValue;

	Boss[client].Voice = cfg.GetInt("sound_block_vo", i) ? !i : true;
	Boss[client].RageMode = cfg.GetInt("ragemode", i) ? view_as<bool>(i) : false;

	if(!cfg.GetInt("sapper", i))
		i = CvarSapper.IntValue;

	Boss[client].Sapper = (i==1 || i>2);

	if(cfg.GetInt("pickups", i))
	{
		Boss[client].HealthKits = (i==1 || i>2);
		Boss[client].AmmoKits = i>1;
	}
	else
	{
		Boss[client].HealthKits = false;
		Boss[client].AmmoKits = false;
	}

	float f;
	Boss[client].RageMax = cfg.GetFloat("ragemax", f) ? f : 100.0;
	Boss[client].RageMin = cfg.GetFloat("ragemin", f) ? f : 100.0;
	Boss[client].MaxSpeed = cfg.GetFloat("maxspeed", f) ? f : 340.0;

	Boss[client].Killstreak = 0;
	Boss[client].RPSHealth = 0;
	Boss[client].RPSCount = 0;
	Boss[client].Charge[0] = 0.0;
	Boss[client].Hazard = 0.0;

	Bosses_Prepare(Boss[client].Special);

	bool nonLeader;
	for(int target=1; target<=MaxClients; target++)
	{
		if(!Boss[target].Active || !Boss[target].Leader)
			continue;

		nonLeader = true;
		break;
	}

	Client[client].Team = cfg.GetInt("bossteam", i) ? i : view_as<int>(TFTeam_Unassigned);
	if(Client[client].Team<view_as<int>(TFTeam_Spectator) || Client[client].Team>view_as<int>(TFTeam_Blue))
	{
		if(!cfg.GetInt("team", i) || i<0)
		{
			if(team == 4)
			{
				Client[client].Team = GetRandomInt(0, 1) ? view_as<int>(TFTeam_Red) : view_as<int>(TFTeam_Blue);
			}
			else
			{
				Client[client].Team = team;
			}
		}
		else if(i > 3)
		{
			Client[client].Team = GetRandomInt(0, 1) ? view_as<int>(TFTeam_Red) : view_as<int>(TFTeam_Blue);
		}
		else
		{
			Client[client].Team = i;
		}
	}
	else if(Client[client].Team == view_as<int>(TFTeam_Spectator))
	{
		Client[client].Team = GetRandomInt(0, 1) ? view_as<int>(TFTeam_Red) : view_as<int>(TFTeam_Blue);
	}

	if(nonLeader)
	{
		Boss[client].Leader = false;
	}
	else
	{
		BossTeam = Client[client].Team;
		Boss[client].Leader = true;
	}
}

void Bosses_Prepare(int boss)
{
	if(Special[boss].Precached)
		return;

	ConfigMap cfg = Special[boss].Cfg.GetSection("character");

	char file[PLATFORM_MAX_PATH];
	if(cfg.Get("model", file, sizeof(file)))
	{
		if(FileExists(file, true))
		{
			PrecacheModel(file);
		}
		else
		{
			LogError2("[Boss] %s is missing file '%s' in 'model'", Special[boss].File, file);
		}
	}

	Special[boss].Precached = true;
	StringMapSnapshot snap = cfg.Snapshot();
	if(!snap)
		return;

	int entries = snap.Length;
	if(entries)
	{
		for(int i; i<entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] buffer = new char[length];
			snap.GetKey(i, buffer, length);
			PackVal val;
			cfg.GetArray(buffer, val, sizeof(val));
			if(val.tag == KeyValType_Null)
				continue;

			SectionType type = GetSectionType(buffer);
			if(type!=Section_Sound && type!=Section_Precache)
				continue;

			val.data.Reset();
			ConfigMap sec = val.data.ReadCell();
			if(sec == null)
				continue;

			StringMapSnapshot snap2 = sec.Snapshot();
			if(!snap2)
				continue;

			int entries2 = snap2.Length;
			if(entries2)
			{
				for(int i2; i2<entries; i2++)
				{
					int length2 = snap2.KeyBufferSize(i2)+1;
					char[] buffer2 = new char[length2];
					snap2.GetKey(i2, buffer2, length2);
					PackVal val2;
					sec.GetArray(buffer2, val2, sizeof(val2));
					if(val2.tag == KeyValType_Null)
						continue;

					if(type == Section_Sound)
					{
						FormatEx(file, sizeof(file), "sound/%s", buffer2);
						if(FileExists(file, true))
						{
							PrecacheSound(buffer2);
							continue;
						}

						LogError2("[Boss] %s is missing file '%s' in section '%s'", Special[boss].File, file, buffer);
					}

					if(FileExists(buffer2, true))
					{
						PrecacheModel(buffer2);
						continue;
					}

					LogError2("[Boss] %s is missing file '%s' in section '%s'", Special[boss].File, buffer2, buffer);
				}
			}
			delete snap2;
		}
	}
	delete snap;
}

void Bosses_SetHealth(int client)
{
	ConfigMap cfg = Special[Boss[client].Special].Cfg.GetSection("character");

	static char buffer[1024];
	if(cfg.Get("ragedamage", buffer, sizeof(buffer)))
	{
		#if defined FF2_TIMESTEN
		Boss[client].RageDamage = RoundFloat(ParseFormula(buffer, Players)*TimesTen_Value());
		#else
		Boss[client].RageDamage = RoundFloat(ParseFormula(buffer, Players));
		#endif
	}
	else
	{
		Boss[client].RageDamage = RoundFloat(DEFAULT_RAGEDAMAGE);
	}

	int i;
	if(cfg.GetInt("lives", i))
	{
		if(i > 1)
		{
			Boss[client].Lives = i;
		}
		else
		{
			Boss[client].Lives = 1;
		}
	}
	else
	{
		Boss[client].Lives = 1;
	}

	Boss[client].MaxLives = Boss[client].Lives;
	if(cfg.Get("health_formula", buffer, sizeof(buffer)))
	{
		#if defined FF2_TIMESTEN
		Boss[client].MaxHealth = RoundFloat(ParseFormula(buffer, Players)*TimesTen_Value());
		#else
		Boss[client].MaxHealth = RoundFloat(ParseFormula(buffer, Players));
		#endif

		if(Boss[client].MaxHealth < 1)
			#if defined FF2_TIMESTEN
			Boss[client].MaxHealth = RoundFloat(DEFAULT_HEALTH*TimesTen_Value());
			#else
			Boss[client].MaxHealth = RoundFloat(DEFAULT_HEALTH);
			#endif
	}
	else
	{
		#if defined FF2_TIMESTEN
		Boss[client].MaxHealth = RoundFloat(DEFAULT_HEALTH*TimesTen_Value());
		#else
		Boss[client].MaxHealth = RoundFloat(DEFAULT_HEALTH);
		#endif
	}

	Boss[client].Health = Boss[client].MaxHealth*Boss[client].Lives;
}

void Bosses_Equip(int client)
{
	ConfigMap cfg = Special[Boss[client].Special].Cfg.GetSection("character");

	Boss[client].Class = CfgGetClass(cfg, "class");

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	TF2_RemovePlayerDisguise(client);
	TF2_SetPlayerClass(client, Boss[client].Class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);

	RequestFrame(Bosses_Model, GetClientUserId(client));

	int i;
	Boss[client].Cosmetics = (cfg.GetInt("cosmetics", i) && i);
	i = MaxClients+1;
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

	i = MaxClients+1;
	while((i=FindEntityByClassname2(i, "tf_powerup_bottle")) != -1)
	{
		if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
			TF2_RemoveWearable(client, i);
	}

	TF2_RemoveAllWeapons(client);
	StringMapSnapshot snap = cfg.Snapshot();
	if(!snap)
		return;

	int entries = snap.Length;
	if(entries)
	{
		bool first;
		char attributes[PLATFORM_MAX_PATH];
		for(i=0; i<entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] buffer = new char[length];
			snap.GetKey(i, buffer, length);
			PackVal val;
			cfg.GetArray(buffer, val, sizeof(val));
			if(val.tag!=KeyValType_Section || GetSectionType(buffer)!=Section_Weapon)
				continue;

			val.data.Reset();
			ConfigMap wep = val.data.ReadCell();
			if(wep == null)
				continue;

			bool wearable;
			static char classname[MAX_CLASSNAME_LENGTH];
			if(StrContains(buffer, "tf_") && !StrEqual(buffer, "saxxy"))
			{
				if(StrContains(buffer, "weapon"))
				{
					if(StrContains(buffer, "wearable"))
						continue;

					wearable = true;
				}

				if(!wep.Get("name", classname, sizeof(classname)))
					strcopy(classname, sizeof(classname), wearable ? "tf_wearable" : "saxxy");
			}
			else
			{
				strcopy(classname, sizeof(classname), buffer);
			}

			MultiClassname(TF2_GetPlayerClass(client), classname, sizeof(classname));
			wearable = view_as<bool>(StrContains(classname, "tf_weap"));

			if(wearable && SDKEquipWearable==null)
				continue;

			int index;
			wep.GetInt("index", index);

			int level = -1;
			wep.GetInt("level", level);

			int quality = 5;
			wep.GetInt("quality", quality);

			bool override = (wep.GetInt("override", length) && length);

			int rank = (level==-1 || override) ? -1 : 21;
			wep.GetInt("rank", rank);

			int kills = rank>=0 ? GetRankingKills(rank, index, wearable) : -1;

			if(level < 0)
				level = 101;

			if(kills >= 0)
			{
				if(wep.Get("attributes", attributes, sizeof(attributes)))
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
				if(wep.Get("attributes", attributes, sizeof(attributes)))
				{
					Format(attributes, sizeof(attributes), "%s ; %s", DEFAULT_ATTRIBUTES, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, attributes);
				}
				else
				{
					FormatEx(attributes, sizeof(attributes), DEFAULT_ATTRIBUTES, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);
				}
			}
			else if(!wep.Get("attributes", attributes, sizeof(attributes)))
			{
				attributes[0] = 0;
			}

			#if defined FF2_TF2ITEMS
			index = (TF2Items && !wearable) ? TF2Items_SpawnWeapon(client, classname, index, level, quality, attributes) : SDK_SpawnWeapon(client, classname, index, level, quality, attributes);
			#else
			index = SDK_SpawnWeapon(client, classname, index, level, quality, attributes);
			#endif
			if(index == -1)
				continue;

			if(!wearable)
			{
				level = -1;
				kills = -1;
				if(wep.GetInt("ammo", level) || wep.GetInt("clip", kills))
					FF2_SetAmmo(client, index, level, kills);
	
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

			level = wearable ? 1 : 0;
			wep.GetInt("show", level);
			if(level)
			{
				if(wep.Get("worldmodel", attributes, sizeof(attributes)))
					ConfigureWorldModelOverride(index, attributes, wearable);

				SetEntProp(index, Prop_Send, "m_bValidatedAttachedEntity", 1);
			}
			else
			{
				SetEntProp(index, Prop_Send, "m_bValidatedAttachedEntity", 0);
				SetEntPropFloat(index, Prop_Send, "m_flModelScale", 0.001);
				//SetEntProp(index, Prop_Send, "m_iWorldModelIndex", -1);
				//SetEntProp(index, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
			}

			int rgba[4] = {255, 255, 255, 255};
			override = view_as<bool>(wep.GetInt("alpha", rgba[0]));
			override = (wep.GetInt("red", rgba[1]) || override);
			override = (wep.GetInt("green", rgba[2]) || override);
			override = (wep.GetInt("blue", rgba[3]) || override);
			if(override)
			{
				SetEntityRenderMode(index, RENDER_TRANSCOLOR);
				SetEntityRenderColor(index, rgba[1], rgba[2], rgba[3], rgba[0]);
			}

			if(wearable || first)
				continue;

			first = true;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", index);
		}
	}
	delete snap;
}

public void Bosses_Model(int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !Boss[client].Active)
		return;

	static char buffer[PLATFORM_MAX_PATH];
	if(!Special[Boss[client].Special].Cfg.Get("character.model", buffer, sizeof(buffer)))
		return;

	SetVariantString(buffer);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

public Action Bosses_Rage(int client, const char[] command, int args)
{
	if(!Boss[client].Active || Boss[client].RageDamage>99998 || Boss[client].RageMode==RageMode_None || Boss[client].RageMin>Boss[client].Charge[0] || !IsPlayerAlive(client) || CheckRoundState()!=1)
		return Plugin_Continue;

	static char arg[4];
	GetCmdArgString(arg, sizeof(arg));
	if(!StrEqual(arg, "0 0"))
		return Plugin_Continue;

	Bosses_AbilitySlot(client, 0);
	if(Boss[client].RageMode == RageMode_Full)
	{
		Boss[client].Charge[0] = 0.0;
	}
	else if(Boss[client].RageMode == RageMode_Part)
	{
		Boss[client].Charge[0] -= Boss[client].RageMin;
	}

	if(!PlayBossSound(client, "sound_ability_serverwide", 1, "0"))
		PlayBossSound(client, "sound_ability", 0, "0");

	return Plugin_Handled;
}

public Action Bosses_KermitSewerSlide(int client, const char[] command, int args)
{
	if(!Boss[client].Active)
		return Plugin_Continue;

	int roundState = CheckRoundState();
	if(roundState == 2)
		return Plugin_Continue;

	if(roundState == 1)
	{
		if(CvarSewerSlide.BoolValue)
			return Plugin_Continue;

		FPrintToChat(client, "%t", "Boss Suicide");
	}
	else
	{
		FPrintToChat(client, "%t", CvarSewerSlide.BoolValue ? "Boss Suicide Pre" : "Boss Suicide");
	}
	return Plugin_Handled;
}

public Action Bosses_JoinClass(int client, const char[] command, int args)
{
	if(!Boss[client].Active || CheckRoundState()!=1)
		return Plugin_Continue;

	static char class[16];
	GetCmdArg(1, class, sizeof(class));
	if(TF2_GetClass(class) != TFClass_Unknown)
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetClass(class));

	return Plugin_Handled;
}

void Bosses_AbilitySlot(int client, int slot)
{
	ConfigMap character = Special[Boss[client].Special].Cfg.GetSection("character");
	StringMapSnapshot snap = character.Snapshot();
	if(!snap)
		return;

	int entries = snap.Length;
	if(entries)
	{
		for(int i; i<entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] buffer = new char[length];
			snap.GetKey(i, buffer, length);
			PackVal val;
			character.GetArray(buffer, val, sizeof(val));
			if(val.tag!=KeyValType_Section || GetSectionType(buffer)!=Section_Ability)
				continue;

			val.data.Reset();
			ConfigMap cfg = val.data.ReadCell();
			if(cfg == null)
				continue;

			int count;
			if(!cfg.GetInt("slot", count))
				cfg.GetInt("arg0", count);

			if(count != slot)
				continue;

			static char ability[64];
			if(StrContains(buffer, "ability"))
			{
				strcopy(ability, sizeof(ability), buffer);
			}
			else if(!cfg.Get("name", ability, sizeof(ability)))
			{
				continue;
			}

			static char plugin[64];
			if(cfg.Get("life", plugin, sizeof(plugin)))
			{
				bool found;
				static char lives[8][4];
				count = ExplodeString(plugin, " ", lives, sizeof(lives), sizeof(lives[]));
				for(length=0; length<count; length++)
				{
					if(StringToInt(lives[length]) != Boss[client].Lives)
						continue;

					found = true;
					break;
				}

				if(!found)
					continue;
			}

			if(!cfg.Get("plugin_name", plugin, sizeof(plugin)))
				plugin[0] = 0;

			Bosses_Ability(client, ability, plugin, slot, cfg.GetInt("buttonmode", count) ? count : 0);
		}
	}
	delete snap;
}

void Bosses_Ability(int client, const char[] ability, const char[] plugin, int slot, int buttonMode)
{
	bool enabled = true;
	Call_StartForward(PreAbility);
	Call_PushCell(Boss[client].Leader ? 0 : client);
	Call_PushString(plugin);
	Call_PushString(ability);
	Call_PushCell(slot);
	Call_PushCellRef(enabled);
	Call_Finish();

	if(!enabled)
		return;

	Action action = Plugin_Continue;
	Call_StartForward(OnAbility);
	Call_PushCell(Boss[client].Leader ? 0 : client);
	Call_PushString(plugin);
	Call_PushString(ability);
	if(slot<=0 || slot>3)
	{
		Call_PushCell(3);
		Call_PushCell(client);
		Call_Finish(action);
		return;
	}

	SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
	int button;
	switch(buttonMode)
	{
		case 1:
			button = IN_DUCK|IN_ATTACK2;

		case 2:
			button = IN_RELOAD;

		case 3:
			button = IN_ATTACK3;

		case 4:
			button = IN_DUCK;

		case 5:
			button = IN_SCORE;

		default:
			button = IN_ATTACK2;
	}

	if(GetClientButtons(client) & button)
	{
		if(Boss[client].Charge[slot] >= 0.0)
		{
			Call_PushCell(2);
			Call_PushCell(client);
			Call_Finish(action);

			float charge = 20.0/Bosses_ArgF(client, ability, plugin, "charge time", 1, 1.5);
			if(Boss[client].Charge[slot]+charge < 100.0)
			{
				Boss[client].Charge[slot] += charge;
			}
			else
			{
				Boss[client].Charge[slot] = 100.0;
			}
		}
		else
		{
			Call_PushCell(1);  //Status
			Call_PushCell(client);
			Call_Finish(action);
			Boss[client].Charge[slot] += 0.2;
		}
		return;
	}

	if(Boss[client].Charge[slot] > 0.3)
	{
		float angles[3];
		GetClientEyeAngles(client, angles);
		if(angles[0] < -30.0)
		{
			Call_PushCell(3);
			Call_PushCell(client);
			Call_Finish(action);

			DataPack data;
			CreateDataTimer(0.1, Bosses_UseBossCharge, data);
			data.WriteCell(GetClientUserId(client));
			data.WriteCell(slot);
			data.WriteFloat(-1.0*Bosses_ArgF(client, ability, plugin, "cooldown", 2, 5.0));
		}
		else
		{
			Call_PushCell(0);
			Call_PushCell(client);
			Call_Finish(action);
			Boss[client].Charge[slot] = 0.0;
		}
		return;
	}

	if(Boss[client].Charge[slot] < 0.0)
	{
		Call_PushCell(1);
		Call_PushCell(client);
		Call_Finish(action);
		Boss[client].Charge[slot] += 0.2;
		return;
	}

	Call_PushCell(0);
	Call_PushCell(client);
	Call_Finish(action);
}

public Action Bosses_UseBossCharge(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	if(IsValidClient(client))
		Boss[client].Charge[data.ReadCell()] = data.ReadFloat();

	return Plugin_Continue;
}

int Bosses_ArgI(int client, const char[] ability, const char[] plugin, const char[] arg="", int index=-1, int defaul=0)
{
	ConfigMap character = Special[Boss[client].Special].Cfg.GetSection("character");
	StringMapSnapshot snap = character.Snapshot();
	if(!snap)
		return defaul;

	int entries = snap.Length;
	if(!entries)
	{
		delete snap;
		return defaul;
	}

	char buffer2[64];
	for(int i; i<entries; i++)
	{
		int length = snap.KeyBufferSize(i)+1;
		char[] buffer = new char[length];
		snap.GetKey(i, buffer, length);
		PackVal val;
		character.GetArray(buffer, val, sizeof(val));
		if(val.tag != KeyValType_Section)
			continue;

		if(GetSectionType(buffer) != Section_Ability)
			continue;

		val.data.Reset();
		ConfigMap cfg = val.data.ReadCell();
		if(cfg == null)
			continue;

		if(!StrContains(buffer, "ability"))
		{
			if(!cfg.Get("name", buffer2, sizeof(buffer2)) || !StrEqual(ability, buffer2, false))
				continue;
		}
		else if(!StrEqual(ability, buffer, false))
		{
			continue;
		}

		if(plugin[0] && cfg.Get("plugin_name", buffer2, sizeof(buffer2)) && !StrEqual(plugin, buffer2, false))
			continue;

		delete snap;

		i = defaul;
		if((!arg[0] || !cfg.GetInt(arg, i)) && index>=0)
		{
			FormatEx(buffer2, sizeof(buffer2), "arg%d", index);
			cfg.GetInt(buffer2, i);
		}
		return i;
	}

	delete snap;
	return defaul;
}

float Bosses_ArgF(int client, const char[] ability, const char[] plugin, const char[] arg="", int index=-1, float defaul=0.0)
{
	ConfigMap character = Special[Boss[client].Special].Cfg.GetSection("character");
	StringMapSnapshot snap = character.Snapshot();
	if(!snap)
		return defaul;

	int entries = snap.Length;
	if(!entries)
	{
		delete snap;
		return defaul;
	}

	char buffer2[64];
	for(int i; i<entries; i++)
	{
		int length = snap.KeyBufferSize(i)+1;
		char[] buffer = new char[length];
		snap.GetKey(i, buffer, length);
		PackVal val;
		character.GetArray(buffer, val, sizeof(val));
		if(val.tag != KeyValType_Section)
			continue;

		if(GetSectionType(buffer) != Section_Ability)
			continue;

		val.data.Reset();
		ConfigMap cfg = val.data.ReadCell();
		if(cfg == null)
			continue;

		if(!StrContains(buffer, "ability"))
		{
			if(!cfg.Get("name", buffer2, sizeof(buffer2)) || !StrEqual(ability, buffer2, false))
				continue;
		}
		else if(!StrEqual(ability, buffer, false))
		{
			continue;
		}

		if(plugin[0] && cfg.Get("plugin_name", buffer2, sizeof(buffer2)) && !StrEqual(plugin, buffer2, false))
			continue;

		delete snap;

		float value = defaul;
		if((!arg[0] || !cfg.GetFloat(arg, value)) && index>=0)
		{
			FormatEx(buffer2, sizeof(buffer2), "arg%d", index);
			cfg.GetFloat(buffer2, value);
		}
		return value;
	}

	delete snap;
	return defaul;
}

bool Bosses_ArgS(int client, const char[] ability, const char[] plugin, const char[] arg="", int index=-1, char[] buffer, int length)
{
	ConfigMap character = Special[Boss[client].Special].Cfg.GetSection("character");
	StringMapSnapshot snap = character.Snapshot();
	if(!snap)
		return false;

	int entries = snap.Length;
	if(!entries)
	{
		delete snap;
		return false;
	}

	char buffer3[64];
	for(int i; i<entries; i++)
	{
		int length2 = snap.KeyBufferSize(i)+1;
		char[] buffer2 = new char[length2];
		snap.GetKey(i, buffer2, length2);
		PackVal val;
		character.GetArray(buffer2, val, sizeof(val));
		if(val.tag != KeyValType_Section)
			continue;

		if(GetSectionType(buffer2) != Section_Ability)
			continue;

		val.data.Reset();
		ConfigMap cfg = val.data.ReadCell();
		if(cfg == null)
			continue;

		if(!StrContains(buffer2, "ability"))
		{
			if(!cfg.Get("name", buffer3, sizeof(buffer3)) || !StrEqual(ability, buffer3, false))
				continue;
		}
		else if(!StrEqual(ability, buffer2, false))
		{
			continue;
		}

		if(plugin[0] && cfg.Get("plugin_name", buffer3, sizeof(buffer3)) && !StrEqual(plugin, buffer3, false))
			continue;

		delete snap;
		if(arg[0] && cfg.Get(arg, buffer, length))
			return true;

		if(index < 0)
			return false;

		FormatEx(buffer3, sizeof(buffer3), "arg%d", index);
		return view_as<bool>(cfg.Get(buffer3, buffer, length));
	}

	delete snap;
	return false;
}

/*KeyValues Bosses_ArgK(int client, const char[] ability, const char[] plugin)
{
	Special[Boss[client].Special].Kv.Rewind();
	Special[Boss[client].Special].Kv.GotoFirstSubKey();
	do
	{
		if(KvGetSectionType(Special[Boss[client].Special].Kv, buffer, length != Section_Ability))
			continue;

		if(!StrContains(buffer, "ability"))
		{
			Special[Boss[client].Special].Kv.GetString("name", buffer, length);
			continue;
		}

		if(plugin[0])
		{
			Special[Boss[client].Special].Kv.GetString("plugin_name", buffer, length);
			if(buffer[0] && !StrEqual(plugin, buffer))
				continue;
		}

		return Special[Boss[client].Special].Kv;
	} while(Special[Boss[client].Special].Kv.GotoNextKey());
	return view_as<KeyValues>(INVALID_HANDLE);
}*/

ConfigMap Bosses_ArgC(int client, const char[] ability, const char[] plugin)
{
	ConfigMap character = Special[Boss[client].Special].Cfg.GetSection("character");
	StringMapSnapshot snap = character.Snapshot();
	if(!snap)
		return null;

	int entries = snap.Length;
	if(!entries)
	{
		delete snap;
		return null;
	}

	for(int i; i<entries; i++)
	{
		int length = snap.KeyBufferSize(i)+1;
		char[] buffer = new char[length];
		snap.GetKey(i, buffer, length);
		PackVal val;
		character.GetArray(buffer, val, sizeof(val));
		if(val.tag != KeyValType_Section)
			continue;

		if(GetSectionType(buffer, length) != Section_Ability)
			continue;

		val.data.Reset();
		ConfigMap cfg = val.data.ReadCell();
		if(cfg == null)
			continue;

		static char buffer2[64];
		if(!StrContains(buffer, "ability"))
		{
			if(!cfg.Get("name", buffer2, sizeof(buffer2)) || !StrEqual(ability, buffer2, false))
				continue;
		}
		else if(!StrEqual(ability, buffer, false))
		{
			continue;
		}

		if(plugin[0] && cfg.Get("plugin_name", buffer2, sizeof(buffer2)) && !StrEqual(plugin, buffer2, false))
			continue;

		delete snap;
		return cfg;
	}

	delete snap;
	return null;
}

// Type | 0: Leader Boss, 1: Companion Boss, 2: Other Boss
int Bosses_GetSpecial(int client, int selection, int type)
{
	Action action;
	Call_StartForward(OnSpecialSelected);
	Call_PushCell(type ? client : 0);
	int boss = selection;
	Call_PushCellRef(boss);
	char buffer[64];
	Special[selection].Cfg.Get("character.name", buffer, sizeof(buffer));
	Call_PushStringEx(buffer, sizeof(buffer), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(type!=1);
	Call_Finish(action);
	if(action == Plugin_Changed)
	{
		if(buffer[0])
		{
			int found = GetMatchingBoss(buffer);
			if(found != -1)
				boss = found;
		}
		else if(boss < -1)
		{
			boss = -1;
		}
		return boss;
	}

	if(action != Plugin_Continue)
		return -1;

	if(type == 1)
		return selection;

	if(selection >= 0)
	{
		if(Special[selection].Charset==Charset && CheckBossAccess(client, selection)==1)
			return selection;
	}

	ArrayList list = new ArrayList();
	for(boss=0; boss<Specials; boss++)
	{
		if(Special[selection].Charset==Charset && CheckBossAccess(client, selection)>=0)
			list.Push(boss);
	}

	boss = list.Length;
	if(boss < 1)
	{
		delete list;
		return -1;
	}

	boss = list.Get(GetRandomInt(0, boss-1));
	delete list;
	return boss;
}

void Bosses_CheckCompanion(int boss, int team)
{
	static char buffer[64];
	if(!Special[boss].Cfg.Get("character.companion", buffer, sizeof(buffer)))
		return;

	int companion = GetMatchingBoss(buffer);
	if(companion == -1)
	{
		LogError2("[Boss] %s has unknown companion '%s'", Special[boss].File, buffer);
		return;
	}

	int client = GetRandBossClient(companion);
	if(!client)
		return;

	companion = Bosses_GetSpecial(client, companion, 1);
	if(companion == -1)
		return;

	Boss[client].Special = companion;
	Boss[client].Active = true;
	Bosses_Create(client, team);
	Bosses_CheckCompanion(companion, team);
}

static int GetRankingKills(int rank, int index, bool wearable)
{
	switch(rank)
	{
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
}
