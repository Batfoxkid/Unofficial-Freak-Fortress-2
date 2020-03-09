/*
	Requirement:
	bosses.sp
*/

#define FF2_MUSIC

#define MAXSONGS	10

int BGMs;

enum struct BGMEnum
{
	char Path[PLATFORM_MAX_PATH];
	float Time;
	char Name[64];
	char Artist[64];
}

BGMEnum BGM[MAXSONGS];

void Music_Start(float engineTime)
{
	BGMs = 0;
	for(int client=1; client<=MaxClients; client++)
	{
		Client[client].BGMAt = engineTime+3.0;
		if(Boss[client].Active)
			AddMusicTracks(Boss[client].Special, Boss[client].Lives);
	}
}

static void AddMusicTracks(int boss, int lives)
{
	Special[boss].Kv.Rewind();
	if(!Special[boss].Kv.JumpToKey("sound_bgm"))
		return;

	char filepath[PLATFORM_MAX_PATH];
	if(Special[boss].Kv.GoFirstSubKey())
	{
		do
		{
			if(!Special[boss].Kv.GetSectionName(BGM[BGMs].Path, MAX_PLATFORM_PATH))
				continue;

			int life = Special[boss].Kv.GetNum("life");
			if(life>0 && life!=lives)
				continue;

			BGM[BGMs].Time = Special[boss].Kv.GetFloat("time");
			if(BGM[BGMs].Time < 1)
				continue;

			Special[boss].Kv.GetString("name", BGM[BGMs].Name);
			Special[boss].Kv.GetString("artist", BGM[BGMs].Artist);
			BGMs++;
		} while(BGMs<MAXSONGS && Special[boss].Kv.GotoNextKey())
		return;
	}

	char key[8];
	for(int i=1; i<=MAXSONGS && BGMs<MAXSONGS; i++)
	{
		FormatEx(key, sizeof(key), "time%i", i);
		BGM[BGMs].Time = Special[boss].Kv.GetFloat(key);
		if(BGM[BGMs].Time < 1)
			break;

		FormatEx(key, sizeof(key), "path%i", i);
		Special[boss].Kv.GetString(key, BGM[BGMs].Path);
		if(!BGM[BGMs].Path[0])
			break;

		FormatEx(key, sizeof(key), "life%i", i);
		int life = Special[boss].Kv.GetNum(key);
		if(life>0 && life!=lives)
			continue;

		FormatEx(key, sizeof(key), "name%i", i);
		Special[boss].Kv.GetString(key, BGM[BGMs].Name);

		FormatEx(key, sizeof(key), "artist%i", i);
		Special[boss].Kv.GetString(key, BGM[BGMs].Artist);
		BGMs++;
	}
}

void Music_Play(int client, float engineTime, int song=-1)
{
	Music_Stop(client);

	if(song < 0)
	{
		song = GetRandomInt(0, BGMs-1);
	}
	else if(song >= BGMs)
	{
		song = 0;
	}

	float time = BGM[song].Time;
	char name[64], artist[64], path[MAX_PLATFORM_PATH];
	strcopy(path, sizeof(path), BGM[song].Path);
	strcopy(name, sizeof(name), BGM[song].Name);
	strcopy(artist, sizeof(artist), BGM[song].Artist);

	Action action;
	Call_StartForward(OnMusic2);
	Call_PushStringEx(path, sizeof(path), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushFloatRef(time);
	Call_PushStringEx(name, sizeof(name), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(artist, sizeof(artist), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	switch(action)
	{
		case Plugin_Stop, Plugin_Handled:
		{
			Client[client].BGMAt = FAR_FUTURE;
			return;
		}
		case Plugin_Continue:
		{
			time = BGM[song].Time;
			strcopy(path, sizeof(path), BGM[song].Path);
			strcopy(name, sizeof(name), BGM[song].Name);
			strcopy(artist, sizeof(artist), BGM[song].Artist);

			action = Plugin_Continue;
			Call_StartForward(OnMusic);
			Call_PushStringEx(path, sizeof(path), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushFloatRef(time);
			Call_Finish(action);
			switch(action)
			{
				case Plugin_Stop, Plugin_Handled:
				{
					Client[client].BGMAt = FAR_FUTURE;
					return;
				}
				case Plugin_Continue:
				{
					time = BGM[song].Time;
					strcopy(path, sizeof(path), BGM[song].Path);
				}
			}
		}
	}

	// TODO: Client Preferences
	strcopy(Client[client].BGM, PLATFORM_MAX_PATH, path);

	ClientCommand(client, "playgamesound \"%s\"", path);
	Client[client].BGMAt = time>1 ? engineTime+time : FAR_FUTURE;

	if(!name[0])
		FormatEx(name, sizeof(name), "%T", "Music Name", client);

	if(!artist[0])
		FormatEx(artist, sizeof(artist), "%T", "Music Artist", client);

	FPrintToChat(client, "%t", "Music Info", artist, name);
}

void Music_Stop(int client)
{
	Client[client].BGMAt = FAR_FUTURE;
	if(!Client[client].BGM[0])
		return;

	StopSound(client, SNDCHAN_AUTO, Client[client].BGM);
	Client[client].BGM[0] = 0;
}

void Music_Menu(int client)
{
	Menu menu = new Menu(Music_MenuH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Music Menu");

	char buffer[64];
	FormatEx(buffer, sizeof(buffer), "%t", Client[client].Pref[Pref_Music]>Pref_On ? "Music Enable" : "Music Disable");
	menu.AddItem(buffer, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Music Skip");
	menu.AddItem(buffer, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Music Shuffle");
	menu.AddItem(buffer, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Music Select");
	menu.AddItem(buffer, buffer);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Music_MenuH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
		}
	}
}

void Music_Skip(int client)
{
	if(Client[client].BGM[0])
	{
		for(int i; i<BGMs; i++)
		{
			if(!StrEqual(BGM[i].Path[0], Client[client].BGM))
				continue;

			Music_Play(client, GetEngineTime(), i+1);
			return;
		}
	}
	Music_Play(client, GetEngineTime());
}
