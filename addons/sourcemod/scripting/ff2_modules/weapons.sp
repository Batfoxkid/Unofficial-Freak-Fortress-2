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
	if(WeaponCfg = null)
		LogError2("[Weapons] '%s' failed to be converted to ConfigMap!", WEAPON_CONFIG);

	ConfigMap cfg = Special[Specials].Cfg.GetSection("Weapons");
	if(cfg == null)
	{
		DeleteCfg(WeaponCfg);
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

	ConfigMap cfg = Special[Specials].Cfg.GetSection("Weapons");
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
					weapon == -1;
			}
			else
			{
				weapon == -1;
			}
		}

		if(weapon != -1)
		{
			int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			GetEntityClassname(weapon, classname, sizeof(classname));

			bool found;
			StringMapSnapshot snap = cfg.Snapshot();
			if(snap)
			{
				bool found;
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

						static char names[8][MAX_CLASSNAME_LENGTH];
						int num = ExplodeString(buffer, " ; ", names, sizeof(names), sizeof(names[]));
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

						int i = WeaponCfg.GetNum("slot", slot);
						if(i<0 || i>2)
						{
							found = false;
							break;
						}

						Weapon[client][i].Stale = WeaponCfg.GetNum("stale");
						Weapon[client][i].Shield = view_as<bool>(WeaponCfg.GetNum("shield")) ? weapon : 0;
						Weapon[client][i].Crit = WeaponCfg.GetNum("crits", -1);
						Weapon[client][i].Special = WeaponCfg.GetFloat("special");
						Weapon[client][i].Outline = WeaponCfg.GetFloat("outline");
						Weapon[client][i].Stun = WeaponCfg.GetFloat("stun");
						Weapon[client][i].Uber = WeaponCfg.GetFloat("uber");
						Weapon[client][i].Stab = WeaponCfg.GetFloat("stab", 1.0);
						Weapon[client][i].Fall = WeaponCfg.GetFloat("fall", 1.0);
						Weapon[client][i].Damage[0] = WeaponCfg.GetFloat("damage", 1.0);
						Weapon[client][i].Damage[1] = WeaponCfg.GetFloat("damage mini", 1.0);
						Weapon[client][i].Damage[2] = WeaponCfg.GetFloat("damage crit", 1.0);
						Weapon[client][i].HealthKit = view_as<bool>(WeaponCfg.GetNum("kit"));
						Weapon[client][i].NoForce = !WeaponCfg.GetNum("knockback", 1);
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
		Weapon[client][slot].Shield = 0;
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
	}
}
