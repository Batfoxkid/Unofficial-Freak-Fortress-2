/*
	Requirement:
	sdkhooks.sp

	Optional:
	tf2items.sp
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
	int Charset;
	KeyValues Kv;
}

BossEnum Boss[MAXSPECIALS];
ArrayList BossRand;
int Specials;

ArrayList Charset;

void Bosses_Setup()
{
	Specials = 0;
	for(int i; i<MAXSPECIALS; i++)
	{
		Boss[i].Kv = null;
		Boss[i].Charset = -1;
	}

	if(Charset == INVALID_HANDLE)
	{
		Charset = new ArrayList(MAX_CHARSET_LENGTH, 0);
	}
	else
	{
		Charset.Clear();
	}

	char filepath[PLATFORM_MAX_PATH], config[PLATFORM_MAX_PATH], key[4], charset[42];
	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, CHARSET_PATH);

	if(!FileExists(filepath))
	{
		Charset.SetString(0, "Freak Fortress 2");
		BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, CONFIG_PATH);
		ProcessDirectory(filepath, "", "", 0);
	}

	KeyValues Kv = new KeyValues("");
	Kv.ImportFromFile(filepath);
	int i = cvarCharset.IntValue;
	for(i=0; i<FF2CharSet; i++)
	{
		if(!Kv.GotoNextKey())
			break;
	}

	CurrentCharSet = i;
	Kv.GetSectionName(CharSetString[CurrentCharSet], sizeof(CharSetString[]));

	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, ConfigPath);
	Kv.GetString("1", config, PLATFORM_MAX_PATH);
	if(config[0])
	{
		for(i=1; Specials<MAXSPECIALS && i<=MAXSPECIALS; i++)
		{
			IntToString(i, key, sizeof(key));
			Kv.GetString(key, config, PLATFORM_MAX_PATH);
			if(!config[0])
				continue;

			if(StrContains(config, "*") >= 0)
			{
				ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
				ProcessDirectory(filepath, "", config, -1);
				continue;
			}
			LoadCharacter(config);
		}
	}
	else
	{
		Kv.GotoFirstSubKey();
		do
		{
			Kv.GetSectionName(config, PLATFORM_MAX_PATH);
			if(!config[0])
				break;

			if(StrContains(config, "*") >= 0)
			{
				ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
				ProcessDirectory(filepath, "", config, -1);
				continue;
			}
			LoadCharacter(config);
		} while(Kv.GotoNextKey() && Specials<MAXSPECIALS);
		KvGoBack(Kv);
	}

	// Check if the current charset is not the first
	// one or if there's a charset after this one
	HasCharSets = CurrentCharSet>0;
	if(!HasCharSets)
		HasCharSets = Kv.GotoNextKey();

	delete Kv;

	int amount;
	if(HasCharSets)
	{
		if(cvarNameChange.IntValue == 2)
		{
			char newName[256];
			FormatEx(newName, 256, "%s | %s", oldName, CharSetString[CurrentCharSet]);
			hostName.SetString(newName);
		}

		// KvRewind, you son of a-
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);
		Kv = CreateKeyValues("");
		FileToKeyValues(Kv, config);
		do
		{
			if(amount == CurrentCharSet)	// Skip the current pack
			{
				amount++;
				continue;
			}

			Kv.GetSectionName(CharSetString[amount], sizeof(CharSetString[]));
			Kv.GetString("1", config, PLATFORM_MAX_PATH);
			if(config[0])
			{
				for(i=1; PackSpecials[amount]<MAXSPECIALS && i<=MAXSPECIALS; i++)
				{
					IntToString(i, key, sizeof(key));
					Kv.GetString(key, config, PLATFORM_MAX_PATH);
					if(!config[0])
						continue;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				}
			}
			else
			{
				Kv.GotoFirstSubKey();
				do
				{
					Kv.GetSectionName(config, PLATFORM_MAX_PATH);
					if(!config[0])
						break;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				} while(Kv.GotoNextKey() && PackSpecials[amount]<MAXSPECIALS);
				Kv.GoBack();
			}
			amount++;
		} while(amount<MAXCHARSETS && Kv.GotoNextKey());

		delete Kv;
	}

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

static void ProcessDirectory(const char[] base, const char[] current, const char[] matching, int pack)
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
				LoadCharacter(file, pack);

			continue;
		}

		if(type!=FileType_Directory || !StrContains(file, "."))
			continue;

		if(current[0])
			Format(file, PLATFORM_MAX_PATH, "%s/%s", current, file);

		ProcessDirectory(base, file, matching, pack);
	}
	delete listing;
}

void Bosses_Equip(int client, int boss)
{
	TF2_RemoveAllWeapons(client);
	BossKV[boss].Rewind();
	BossKV[boss].GotoFirstSubKey();
	char attributes[256];
	do
	{
		static char classname[MAX_CLASSNAME_LENGTH];
		if(!BossKV[boss].GetSectionName(classname, sizeof(classname))
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

			BossKV[boss].GetString("name", classname, sizeof(classname), wearable ? "tf_wearable" : "saxxy");
		}
		else
		{
			wearable = view_as<bool>(StrContains(classname, "tf_weap"));
		}

		if(wearable && SDKEquipWearable==null)
			continue;

		int index = BossKV[boss].GetNum("index");
		int level = BossKV[boss].GetNum("level", -1);
		bool override = view_as<bool>(BossKV[boss].GetNum("override"));
		int rank = BossKV[boss].GetNum("rank", (level==-1 || override) ? -1 : 21);
		int kills = GetRankingKills(rank, index, wearable);

		if(level < 0)
			level = 101;

		BossKV[boss].GetString("attributes", attributes, sizeof(attributes));
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
		index = (TF2Items && !wearable) ? TF2Items_SpawnWeapon(client, classname, index, level, BossKV[boss].GetNum("quality", 5), attributes) : SDK_SpawnWeapon(client, classname, index, level, BossKV[boss].GetNum("quality", 5), attributes);
		#else
		index = SDK_SpawnWeapon(client, classname, index, level, BossKV[boss].GetNum("quality", 5), attributes);
		#endif
		if(index == -1)
			continue;

		if(!wearable)
		{
			FF2_SetAmmo(client, index, BossKV[boss].GetNum("ammo", -1), BossKV[boss].GetNum("clip", -1));
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

		if(BossKV[boss].GetNum("show", wearable ? 1 : 0))
		{
			BossKV[boss].GetString("worldmodel", attributes, sizeof(attributes));
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
		rgba[0] = BossKV[boss].GetNum("alpha", 255);
		rgba[1] = BossKV[boss].GetNum("red", 255);
		rgba[2] = BossKV[boss].GetNum("green", 255);
		rgba[3] = BossKV[boss].GetNum("blue", 255);

		for(level=0; level<4; level++)
		{
			if(rgba[level] == 255)
				continue;

			SetEntityRenderMode(index, RENDER_TRANSCOLOR);
			SetEntityRenderColor(index, rgba[1], rgba[2], rgba[3], rgba[0]);
			break;
		}

		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", index);
	} while(BossKV[boss].GotoNextKey());
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
