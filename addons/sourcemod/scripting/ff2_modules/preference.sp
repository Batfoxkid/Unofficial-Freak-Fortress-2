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
	FormatEx(buffer, sizeof(buffer), "%t", "Pref Voice", Client[client].Pref[Pref_Voice]==Pref_Off ? "Disabled" : Client[client].Pref[Pref_Voice]==Pref_Temp ? "Temp Round" : "Enabled");
	menu.AddItem("1", buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Help", Client[client].Pref[Pref_Help]==Pref_Off ? "Disabled" : Client[client].Pref[Pref_Help]==Pref_Temp ? "Temp Map" : "Enabled");
	menu.AddItem("2", buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Boss", Client[client].Pref[Pref_Boss]==Pref_Off ? "Disabled" : Client[client].Pref[Pref_Boss]==Pref_Temp ? "Temp Map" : "Enabled");
	menu.AddItem("4", buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Duo", Client[client].Pref[Pref_Duo]==Pref_Off ? "Disabled" : Client[client].Pref[Pref_Duo]==Pref_Temp ? "Temp Map" : "Enabled");
	menu.AddItem("5", buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Pref Diff", Client[client].Pref[Pref_Diff]==Pref_Off ? "Disabled" : Client[client].Pref[Pref_Diff]==Pref_Temp ? "Temp Map" : "Enabled");
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
	FormatEx(buffer, sizeof(buffer), "%t", "Enabled");
	menu.AddItem(num, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Disabled");
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
		}
	}
}
