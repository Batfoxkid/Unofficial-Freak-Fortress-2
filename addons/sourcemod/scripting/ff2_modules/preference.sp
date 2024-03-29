 /*
	Functions:
	void Pref_Setup()
	void Pref_SetupClient(int client, float engineTime)
	void Pref_SaveClient(int client)
	void Pref_Menu(int client)
	void Pref_QuickToggle(int client, int selection=-1)
	void Pref_BossMenu(int client, int pack)
	void Pref_Bosses(int client)
	void Pref_SelectBoss(int client, int boss, bool blank=false)
*/

#define FF2_PREF

static Cookie CoreCookie;
static Cookie BossCookie;

void Pref_Setup()
{
	CoreCookie = new Cookie("ff2_cookies_mk3", "Your Preferences", CookieAccess_Protected);
	BossCookie = new Cookie("ff2_cookies_selection", "Your Boss Selections", CookieAccess_Protected);
}

void Pref_SetupClient(int client, float engineTime)
{
	if(IsFakeClient(client) || !Client[client].Cached)
	{
		Client[client].Queue = 0;
		for(int i; i<Pref_MAX; i++)
		{
			Client[client].Pref[i] = Pref_Undef;
		}
		Client[client].PopUpAt = engineTime+30.0;
		Client[client].Selection = -1;
		return;
	}

	int length = Charsets.Length;
	if(!length)
		length = 1;

	static char buffer[512];
	int size = sizeof(buffer)/length;
	if(size > 64)
	{
		size = 64;
	}
	else if(size < 12)
	{
		size = 12;
	}

	if(length <= Pref_MAX)
		length = Pref_MAX+1;

	CoreCookie.Get(client, buffer, sizeof(buffer));
	char[][] buffers = new char[length][size];
	int amount = ExplodeString(buffer, " ", buffers, length, size);

	Client[client].Queue = amount ? StringToInt(buffers[0]) : 0;
	for(int i=1; i<=Pref_MAX; i++)
	{
		Client[client].Pref[i-1] = amount>i ? StringToInt(buffers[i]) : Pref_Undef;
	}
	Client[client].PopUpAt = Client[client].Pref[Pref_Boss]==Pref_Undef ? engineTime+30.0 : FAR_FUTURE;

	BossCookie.Get(client, buffer, sizeof(buffer));
	amount = ExplodeString(buffer, ";", buffers, length, size);
	if(amount > Charset)
	{
		for(int i; i<Specials; i++)
		{
			if(Special[i].Charset != Charset)
				continue;

			if(!Special[i].Cfg.Get("character.name", buffer, sizeof(buffer)))
				continue;

			if(StrContains(buffer, buffers[Charset]))
				continue;

			Client[client].Selection = i;
			return;
		}
	}
	Client[client].Selection = -1;
}

void Pref_SaveClient(int client)
{
	if(IsFakeClient(client) || !Client[client].Cached)
		return;

	if(Client[client].Queue > 9999)
		Client[client].Queue = 9999;

	static char buffer[Pref_MAX*6+5];
	IntToString(Client[client].Queue, buffer, sizeof(buffer));
	for(int i; i<Pref_Hud; i++)
	{
		Format(buffer, sizeof(buffer), "%s %d", buffer, Client[client].Pref[i]==Pref_Temp ? Pref_Undef : Client[client].Pref[i]);
	}
	Format(buffer, sizeof(buffer), "%s %d", buffer, Client[client].Pref[Pref_Hud]);
	CoreCookie.Set(client, buffer);
}

void Pref_Menu(int client)
{
	Menu menu = new Menu(Pref_MenuH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Pref Menu");

	char buffer[64];
	FormatEx(buffer, sizeof(buffer), "%t", "Pref Voice", Client[client].Pref[Pref_Voice]==Pref_Off ? "Off" : Client[client].Pref[Pref_Voice]==Pref_Temp ? "Temp Round" : "On");
	menu.AddItem("1", buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Help", Client[client].Pref[Pref_Help]==Pref_Off ? "Off" : Client[client].Pref[Pref_Help]==Pref_Temp ? "Temp Map" : "On");
	menu.AddItem("2", buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Boss", Client[client].Pref[Pref_Boss]==Pref_Off ? "Off" : Client[client].Pref[Pref_Boss]==Pref_Temp ? "Temp Map" : "On");
	menu.AddItem("4", buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Duo", Client[client].Pref[Pref_Duo]==Pref_Off ? "Off" : Client[client].Pref[Pref_Duo]==Pref_Temp ? "Temp Map" : "On");
	menu.AddItem("5", buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Diff", Client[client].Pref[Pref_Diff]==Pref_Off ? "Off" : Client[client].Pref[Pref_Diff]==Pref_Temp ? "Temp Map" : "On");
	menu.AddItem("6", buffer);

	if(Client[client].Pref[Pref_Dmg])
	{
		IntToString(Client[client].Pref[Pref_Dmg], buffer, sizeof(buffer));
		Format(buffer, sizeof(buffer), "%t", "Pref Damage", "_s", buffer);
		menu.AddItem("7", buffer);

		switch(Client[client].Pref[Pref_DmgPos])
		{
			case 1:
				FormatEx(buffer, sizeof(buffer), "%t", "Pref Position", "Pos TM");

			case 2:
				FormatEx(buffer, sizeof(buffer), "%t", "Pref Position", "Pos TR");

			case 3:
				FormatEx(buffer, sizeof(buffer), "%t", "Pref Position", "Pos ML");

			case 4:
				FormatEx(buffer, sizeof(buffer), "%t", "Pref Position", "Pos MR");

			case 5:
				FormatEx(buffer, sizeof(buffer), "%t", "Pref Position", "Pos BL");

			case 6:
				FormatEx(buffer, sizeof(buffer), "%t", "Pref Position", "Pos BR");

			default:
				FormatEx(buffer, sizeof(buffer), "%t", "Pref Position", "Pos TL");
		}
		menu.AddItem("8", buffer);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Pref Damage", "Disabled");
		menu.AddItem("7", buffer);
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Pref_MenuH(Menu menu, MenuAction action, int client, int selection)
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
			if(selection < 5)
			{
				char buffer[4];
				menu.GetItem(selection, buffer, sizeof(buffer));
				int pref = StringToInt(buffer);
				if(pref)
					Client[client].Pref[pref] = Client[client].Pref[pref]==Pref_Off ? Pref_On : Client[client].Pref[pref]==Pref_Temp ? Pref_Off : Pref_Temp;
			}
			else if(selection == 5)
			{
				if(++Client[client].Pref[Pref_Dmg] > 9)
				{
					Client[client].Pref[Pref_Dmg] = 0;
				}
				else if(Client[client].Pref[Pref_Dmg] < 3)
				{
					Client[client].Pref[Pref_Dmg] = 3;
				}
			}
			else if(++Client[client].Pref[Pref_DmgPos] > 6)
			{
				Client[client].Pref[Pref_DmgPos] = 0;
			}
			Pref_Menu(client);
		}
	}
}

void Pref_QuickToggle(int client, int selection=-1)
{
	Menu menu = new Menu(Pref_QuickToggleH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Pref Popup");

	char buffer[64], num[6];
	IntToString(selection, num, sizeof(num));
	FormatEx(buffer, sizeof(buffer), "%t", "On");
	menu.AddItem(num, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Off");
	menu.AddItem(num, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Temp Map");
	menu.AddItem(num, buffer);

	if(selection < -1)
	{
		menu.ExitButton = false;
		menu.Display(client, MENU_TIME_FOREVER);
		return;
	}

	for(int i; i<4; i++)
	{
		menu.AddItem(num, " ", ITEMDRAW_SPACER);
	}

	FormatEx(buffer, sizeof(buffer), "%t", "Back"); 
	menu.AddItem(num, buffer);

	menu.Pagination = false;
	menu.ExitButton = true;
	menu.Display(client, 20);
}

public int Pref_QuickToggleH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(selection == MenuCancel_Timeout)
				Pref_QuickToggleH(menu, MenuAction_Select, client, 0);
		}
		case MenuAction_Select:
		{
			switch(selection)
			{
				case 0:
					Client[client].Pref[Pref_Boss] = Pref_On;

				case 1:
					Client[client].Pref[Pref_Boss] = Pref_Off;

				case 2:
					Client[client].Pref[Pref_Boss] = Pref_Temp;
			}

			char buffer[6];
			menu.GetItem(selection, buffer, sizeof(buffer));
			int boss = StringToInt(buffer);
			if(boss < -1)
			{
				FPrintToChat(client, "%t", "Pref Remind");
				return;
			}

			bool blank = boss==-1;
			Pref_SelectBoss(client, blank ? Charset : boss, blank);
			Pref_BossMenu(client, blank ? Charset : Special[boss].Charset);
		}
	}
}

void Pref_BossMenu(int client, int pack)
{
	if(pack < 0)
	{
		if(Charset < 0)
		{
			Pref_Bosses(client);
			return;
		}

		char boss[64];
		SetGlobalTransTarget(client);
		FormatEx(boss, sizeof(boss), "%t", "Pref Random");

		static char buffer[64];
		GetCmdArgString(buffer, sizeof(buffer));
		if(!StrContains(boss, buffer, false))
		{
			if(Client[client].Pref[Pref_Boss] != Pref_On)
			{
				Pref_QuickToggle(client);
				return;
			}

			Pref_SelectBoss(client, Charset, true);
			FReplyToCommand(client, "%t", "Pref Selected", boss);
			return;
		}

		bool access = CheckCommandAccess(client, "ff2_special", ADMFLAG_CHEATS);
		for(int i; i<Specials; i++)
		{
			if(Special[i].Charset != pack)
				continue;

			ConfigMap cfg = Special[i].Cfg.GetSection("character");

			int blocked;
			if(cfg.GetInt("blocked", blocked) && blocked)
				continue;

			CfgGetLang(cfg, "name", boss, sizeof(boss), client);
			if(StrContains(boss, buffer, false))
			{
				static char buffer2[64];
				cfg.Get("name", buffer2, sizeof(buffer2));
				if(StrContains(buffer2, buffer, false) && (!access || StrContains(Special[i].File, buffer, false)))
					continue;
			}

			if(!CheckBossAccessMsg(client, i, buffer, sizeof(buffer)))
			{
				FReplyToCommand(client, buffer);
				return;
			}

			if(Client[client].Pref[Pref_Boss] != Pref_On)
			{
				Pref_QuickToggle(client, i);
				return;
			}

			FReplyToCommand(client, "%t", "Pref Selected", boss);
			return;
		}

		FReplyToCommand(client, "%t", "Deny Unknown");
		return;
	}

	Menu menu = new Menu(Pref_BossMenuH);

	char buffer[64], boss[64];
	SetGlobalTransTarget(client);
	FormatEx(boss, sizeof(boss), "%t", "Pref Random");
	IntToString(pack, buffer, sizeof(buffer));
	menu.AddItem(buffer, boss);

	char buffer2[64];
	for(int i; i<Specials; i++)
	{
		if(Special[i].Charset != pack)
			continue;

		int access = CheckBossAccess(client, i);
		if(access==-2 || !access)
			continue;

		CfgGetLang(Special[i].Cfg, "character.name", buffer, sizeof(buffer), client);
		if(i == Client[client].Selection)
			strcopy(boss, sizeof(boss), buffer);

		if(access == -1)
		{
			menu.AddItem("-1", buffer, ITEMDRAW_DISABLED);
			continue;
		}

		IntToString(i, buffer2, sizeof(buffer2));
		menu.AddItem(buffer2, buffer);
	}

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Selection A");
	if(Charsets.Length > 1)
	{
		Charsets.GetString(Charset, buffer2, sizeof(buffer2));
		Format(buffer, sizeof(buffer), "%s\n%t", buffer, "Pref Selection C", buffer2);
	}

	if(Client[client].Pref[Pref_Boss] == Pref_On)
		Format(buffer, sizeof(buffer), "%s\n%t", buffer, "Pref Selection B", boss);

	menu.SetTitle(buffer);
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Pref_BossMenuH(Menu menu, MenuAction action, int client, int selection)
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
				Pref_Bosses(client);
		}
		case MenuAction_Select:
		{
			char buffer[6];
			menu.GetItem(selection, buffer, sizeof(buffer));
			int boss = StringToInt(buffer);
			if(boss == -1)
			{
				Pref_Bosses(client);
				return;
			}

			if(selection)
			{
				ConfirmBoss(client, boss);
				return;
			}

			if(Client[client].Pref[Pref_Boss] != Pref_On)
			{
				Pref_QuickToggle(client);
				return;
			}

			Pref_SelectBoss(client, boss, true);
			Pref_BossMenu(client, boss);
		}
	}
}

static void ConfirmBoss(int client, int boss)
{
	Menu menu = new Menu(ConfirmBossH, MenuAction_Select|MenuAction_End);
	SetGlobalTransTarget(client);

	ConfigMap cfg = Special[boss].Cfg.GetSection("character");

	char buffer[256];
	if(!CfgGetLang(cfg, "description", buffer, sizeof(buffer), client))
		FormatEx(buffer, sizeof(buffer), "%t", "Pref No Desc");

	menu.SetTitle(buffer);

	char buffer2[64];
	CfgGetLang(cfg, "name", buffer2, sizeof(buffer2), client);
	if(Special[boss].Charset == Charset)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Pref Confirm", buffer2); 
	}
	else
	{
		Charsets.GetString(Charset, buffer, sizeof(buffer));
		Format(buffer, sizeof(buffer), "%t", "Pref Confirm C", buffer2, buffer);
	}

	IntToString(boss, buffer2, sizeof(buffer2));
	menu.AddItem(buffer2, buffer);

	for(int i; i<6; i++)
	{
		menu.AddItem(buffer2, " ", ITEMDRAW_SPACER);
	}

	FormatEx(buffer, sizeof(buffer), "%t", "Back"); 
	menu.AddItem(buffer2, buffer);

	menu.Pagination = false;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ConfirmBossH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char buffer[6];
			menu.GetItem(selection, buffer, sizeof(buffer));
			int boss = StringToInt(buffer);
			if(!selection)
			{
				if(Client[client].Pref[Pref_Boss] != Pref_On)
				{
					Pref_QuickToggle(client, boss);
					return;
				}
				Pref_SelectBoss(client, boss);
			}
			Pref_BossMenu(client, Special[boss].Charset);
		}
	}
}

void Pref_Bosses(int client)
{
	int length = Charsets.Length;
	if(length < 1)
		return;

	Menu menu = new Menu(Pref_BossesH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Pref Selection");

	static char buffer[512];
	if(Client[client].Cached)
	{
		int size = sizeof(buffer)/length;
		if(size > 64)
		{
			size = 64;
		}
		else if(size < 12)
		{
			size = 12;
		}

		BossCookie.Get(client, buffer, sizeof(buffer));
		char[][] buffers = new char[length][size];
		int amount = ExplodeString(buffer, ";", buffers, length, size);

		if(Charset >= 0)
		{
			Charsets.GetString(Charset, buffer, sizeof(buffer));
			if(amount > Charset)
				Format(buffer, sizeof(buffer), "%s: %s", buffer, buffers[Charset]);

			IntToString(Charset, buffers[Charset], size);
			menu.AddItem(buffers[Charset], buffer);
			menu.AddItem(buffers[Charset], "- = - = -", ITEMDRAW_SPACER);
		}

		for(int i; i<length; i++)
		{
			if(i == Charset)
				continue;

			Charsets.GetString(i, buffer, sizeof(buffer));
			if(i < amount)
				Format(buffer, sizeof(buffer), "%s: %s", buffer, buffers[Charset]);

			IntToString(i, buffers[0], size);
			menu.AddItem(buffers[0], buffer);
		}
	}
	else
	{
		char num[6];
		if(Charset >= 0)
		{
			Charsets.GetString(Charset, buffer, sizeof(buffer));
			IntToString(Charset, num, sizeof(num));
			menu.AddItem(num, buffer);
			menu.AddItem(num, "- = - = -", ITEMDRAW_SPACER);
		}

		for(int i; i<Charsets.Length; i++)
		{
			if(i == Charset)
				continue;

			Charsets.GetString(i, buffer, sizeof(buffer));
			IntToString(i, num, sizeof(num));
			menu.AddItem(num, buffer);
		}
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Pref_BossesH(Menu menu, MenuAction action, int client, int selection)
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
			char buffer[6];
			menu.GetItem(selection, buffer, sizeof(buffer));
			Pref_BossMenu(client, StringToInt(buffer));
		}
	}
}

void Pref_SelectBoss(int client, int boss, bool blank=false)
{
	int pack = blank ? boss : Special[boss].Charset;
	if(Charset == pack)
		Client[client].Selection = blank ? -1 : boss;

	int length = Charsets.Length;
	if(pack>length || !Client[client].Cached)
		return;

	static char buffer[512];
	int size = sizeof(buffer)/length;
	if(size > 64)
	{
		size = 64;
	}
	else if(size < 12)
	{
		size = 12;
	}

	BossCookie.Get(client, buffer, sizeof(buffer));
	char[][] buffers = new char[length][size];
	ExplodeString(buffer, ";", buffers, length, size);
	if(blank)
	{
		buffers[pack][0] = 0;
	}
	else
	{
		Special[boss].Cfg.Get("character.name", buffer, sizeof(buffer));
	}

	strcopy(buffer, sizeof(buffer), buffers[0]);
	for(int i=1; i<length; i++)
	{
		Format(buffer, sizeof(buffer), "%s;%s", buffer, buffers[i]);
	}
	BossCookie.Set(client, buffer);
}
