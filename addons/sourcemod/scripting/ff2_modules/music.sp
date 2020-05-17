/*
	Functions:
	void Music_Start(float engineTime)
	void Music_Play(int client, float engineTime, int song)
	void Music_Stop(int client)
	void Music_Override(int client, const char[] path, float time, char[] name, char[] artist)
	void Music_Menu(int client)
	void Music_Next(int client, float engineTime, bool skip)
	void Music_List(int client)
*/

#define FF2_MUSIC

#define MAXSONGS	15

enum struct BGMEnum
{
	char Path[PLATFORM_MAX_PATH];
	float Time;
	char Name[64];
	char Artist[64];
}

int BGMs;
bool BGMLives;
static BGMEnum BGM[MAXSONGS];

void Music_Start(float engineTime)
{
	BGMs = 0;
	BGMLives = false;
	for(int client=1; client<=MaxClients; client++)
	{
		Client[client].BGMAt = engineTime;
		if(Boss[client].Active)
			AddMusicTracks(Boss[client].Special, Boss[client].Lives);
	}
}

static void AddMusicTracks(int boss, int lives)
{
	ConfigMap cfg = Special[boss].Cfg.GetSection("character.sound_bgm");
	if(cfg == null)
		return;

	StringMapSnapshot snap = cfg.Snapshot();
	if(!snap)
		return;

	int entries = snap.Length;
	if(entries)
	{
		char buffer2[PLATFORM_MAX_PATH];
		for(int i; i<entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] buffer = new char[length];
			snap.GetKey(i, buffer, length);
			PackVal val;
			cfg.GetArray(buffer, val, sizeof(val));
			switch(val.tag)
			{
				case KeyValType_Value:
				{
					if(StrContains(buffer, "path"))
						continue;

					ReplaceString(buffer, length, "path", "");
					int id = StringToInt(buffer);
					if(id < 1)
						continue;

					FormatEx(buffer2, sizeof(buffer2), "life%d", id);
					if(cfg.GetInt(buffer2, length))
					{
						if(length>0 && length!=lives)
							continue;
					}

					FormatEx(buffer2, sizeof(buffer2), "path%d", id);
					if(!cfg.Get(buffer2, BGM[id-1].Path, PLATFORM_MAX_PATH))
						continue;

					FormatEx(buffer2, sizeof(buffer2), "time%d", id);
					if(!cfg.GetFloat(buffer2, BGM[id-1].Time))
						BGM[id-1].Time = 0.0;

					FormatEx(buffer2, sizeof(buffer2), "name%d", id);
					if(!cfg.Get(buffer2, BGM[id-1].Name, 64))
						BGM[id-1].Name[0] = 0;

					FormatEx(buffer2, sizeof(buffer2), "artist%d", id);
					if(!cfg.Get(buffer2, BGM[id-1].Artist, 64))
						BGM[id-1].Artist[0] = 0;

					BGMs++;
				}
				case KeyValType_Section:
				{
					val.data.Reset();
					ConfigMap section = val.data.ReadCell();

					if(section.GetInt("life", length))
					{
						if(length>0 && length!=lives)
							continue;
					}

					if(!section.Get("path", BGM[BGMs].Path, PLATFORM_MAX_PATH))
						continue;

					if(!section.GetFloat("time", BGM[BGMs].Time))
						BGM[BGMs].Time = 0.0;

					if(!section.Get("name", BGM[BGMs].Name, 64))
						BGM[BGMs].Name[0] = 0;

					if(!section.Get("artist", BGM[BGMs].Artist, 64))
						BGM[BGMs].Artist[0] = 0;

					BGMs++;
				}
			}
		}
	}

	delete snap;
}

void Music_Play(int client, float engineTime, int song)
{
	Music_Stop(client);
	if(BGMs<1 || Client[client].Pref[Pref_Music]>Pref_On)
		return;

	if(song < 0)
	{
		song = GetRandomInt(0, BGMs-1);
	}
	else if(song >= BGMs)
	{
		song = 0;
	}

	float time = BGM[song].Time;
	char name[64], artist[64];
	static char path[PLATFORM_MAX_PATH];
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

	strcopy(Client[client].BGM, PLATFORM_MAX_PATH, path);

	ClientCommand(client, "playgamesound \"%s\"", path);
	Client[client].BGMAt = time>1 ? engineTime+time : FAR_FUTURE;

	SetGlobalTransTarget(client);

	if(!name[0])
		FormatEx(name, sizeof(name), "%t", "Music Name");

	if(!artist[0])
		FormatEx(artist, sizeof(artist), "%t", "Music Artist");

	FPrintToChat(client, "%t", "Music Info", artist, name);
}

void Music_Stop(int client)
{
	Client[client].BGMAt = FAR_FUTURE;
	if(!Client[client].BGM[0])
		return;

	StopSound(client, SNDCHAN_AUTO, Client[client].BGM);
	StopSound(client, SNDCHAN_AUTO, Client[client].BGM);
	Client[client].BGM[0] = 0;
}

void Music_Override(int client, const char[] path, float time, const char[] name, const char[] artist)
{
	if(Client[client].BGM[0])
		StopSound(client, SNDCHAN_AUTO, Client[client].BGM);

	strcopy(Client[client].BGM, PLATFORM_MAX_PATH, path);

	ClientCommand(client, "playgamesound \"%s\"", path);
	Client[client].BGMAt = time>1 ? GetEngineTime()+time : FAR_FUTURE;

	SetGlobalTransTarget(client);

	char name2[64], artist2[64];
	if(name[0])
	{
		strcopy(name2, sizeof(name2), name);
	}
	else
	{
		FormatEx(name2, sizeof(name2), "%t", "Music Name");
	}

	if(artist[0])
	{
		strcopy(artist2, sizeof(artist2), artist);
	}
	else
	{
		FormatEx(artist2, sizeof(artist2), "%t", "Music Artist");
	}

	FPrintToChat(client, "%t", "Music Info", artist, name);
}

void Music_Menu(int client)
{
	Menu menu = new Menu(Music_MenuH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Music Menu");

	char buffer[64];
	switch(Client[client].Pref[Pref_Music])
	{
		case Pref_Off:
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Music Enable");
			menu.AddItem("1", buffer);
			FormatEx(buffer, sizeof(buffer), "%t", "Music Temp");
			menu.AddItem("3", buffer, BGMs>0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		case Pref_Temp:
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Music Enable");
			menu.AddItem("1", buffer);
			FormatEx(buffer, sizeof(buffer), "%t", "Music Disable");
			menu.AddItem("2", buffer);
		}
		default:
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Music Disable");
			menu.AddItem("2", buffer);
			FormatEx(buffer, sizeof(buffer), "%t", "Music Temp");
			menu.AddItem("3", buffer, BGMs>0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
	}

	FormatEx(buffer, sizeof(buffer), "%t", "Music Skip");
	menu.AddItem("4", buffer, BGMs>0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	FormatEx(buffer, sizeof(buffer), "%t", "Music Shuffle");
	menu.AddItem("5", buffer, BGMs>0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	FormatEx(buffer, sizeof(buffer), "%t", "Music Select");
	menu.AddItem("6", buffer, BGMs>0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.ExitButton = true;
	menu.ExitBackButton = true;
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
		case MenuAction_Cancel:
		{
			if(selection == MenuCancel_ExitBack)
				MainMenu(client);
		}
		case MenuAction_Select:
		{
			switch(selection)
			{
				case 2:
				{
					if(CheckRoundState() == 1)
					{
						Music_Next(client, GetEngineTime(), true);
					}
					else
					{
						FPrintToChat(client, "%t", "Music Wait");
					}
					Music_Menu(client);
				}
				case 3:
				{
					if(CheckRoundState() == 1)
					{
						Music_Next(client, GetEngineTime(), false);
					}
					else
					{
						FPrintToChat(client, "%t", "Music Wait");
					}
					Music_Menu(client);
				}
				case 4:
				{
					if(CheckRoundState() == 1)
					{
						Music_List(client);
						return;
					}

					FPrintToChat(client, "%t", "Music Wait");
					Music_Menu(client);
				}
				default:
				{
					switch(Client[client].Pref[Pref_Music])
					{
						case Pref_Off:
						{
							Client[client].Pref[Pref_Music] = selection ? Pref_Temp : Pref_On;
						}
						case Pref_Temp:
						{
							Client[client].Pref[Pref_Music] = selection ? Pref_Off : Pref_On;
						}
						default:
						{
							Client[client].Pref[Pref_Music] = selection ? Pref_Off : Pref_Temp;
						}
					}
				}
			}
		}
	}
}

void Music_Next(int client, float engineTime, bool skip)
{
	if(skip && Client[client].BGM[0])
	{
		for(int i; i<BGMs; i++)
		{
			if(!StrEqual(BGM[i].Path[0], Client[client].BGM))
				continue;

			Music_Play(client, engineTime, i+1);
			return;
		}
	}
	Music_Play(client, engineTime, -1);
}

void Music_List(int client)
{
	Menu menu = new Menu(Music_ListH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Music Select Menu");

	char buffer[64];
	static char buffer2[16];
	for(int i; i<BGMs; i++)
	{
		TimeToString(RoundToCeil(BGM[i].Time), buffer2, sizeof(buffer2));
		FormatEx(buffer, sizeof(buffer), "%t", "Music Select Song", BGM[i].Artist, BGM[i].Name, buffer2);
		IntToString(i, buffer2, sizeof(buffer2));
		menu.AddItem(buffer2, buffer);
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Music_ListH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(selection == MenuCancel_ExitBack)
				Music_Menu(client);
		}
		case MenuAction_Select:
		{
			if(CheckRoundState() != 1)
			{
				Music_Menu(client);
				FPrintToChat(client, "%t", "Music Wait");
				return;
			}

			char buffer[4];
			menu.GetItem(selection, buffer, sizeof(buffer));
			Music_Play(client, GetEngineTime(), StringToInt(buffer));
			Music_List(client);
		}
	}
}

static void TimeToString(int time, char[] buffer, int length)
{
	if(time/60 > 9)
	{
		IntToString(time/60, buffer, length);
	}
	else
	{
		Format(buffer, length, "0%i", time/60);
	}

	if(time%60 > 9)
	{
		Format(buffer, length, "%s:%i", buffer, time%60);
	}
	else
	{
		Format(buffer, length, "%s:0%i", buffer, time%60);
	}
}
