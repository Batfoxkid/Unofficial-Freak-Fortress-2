/*
	Functions:
	void TTS_Setup()
	bool TTS_Check(const char[] map)
	void TTS_Start()
	void TTS_Add(int client, float damage)

	Credits:
	Chdata
	sarysa
	SHADoW
*/

#define FF2_TTS

#define TTS_WHITELIST_FILE	"data/freak_fortress_2/spawn_teleport.cfg"
#define TTS_BLACKLIST_FILE	"data/freak_fortress_2/spawn_teleport_blacklist.cfg"

float TTSEnabled;
static ConVar CvarTTS;
static ArrayList s_hSpawnArray = null;

void TTS_Setup()
{
	s_hSpawnArray = new ArrayList(2);
	CvarTTS = CreateConVar("ff2_boss_tts", "600.0", "Amount of damage needed to be taken to teleport the boss (if TTS is enabled)", _, true, 0.000001);
}

float TTS_Check(const char[] map)
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), TTS_WHITELIST_FILE);
	if(!FileExists(config))
	{
		LogError2("[TTS] Unable to find '%s'", TTS_WHITELIST_FILE);
		return 0.0;
	}

	File file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogError2("[TTS] Error reading from '%s'", TTS_WHITELIST_FILE);
		return 0.0;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false) || (StrContains(map, config, false)==-1 && StrContains(config, "all", false)))
			continue;

		delete file;
		return CvarTTS.FloatValue;
	}
	delete file;

	BuildPath(Path_SM, config, sizeof(config), TTS_BLACKLIST_FILE);
	if(!FileExists(config))
		return 0.0;

	file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogError2("[TTS] Error reading from '%s'", TTS_BLACKLIST_FILE);
		return 0.0;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false) || (StrContains(map, config, false)==-1 && StrContains(config, "all", false)))
			continue;

		delete file;
		return CvarTTS.FloatValue;
	}
	delete file;
	return 0.0;
}

void TTS_Start()
{
	s_hSpawnArray.Clear();
	int iInt=0, iEnt=MaxClients+1;
	int iSkip[MAXTF2PLAYERS]={0,...};
	while((iEnt = FindEntityByClassname2(iEnt, "info_player_teamspawn")) != -1)
	{
		TFTeam iTeam = view_as<TFTeam>(GetEntProp(iEnt, Prop_Send, "m_iTeamNum"));
		int iClient = GetClosestPlayerTo(iEnt, iTeam);
		if(iClient)
		{
			bool bSkip = false;
			for(int i = 0; i<=MaxClients; i++)
			{
				if(iSkip[i] == iClient)
				{
					bSkip = true;
					break;
				}
			}
			if(bSkip)
				continue;

			iSkip[iInt++] = iClient;
			int iIndex = s_hSpawnArray.Push(EntIndexToEntRef(iEnt));
			s_hSpawnArray.Set(iIndex, iTeam, 1);	// Opposite team becomes an invalid ent
		}
	}
}

void TTS_Add(int client, float damage)
{
	if(TTSEnabled<=0 || CheckRoundState()!=1)
	{
		Boss[client].Hazard = 0.0;
		return;
	}

	Boss[client].Hazard += damage;
	if(Boss[client].Hazard < TTSEnabled)
		return;

	TeleportToMultiMapSpawn(client);
	Boss[client].Hazard = 0.0;
}

/*
    Teleports a client to spawn, but only if it's a spawn that someone spawned in at the start of the round.
    Useful for multi-stage maps like vsh_megaman
*/

static int TeleportToMultiMapSpawn(int client, TFTeam team=TFTeam_Unassigned)
{
	int iSpawn, iIndex;
	TFTeam iTeleTeam;
	if(team <= TFTeam_Spectator)
	{
		iSpawn = EntRefToEntIndex(GetRandBlockCellEx(s_hSpawnArray));
	}
	else
	{
		do
			iTeleTeam = view_as<TFTeam>(GetRandBlockCell(s_hSpawnArray, iIndex, 1));
		while (iTeleTeam != team);
		iSpawn = EntRefToEntIndex(GetArrayCell(s_hSpawnArray, iIndex, 0));
	}
	TeleMeToYou(client, iSpawn);
	return iSpawn;
}

/*
    Returns 0 if no client was found.
*/

static int GetClosestPlayerTo(int iEnt, TFTeam iTeam=TFTeam_Unassigned)
{
	int iBest;
	float flDist, flTemp, vLoc[3], vPos[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vLoc);
	for(int iClient=1; iClient<=MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
		{
			if(iTeam>TFTeam_Unassigned && view_as<TFTeam>(GetEntProp(iClient, Prop_Send, "m_iTeamNum"))!=iTeam)
				continue;

			GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", vPos);
			flTemp = GetVectorDistance(vLoc, vPos);
			if(!iBest || flTemp<flDist)
			{
				flDist = flTemp;
				iBest = iClient;
			}
		}
	}
	return iBest;
}

/*
    Teleports one entity to another.
    Doesn't necessarily have to be players.
    Returns true if a player teleported to a ducking player
*/

static bool TeleMeToYou(int iMe, int iYou, bool bAngles=false)
{
	float vPos[3], vAng[3];
	vAng = NULL_VECTOR;
	GetEntPropVector(iYou, Prop_Send, "m_vecOrigin", vPos);
	if(bAngles)
		GetEntPropVector(iYou, Prop_Send, "m_angRotation", vAng);

	bool bDucked = false;
	if(IsValidClient(iMe) && IsValidClient(iYou) && GetEntProp(iYou, Prop_Send, "m_bDucked"))
	{
		float vCollisionVec[3];
		vCollisionVec[0] = 24.0;
		vCollisionVec[1] = 24.0;
		vCollisionVec[2] = 62.0;
		SetEntPropVector(iMe, Prop_Send, "m_vecMaxs", vCollisionVec);
		SetEntProp(iMe, Prop_Send, "m_bDucked", 1);
		SetEntityFlags(iMe, GetEntityFlags(iMe)|FL_DUCKING);
		bDucked = true;
	}
	TeleportEntity(iMe, vPos, vAng, NULL_VECTOR);
	return bDucked;
}
