/*
	Functions:
	bool Door_Check(const char[] map)
	void Door_Start()
	void Door_Stop()
*/

#define FF2_DOORS

#define DOOR_FILE		"data/freak_fortress_2/doors.cfg"

bool DoorEnabled;
static Handle DoorTimer;

bool Door_Check(const char[] map)
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), DOOR_FILE);
	if(!FileExists(config))
	{
		LogError2("[Doors] Unable to find '%s'", DoorCFG);
		return false;
	}

	File file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogError2("[Doors] Error reading from '%s'", config);
		return false;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false) || (StrContains(map, config, false)==-1 && StrContains(config, "all", false)))
			continue;

		delete file;
		return true;
	}
	return false;
}

void Door_Start()
{
	if(!DoorEnabled)
		return;

	Door_Stop();
	DoorTimer = CreateTimer(5.0, Door_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Door_Stop()
{
	if(DoorTimer == INVALID_HANDLE)
		return;

	KillTimer(DoorTimer);
	DoorTimer = INVALID_HANDLE;
}

public Action Door_Timer(Handle timer)
{
	int entity = -1;
	while((entity=FindEntityByClassname2(entity, "func_door")) != -1)
	{
		AcceptEntityInput(entity, "Open");
		AcceptEntityInput(entity, "Unlock");
	}
	return Plugin_Continue;
}
