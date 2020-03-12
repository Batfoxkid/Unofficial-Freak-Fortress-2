/*
	Top Module
*/

#define FF2_WEAPONS

#define WEAPON_CONFIG		"data/freak_fortress_2/weapons.cfg"

KeyValues WeaponKV;

void Weapons_Setup()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), WEAPON_CONFIG);
	if(!FileExists(config))
	{
		LogError2("[Weapons] Could not find '%s'!", WEAPON_CONFIG);
		WeaponKV = null;
		return;
	}

	WeaponKV = CreateKeyValues("Weapons");
	if(WeaponKV.ImportFromFile(config))
		return;

	LogError2("[Weapons] '%s' is improperly formatted!", WEAPON_CONFIG);
	WeaponKV = null;
}

void Weapons_Check(int client)
{
	WeaponKV.Rewind();
	WeaponKv.GotoFirstSubKey();
	do
	{
		static char attrib[256];
		if(!WeaponKv.GetSectionName(attrib, sizeof(attrib))
			continue;

		static char names[8][MAX_CLASSNAME_LENGTH];
		int num = ExplodeString(attrib, " ; ", names, sizeof(names), sizeof(names[]));
		bool mode;
		for(int i; i<num; i++)
		{
			if(StrContains(names[i], "tf_") == -1)
			{
				for(int a; a<6; a++)
				{
					if(StringToInt(names[i]) != index)
						continue;

					mode = true;
					break;
				}

				if(mode)
					break;

				continue;
			}

			if(StrContains(names[i], "*") == -1)
			{
				if(!StrEqual(names[i], classname))
					continue;

				mode = true;
				break;
			}

			bool full = ReplaceString(names[i], 36, "*", "")>1;
			if((full && StrContains(names[i], classname)==-1) || (!full && !StrContains(names[i], classname)))
				continue;

			mode = true;
			break;
		}

		if(!mode)
			continue;
	}
}
