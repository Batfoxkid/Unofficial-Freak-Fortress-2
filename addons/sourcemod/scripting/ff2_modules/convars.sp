/*
	Functions:
	void Convars_Enable()
	void Convars_Disable()
*/

#define FF2_CONVARS

static const char ForceCvar[][][] =
{
	{ "tf_arena_use_queue", "0" },
	{ "mp_teams_unbalance_limit", "0" },
	{ "tf_arena_first_blood", "0" },
	{ "mp_forcecamera", "0" },
	{ "tf_dropped_weapon_lifetime", "0" },
	{ "mp_humans_must_join_team", "any" }
};

static char CvarValue[sizeof(ForceCvar)][16];
static ConVar Cvarcvar[sizeof(ForceCvar)];
static char Hostname[256];
static ConVar Hostcvar;

void Convars_Enable()
{
	CvarVersion.SetString(PLUGIN_VERSION);

	Hostcvar = FindConVar("hostname");
	if(Hostcvar)
	{
		Hostcvar.GetString(Hostname, sizeof(Hostname));
		Hostcvar.AddChangeHook(Convars_Hostname);
	}

	for(int i; i<sizeof(ForceCvar); i++)
	{
		Cvarcvar[i] = FindConVar(ForceCvar[i][0]);
		if(!Cvarcvar[i])
			continue;

		Cvarcvar[i].GetString(CvarValue[i], sizeof(CvarValue[]));
		Cvarcvar[i].SetString(ForceCvar[i][1]);
		Cvarcvar[i].AddChangeHook(Convars_Hook);
	}
}

void Convars_Disable()
{
	if(Hostcvar)
	{
		Hostcvar.SetString(Hostname);
		Hostcvar.RemoveChangeHook(Convars_Hostname);
		Hostcvar = null;
	}

	for(int i; i<sizeof(ForceCvar); i++)
	{
		if(!Cvarcvar[i])
			continue;

		Cvarcvar[i].SetString(CvarValue[i]);
		Cvarcvar[i].RemoveChangeHook(Convars_Hook);
		Cvarcvar[i] = null;
	}
}

void Convars_NameSuffix(const char[] suffix)
{
	if(!Hostcvar)
		return;

	char buffer[256];
	FormatEx(buffer, sizeof(buffer), "%s | %s", suffix);
	Hostcvar.RemoveChangeHook(Convars_Hostname);
	Hostcvar.SetString(buffer);
	Hostcvar.AddChangeHook(Convars_Hostname);
}

public void Convars_Hook(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	for(int i; i<sizeof(ForceCvar); i++)
	{
		if(cvar != Cvarcvar[i])
			continue;

		if(!StrEqual(newValue, CvarValue[i]))
		{
			strcopy(newValue, CvarValue[i], sizeof(CvarValue[]));
			cvar.SetString(ForceCvar[i][1]);
		}
		return;
	}
}

public void Convars_Hostname(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(newValue, Hostname, sizeof(Hostname));
}