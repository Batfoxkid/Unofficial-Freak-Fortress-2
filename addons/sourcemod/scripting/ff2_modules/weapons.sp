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
	if(WeaponKV == null)
		return;

	static int indexes[6];
	static char classnames[6][MAX_CLASSNAME_LENGTH];
	for(int i; i<6; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		if(weapon<MaxClients || !IsValidEntity(weapon))
		{
			indexes[i] = -1;
			classnames[i][0] = 0;
			continue;
		}

		indexes[i] = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		
	}

	WeaponKV.Rewind();
	WeaponKv.GotoFirstSubKey();
	do
	{
		static char attrib[256];
		if(!WeaponKv.GetSectionName(attrib, sizeof(attrib))
			continue;

		static char names[8][MAX_CLASSNAME_LENGTH];
		int num = ExplodeString(attrib, " ; ", names, sizeof(names), sizeof(names[]));
		int slot = -1;
		for(int i; i<num; i++)
		{
			if(StrContains(names[i], "tf_") == -1)
			{
				int index = StringToInt(names[i]);
				for(int a; a<6; a++)
				{
					if(index != indexes[a])
						continue;

					slot = a;
					break;
				}
			}
			else if(StrContains(names[i], "*") == -1)
			{
				for(int a; a<6; a++)
				{
					if(!StrEqual(names[i], classnames[a]))
						continue;

					slot = a;
					break;
				}
			}
			else if(ReplaceString(names[i], sizeof(names[]), "*", "") > 1)
			{
				for(int a; a<6; a++)
				{
					if(StrContains(names[i], classnames[a]) == -1)
						continue;

					slot = a;
					break;
				}
			}
			else
			{
				for(int a; a<6; a++)
				{
					if(!StrContains(names[i], classnames[a]))
						continue;

					slot = a;
					break;
				}
			}

			if(slot != -1)
				break;

			continue;
		}

		if(!mode)
			continue;
	}
}
