/*
	Top Module
*/

#define FF2_WEAPONS

#define WEAPON_CONFIG		"data/freak_fortress_2/weapons.cfg"

static KeyValues WeaponKV;

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