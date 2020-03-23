/*
*/

#define FF2_DOORS

#define DOOR_FILE		"data/freak_fortress_2/characters.cfg"

void Doors_Setup(bool check=false)
{
	char config[PLATFORM_MAX_PATH];
	checkDoors = false;
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, DoorCFG);
	if(!FileExists(config))
	{
		LogToFile(eLog, "[Doors] Unable to find '%s'", DoorCFG);
		return;
	}

	File file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(eLog, "[Doors] Error reading from '%s'", config);
		return;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(StrContains(currentmap, config, false)!=-1 || !StrContains(config, "all", false))
		{
			delete file;
			checkDoors = true;
			return;
		}
	}
	delete file;
}
