/*
	Top Module

	Functions:
	void Weapons_Setup()
	void Weapons_Check(int client)
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

	WeaponKV = CreateKeyValues("weapons");
	if(WeaponKV.ImportFromFile(config))
		return;

	LogError2("[Weapons] '%s' is improperly formatted!", WEAPON_CONFIG);
	WeaponKV = null;
}

void Weapons_Check(int client)
{
	if(WeaponKV == null)
		return;

	for(int slot; slot<4; slot++)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		if(weapon>MaxClients && IsValidEntity(weapon))
		{
			int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			static char classname[MAX_CLASSNAME_LENGTH];
			GetEntityClassname(weapon, classname, sizeof(classname));

			bool found;
			WeaponKV.Rewind();
			WeaponKv.GotoFirstSubKey();
			do
			{
				static char attrib[256];
				if(!WeaponKv.GetSectionName(attrib, sizeof(attrib))
					continue;

				static char names[8][MAX_CLASSNAME_LENGTH];
				int num = ExplodeString(attrib, " ; ", names, sizeof(names), sizeof(names[]));
				for(int i; i<num; i++)
				{
					if(StrContains(names[i], "tf_") == -1)
					{
						if(StringToInt(names[i]) != index)
							continue;
					}
					else if(StrContains(names[i], "*") == -1)
					{
						if(!StrEqual(names[i], classname))
							continue;
					}
					else if(ReplaceString(names[i], sizeof(names[]), "*", "") > 1)
					{
						if(StrContains(names[i], classname) == -1)
							continue;
					}
					else if(!StrContains(names[i], classname))
					{
						continue;
					}

					found = true;
					break;
				}

				if(!found)
					continue;

				int i = WeaponKv.GetNum("slot", slot);
				if(i<0 || i>2)
				{
					found = false;
					break;
				}

				Weapon[client][i].Stale = WeaponKv.GetNum("stale");
				Weapon[client][i].Crit = WeaponKv.GetNum("crits", -1);
				Weapon[client][i].Special = WeaponKv.GetFloat("special");
				Weapon[client][i].Outline = WeaponKv.GetFloat("outline");
				Weapon[client][i].Stun = WeaponKv.GetFloat("stun");
				Weapon[client][i].Uber = WeaponKv.GetFloat("uber");
				Weapon[client][i].Stab = WeaponKv.GetFloat("stab", 1.0);
				Weapon[client][i].Fall = WeaponKv.GetFloat("fall", 1.0);
				Weapon[client][i].Damage[0] = WeaponKv.GetFloat("damage", 1.0);
				Weapon[client][i].Damage[1] = WeaponKv.GetFloat("damage mini", 1.0);
				Weapon[client][i].Damage[2] = WeaponKv.GetFloat("damage crit", 1.0);
				Weapon[client][i].HealthKit = view_as<bool>(WeaponKv.GetNum("kit"));
				Weapon[client][i].NoForce = !WeaponKv.GetNum("knockback", 1);
				Weapon[client][i].Shield = view_as<bool>(WeaponKv.GetNum("shield"));
				break;
			}

			if(found)
				continue;
		}

		if(slot > 2)
			continue;

		Weapon[client][slot].Stale = 0;
		Weapon[client][slot].Crit = -1;
		Weapon[client][slot].Special = 0.0;
		Weapon[client][slot].Outline = 0.0;
		Weapon[client][slot].Stun = 0.0;
		Weapon[client][slot].Uber = 0.0;
		Weapon[client][slot].Stab = 1.0;
		Weapon[client][slot].Fall = 1.0;
		Weapon[client][slot].Damage[0] = 1.0;
		Weapon[client][slot].Damage[1] = 1.0;
		Weapon[client][slot].Damage[2] = 1.0;
		Weapon[client][slot].HealthKit = false;
		Weapon[client][slot].NoForce = false;
		Weapon[client][slot].Shield = false;
	}
}
