 /*
	Requirement:
	
*/

#define FF2_PREF

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
				Menu_Main(client);
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

void Pref_QuickToggle(int client, int selection)
{
	Menu menu = new Menu(Pref_QuickToggleH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Pref Popup");

	char buffer[64], num[4];
	IntToString(selection, num, sizeof(num));
	FormatEx(buffer, sizeof(buffer), "%t", "On");
	menu.AddItem(num, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Off");
	menu.AddItem(num, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Temp Map");
	menu.AddItem(num, buffer);

	menu.ExitButton = selection>=0;
	menu.ExitBackButton = selection>=0;
	menu.Display(client, MENU_TIME_FOREVER);
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
			if(selection == MenuCancel_ExitBack)
				Pref_Boss(client);
		}
		case MenuAction_Select:
		{
			char buffer[6];
			menu.GetItem(selection, buffer, sizeof(buffer));
			if(StringToInt(buffer) == -1)
			{
				FPrintToChat(client, "%t", "Pref Remind");
				return;
			}

			// Select Boss
		}
	}
}

void Pref_Boss(int client, int pack)
{
	char buffer[64];
	if(Charset < 0)
	{
		return;
	}

	if(pack == -2)
	{
		return;
	}

	Menu menu = new Menu(Pref_BossH);
	SetGlobalTransTarget(client);
	if(Charsets.Length > 1)
	{
		Charsets.GetString(Charset, buffer, sizeof(buffer))
		menu.SetTitle("%t", "Pref Selection BC", buffer, boss);
	}
	else
	{
		menu.SetTitle("%t", "Pref Selection B", boss);
	}

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Random");
	menu.AddItem(buffer, buffer);
}

void Pref_Bosses(int client)
{
	Menu menu = new Menu(Pref_BossesH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "Pref Selection");

	static char buffer[512];
	if(AreClientCookiesCached(client))
	{
		int size = Charsets.Length>0 ? sizeof(buffer)/Charsets.Length : 64;
		if(size > 64)
		{
			size = 64;
		}
		else if(size < 12)
		{
			size = 12;
		}

		SelectionCookie.Get(client, buffer, sizeof(buffer));
		char[][] buffers = new char[Charsets.Length][size];
		int amount = ExplodeString(buffer, ";", buffers, Charsets.Length, size);

		if(Charset >= 0)
		{
			Charsets.GetString(Charset, buffer, sizeof(buffer));
			if(amount > Charset)
				Format(buffer, sizeof(buffer), "%s: %s", buffer, buffers[Charset]);

			IntToString(Charset, buffers[Charset], size);
			menu.AddItem(buffers[Charset], buffer);
			menu.AddItem(buffers[Charset], "- = - = -", ITEMDRAW_SPACER);
		}

		for(int i; i<Charsets.Length; i++)
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
				Menu_Main(client);
		}
		case MenuAction_Select:
		{
			char buffer[6];
			menu.GetItem(selection, buffer, sizeof(buffer));
			Pref_Boss(client, StringToInt(buffer));
		}
	}
}
