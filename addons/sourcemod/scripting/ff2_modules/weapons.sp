/*
	Top Module

	Functions:
	void Weapons_Setup()
	void Weapons_Check(int userid)
*/

#define FF2_WEAPONS

#define WEAPON_CONFIG		"data/freak_fortress_2/weapons.cfg"

ConfigMap WeaponCfg;

void Weapons_Setup()
{
	if(Enabled <= Game_Disabled)
		return;

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), WEAPON_CONFIG);
	if(!FileExists(config))
	{
		LogError2("[Weapons] Could not find '%s'!", WEAPON_CONFIG);
		WeaponCfg = null;
		return;
	}

	WeaponCfg = new ConfigMap(config);
	if(WeaponCfg == null)
		LogError2("[Weapons] '%s' failed to be converted to ConfigMap!", WEAPON_CONFIG);

	ConfigMap cfg = WeaponCfg.GetSection("Weapons");
	if(cfg == null)
	{
		DeleteCfg(WeaponCfg);
		WeaponCfg = null;
		LogError2("[Weapons] '%s' is improperly formatted!", WEAPON_CONFIG);
	}
}

public void Weapons_Check(int userid)
{
	if(WeaponCfg == null)
		return;

	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
		return;

	ConfigMap cfg = WeaponCfg.GetSection("Weapons");
	for(int slot; slot<4; slot++)
	{
		static char classname[MAX_CLASSNAME_LENGTH];
		int weapon = GetPlayerWeaponSlot(client, slot);
		if(weapon<=MaxClients || !IsValidEntity(weapon))
		{
			if(slot < 2)
			{
				weapon = MaxClients+1;
				bool found;
				while((weapon=FindEntityByClassname2(weapon, "tf_wearable*")) != -1)
				{
					if(!GetEntityNetClass(weapon, classname, sizeof(classname)) || StrContains(classname, "CTFWearable")==-1 || GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity")!=client || GetEntProp(weapon, Prop_Send, "m_bDisguiseWearable"))
						continue;

					int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					if(slot)
					{
						found = (index==57 || index==131 || index==231 || index==406 || index==642 || index==1099 || index==1144);
					}
					else
					{
						found = (index==405 || index==608);
					}

					if(found)
						break;
				}

				if(!found)
					weapon = -1;
			}
			else
			{
				weapon = -1;
			}
		}

		if(weapon != -1)
		{
			StringMapSnapshot snap = cfg.Snapshot();
			if(snap)
			{
				bool found;
				int entries = snap.Length;
				if(entries)
				{
					int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					GetEntityClassname(weapon, classname, sizeof(classname));

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
						ConfigMap section = val.data.ReadCell();

						static char skip[256], names[8][MAX_CLASSNAME_LENGTH];
						if(section.GetString("skip", skip, sizeof(skip)))
						{
							length = ExplodeString(skip, " ; ", names, sizeof(names), sizeof(names[]));
							for(int x; x<length; x++)
							{
								if(StringToInt(names[x]) != index)
									continue;

								found = true;
								break;
							}

							if(!found)
								continue;

							found = false;
						}

						bool old = !StrContains(buffer, "weapon");
						if(old)
						{
							if(!section.GetString("classname", skip, sizeof(skip)))
							{
								if(!section.GetString("index", skip, sizeof(skip)))
									continue;
							}

							length = ExplodeString(skip, " ; ", names, sizeof(names), sizeof(names[]));
						}
						else
						{
							length = ExplodeString(buffer, " ; ", names, sizeof(names), sizeof(names[]));
						}

						for(int x; x<length; x++)
						{
							if(StrContains(names[x], "tf_") == -1)
							{
								if(StringToInt(names[x]) != index)
									continue;
							}
							else if(StrContains(names[x], "*") == -1)
							{
								if(!StrEqual(names[x], classname))
									continue;
							}
							else if(ReplaceString(names[x], sizeof(names[]), "*", "") > 1)
							{
								if(StrContains(names[x], classname) == -1)
									continue;
							}
							else if(!StrContains(names[x], classname))
							{
								continue;
							}

							found = true;
							break;
						}

						if(!found)
							continue;

						i = slot;
						section.GetInt("slot", i);
						if(i<0 || i>2)
						{
							found = false;
							break;
						}

						Weapon[client][i].Stale = section.GetInt("stale", length) ? length : 0;
						Weapon[client][i].Crit = section.GetInt("crits", length) ? length : -1;
						Weapon[client][i].Shield = (section.GetInt("shield", length) && length) ? weapon : 0;
						Weapon[client][i].HealthKit = (section.GetInt("kit", length) && length);
						Weapon[client][i].NoForce = (section.GetInt("knockback", length) && !length);

						float value;
						section.GetFloat("special", value);
						Weapon[client][i].Special = value;
						Weapon[client][i].Outline = section.GetFloat("outline", value) ? value : 0.0;
						Weapon[client][i].Stun = section.GetFloat("stun", value) ? value : 0.0;
						Weapon[client][i].Uber = section.GetFloat("uber", value) ? value : 0.0;
						Weapon[client][i].Stab = section.GetFloat("stab", value) ? value : 1.0;
						Weapon[client][i].Fall = section.GetFloat("fall", value) ? value : 1.0;
						Weapon[client][i].Damage[0] = section.GetFloat("damage", value) ? value : 1.0;
						Weapon[client][i].Damage[1] = section.GetFloat("damage mini", value) ? value : 1.0;
						Weapon[client][i].Damage[2] = section.GetFloat("damage crit", value) ? value : 1.0;
						break;
					}
				}
				delete snap;
				if(found)
					continue;
			}
		}

		if(slot > 2)
			continue;

		Weapon[client][slot].Stale = 0;
		Weapon[client][slot].Crit = -1;
		Weapon[client][slot].Shield = 0;
		Weapon[client][slot].HealthKit = false;
		Weapon[client][slot].NoForce = false;
		Weapon[client][slot].Special = 0.0;
		Weapon[client][slot].Outline = 0.0;
		Weapon[client][slot].Stun = 0.0;
		Weapon[client][slot].Uber = 0.0;
		Weapon[client][slot].Stab = 1.0;
		Weapon[client][slot].Fall = 1.0;
		Weapon[client][slot].Damage[0] = 1.0;
		Weapon[client][slot].Damage[1] = 1.0;
		Weapon[client][slot].Damage[2] = 1.0;
	}
}
