/*
	Functions:
	void StatTrak_Setup()
	void StatTrak_Check()
	void StatTrak_Save(int client)
	void StatTrak_Client(int client)
	void StatTrak_Add(int client, int stat, TFClassType class=TFClass_Unknown, int amount=1)
	void StatTrak_Menu(int client, int target, int page, bool referer=false)
*/

#define FF2_STATTRAK

static Cookie StatCookie;
bool StatEnabled;
ConVar CvarStatTrak;
ConVar CvarStatPlayers;

void StatTrak_Setup()
{
	CvarStatTrak = CreateConVar("ff2_stattrak", "0", "If to display StatTrak to players, 2 to make stats public to other players", _, true, 0.0, true, 2.0);
	CvarStatPlayers = CreateConVar("ff2_stattrak_players", "10", "How many players to enable StatTrak", _, true, 0.0, true, float(MAXTF2PLAYERS));

	StatCookie = new Cookie("ff2_cookies_stattrak", "Your StatTrak stats", CookieAccess_Protected);

	RegConsoleCmd("ff2_stats", StatTrak_Command, "View your StatTrak stats");
	RegConsoleCmd("ff2stats", StatTrak_Command, "View your StatTrak stats");
	RegConsoleCmd("hale_stats", StatTrak_Command, "View your StatTrak stats");
	RegConsoleCmd("halestats", StatTrak_Command, "View your StatTrak stats");
}

void StatTrak_Check()
{
	StatEnabled = (Enabled==Game_Arena && Players>CvarStatPlayers.IntValue);
}

void StatTrak_Save(int client)
{
	if(!Client[client].Cached)
		return;

	// 6 * (view_as<int>(TFClassType)-1+Stat_MAX)
	static char buffer[78];
	for(int i; i<Stat_MAX; i++)
	{
		if(Client[client].Stat[i] > 99999)
			Client[client].Stat[i] = 99999;

		if(i)
		{
			Format(buffer, sizeof(buffer), "%s %d", buffer, Client[client].Stat[i]);
			continue;
		}

		IntToString(Client[client].Stat[0], buffer, sizeof(buffer));
	}
	for(int i=1; i<view_as<int>(TFClassType); i++)
	{
		if(Client[client].Kills[i] > 99999)
			Client[client].Kills[i] = 99999;

		if(Client[client].Mvps[i] > 99999)
			Client[client].Mvps[i] = 99999;

		Format(buffer, sizeof(buffer), "%s %d %d", buffer, Client[client].Kills[i], Client[client].Mvps[i]);
	}
	SetClientCookie(client, StatCookie, buffer);
}

void StatTrak_Client(int client)
{
	if(!Client[client].Cached)
	{
		for(int i; i<Stat_MAX; i++)
		{
			Client[client].Stat[i] = 0;
		}
		for(int i; i<view_as<int>(TFClassType); i++)
		{
			Client[client].Kills[i] = 0;
			Client[client].Mvps[i] = 0;
		}
		return;
	}

	Client[client].Kills[0] = 0
	Client[client].Mvps[0] = 0;

	static char buffer[6 * (view_as<int>(TFClassType)-1+Stat_MAX)];
	GetClientCookie(client, StatCookie, cookies);

	static char buffers[view_as<int>(TFClassType)-1+Stat_MAX][6];
	int count = ExplodeString(buffer, " ", buffers, sizeof(buffers), sizeof(buffers[]));
	for(int i; i<Stat_MAX; i++)
	{
		Client[client].Stat[i] = count>i ? StringToInt(buffers[i]) : 0;
	}

	int a = Stat_MAX;
	for(int i=1; i<view_as<int>(TFClassType); i++)
	{
		Client[client].Kills[i] = count>a ? StringToInt(buffers[a++]) : 0;
		Client[client].Mvps[i] = count>a ? StringToInt(buffers[a++]) : 0;
	}
}

void StatTrak_Add(int client, int stat, TFClassType class=TFClass_Unknown, int amount=1)
{
	if(!StatEnabled && !IsFakeClient(client))
		return;

	if(stat < Stat_MAX)
	{
		Client[client].Stat[stat] += amount;
		return;
	}

	if(stat == Stat_Slain)
	{
		Client[client].Kills[class] += amount;
		return;
	}

	Client[client].Mvps[class] += amount;
}

public Action StatTrak_Command(int client, int args)
{
	if(!args)
	{
		if(client)
		{
			StatTrak_Menu(client, client, Boss[client].Active ? 0 : GetClassType(view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))));
		}
		else
		{
			ReplyToCommand(client, "[SM] Usage: ff2_stats <target>");
		}
		return Plugin_Handled;
	}

	static char buffer[MAX_TARGET_LENGTH];
	GetCmdArgString(buffer, sizeof(buffer));

	char name[2];
	int targets[2], matches;
	bool special;
	if((matches=ProcessTargetString(buffer, client, targets, sizeof(targets), COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS, name, sizeof(name), special)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(client!=targets[0] && Client[targets[0]].Private)
	{
		ReplyToTargetError(client, COMMAND_TARGET_IMMUNE);
		return Plugin_Handled;
	}

	StatTrak_Menu(client, targets[0], Boss[targets[0]].Active ? 0 : GetClassType(TF2_GetPlayerClass(targets[0])));
	return Plugin_Handled;
}

void StatTrak_Menu(int client, int target, int page, bool referer=false)
{
	Menu menu = new Menu(StatTrak_MenuH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Stat Menu");

	char buffer[64];
	FormatEx(buffer, sizeof(buffer), "%t", "Stat Wins", Client[target].Stat[Stat_Win]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Losses", Client[target].Stat[Stat_Lose]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Kills", Client[target].Stat[Stat_Kill]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Deaths", Client[target].Stat[Stat_Death]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	menu.AddItem("0", "", ITEMDRAW_RAWLINE);
	menu.AddItem("0", "", ITEMDRAW_RAWLINE);

	if(client == target)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Stat Reset");
		menu.AddItem("4", buffer, referer ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Stat Self");
		menu.AddItem("0", buffer);
	}

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Slains Scout", Client[target].Kills[TFClass_Scout]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat MVPs Scout", Client[target].Mvps[TFClass_Scout]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Slains Soldier", Client[target].Kills[TFClass_Soldier]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat MVPs Soldier", Client[target].Mvps[TFClass_Soldier]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Slains Pyro", Client[target].Kills[TFClass_Pyro]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat MVPs Pyro", Client[target].Mvps[TFClass_Pyro]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	if(client == target)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Stat Reset");
		menu.AddItem("5", buffer, referer ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Stat Self");
		menu.AddItem("1", buffer);
	}

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Slains Demoman", Client[target].Kills[TFClass_DemoMan]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat MVPs Demoman", Client[target].Mvps[TFClass_DemoMan]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Slains Heavy", Client[target].Kills[TFClass_Heavy]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat MVPs Heavy", Client[target].Mvps[TFClass_Heavy]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Slains Engineer", Client[target].Kills[TFClass_Engineer]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat MVPs Engineer", Client[target].Mvps[TFClass_Engineer]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	if(client == target)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Stat Reset");
		menu.AddItem("6", buffer, referer ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Stat Self");
		menu.AddItem("2", buffer);
	}

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Slains Medic", Client[target].Kills[TFClass_Medic]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat MVPs Medic", Client[target].Mvps[TFClass_Medic]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Slains Sniper", Client[target].Kills[TFClass_Sniper]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat MVPs Sniper", Client[target].Mvps[TFClass_Sniper]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat Slains Spy", Client[target].Kills[TFClass_Spy]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	FormatEx(buffer, sizeof(buffer), "%t", "Stat MVPs Spy", Client[target].Mvps[TFClass_Spy]);
	menu.AddItem("0", buffer, ITEMDRAW_RAWLINE);

	if(client == target)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Stat Reset");
		menu.AddItem("7", buffer, referer ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Stat Self");
		menu.AddItem("3", buffer);
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.DisplayAt(client, page*7, MENU_TIME_FOREVER);
}

public int StatTrak_MenuH(Menu menu, MenuAction action, int client, int selection)
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
			char buffer[4];
			menu.GetItem(selection, buffer, sizeof(buffer));
			int choice = StringToInt(buffer);
			if(choice < 4)
			{
				StatTrak_Menu(client, client, choice);
				return;
			}

			IntToString(choice-4, buffer, sizeof(buffer));
			StatTrak_Reset(client, buffer);
		}
	}
}

static void StatTrak_Reset(int client, const char[] back, bool confirm=false)
{
	Menu menu = new Menu(confirm ? StatTrak_ResetH : StatTrak_Confirm);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", confirm ? "Stat Confirm" : "Stat Reset");

	char buffer[16];
	FormatEx(buffer, sizeof(buffer), "%t", "Yes");
	menu.AddItem(back, buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "No");
	menu.AddItem(back, buffer);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int StatTrak_Confirm(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char buffer[4];
			menu.GetItem(selection, buffer, sizeof(buffer));
			if(selection)
			{
				StatTrak_Menu(client, client, StringToInt(buffer));
				return;
			}

			StatTrak_Reset(client, buffer, true);
		}
	}
}

public int StatTrak_ResetH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!selection)
			{
				for(int i; i<Stat_MAX; i++)
				{
					Client[client].Stat[i] = 0;
				}
				for(int i; i<view_as<int>(TFClassType); i++)
				{
					Client[client].Kills[i] = 0;
					Client[client].Mvps[i] = 0;
				}
				StatTrak_Save(client);
			}

			char buffer[4];
			menu.GetItem(selection, buffer, sizeof(buffer));
			StatTrak_Menu(client, client, StringToInt(buffer), !selection);
		}
	}
}

static int GetClassType(TFClassType class)
{
	switch(class)
	{
		case TFClass_Scout, TFClass_Soldier, TFClass_Pyro:
			return 1;

		case TFClass_DemoMan, TFClass_Heavy, TFClass_Engineer:
			return 2;

		case TFClass_Medic, TFClass_Sniper, TFClass_Spy:
			return 3;
	}
	return 0;
}