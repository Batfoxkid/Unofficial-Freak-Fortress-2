/*
                << Freak Fortress 2 >>
                   < Unofficial 2 >

     Original Author of VSH and FF2, Rainbolt Dash
        Programmer, modeller, mapper, painter
             Author of Demoman The Pirate
         One of two creators of Floral Defence

      And notoriously famous for creating plugins
      with terrible code and then abandoning them.

      Updated by Otokiru, Powerlord, and RavensBro
       after Rainbolt Dash got sucked into DOTA2

     Updated again by Wliu, Chris, Lawd, and Carge
              after Powerlord quit FF2

           Old Versus Saxton Hale Thread:
  http://forums.alliedmods.net/showthread.php?t=146884
             Old Freak Fortress Thread:
  http://forums.alliedmods.net/showthread.php?t=182108
           New Versus Saxton Hale Thread:
  http://forums.alliedmods.net/showthread.php?t=244209
             New Freak Fortress Thread:
  http://forums.alliedmods.net/showthread.php?t=229013

    Freak Fortress and Versus Saxton Hale Subforum:
  http://forums.alliedmods.net/forumdisplay.php?f=154



  Well here I am again, this time an entire remake, or
  somewhat remake. This can help stabilize FF2 and make
   it easier for additions, modifications, etc. Well
   here's one last booster. Unless someone else does
   the same, I think this might be the last of FF2...

					-Batfoxkid

          Unofficial Freak Fortress 2 Thread:
  http://forums.alliedmods.net/showthread.php?t=313008
*/
#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#include <adt_array>
#include <clientprefs>
#include <colorlib>
#include <sdkhooks>
#include <tf2_stocks>
#undef REQUIRE_EXTENSIONS
#tryinclude <tf2items>
#tryinclude <SteamWorks>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <tf2attributes>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define FORK_MAJOR_REVISION	"2"
#define FORK_MINOR_REVISION	"0"
#define FORK_STABLE_REVISION	"0"
#define FORK_SUB_REVISION	"Unofficial"
#define FORK_DEV_REVISION	"build"
#define FORK_DATE_REVISION	"SoonTM"

#define BUILD_NUMBER	FORK_MINOR_REVISION...""...FORK_STABLE_REVISION..."000"

#if defined FORK_DEV_REVISION
	#define PLUGIN_VERSION	FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION..." "...FORK_DEV_REVISION..."-"...BUILD_NUMBER
#else
	#define PLUGIN_VERSION	FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION
#endif

#define MAJOR_REVISION	"1"
#define MINOR_REVISION	"11"
#define STABLE_REVISION	"0"
#define DEV_REVISION	"Beta"
#define DATE_REVISION	"--Unknown--"

#define DATATABLE	"ff2_stattrak"
#define CHANGELOG_URL	"https://batfoxkid.github.io/Unofficial-Freak-Fortress-2"

#define MAXENTITIES	2048
#define MAXSPECIALS	1024
#define MAXTF2PLAYERS	36

#define HUD_DAMAGE	(1 << 0)
#define HUD_ITEM	(1 << 1)
#define HUD_HEALTH	(1 << 2)
#define HUD_MESSAGE	(1 << 3)

enum
{
	Pref_Undef = 0,
	Pref_On,
	Pref_Off,
	Pref_Temp,

	Pref_Music = 0,
	Pref_Voice,
	Pref_Help,
	Pref_Boss,
	Pref_Duo,
	Pref_Diff,
	Pref_Dmg,
	Pref_DmgPos,
	Pref_Hud,
	Pref_MAX,

	RageMode_Full = 0,
	RageMode_Part,
	RageMode_None
}

enum struct BossEnum
{
	bool Active;
	bool Leader;
	int Special;
	char Name[MAX_TARGET_LENGTH];
	TFClassType Class;
	TFTeam Team;

	int MaxHealth;
	int Lives;
	int MaxLives;
	float MaxSpeed;

	int RageDamage;
	int RageMode;
	float RageMin;
	float RageMax;
	float Charge[4];

	int Killstreak;
	int RPSHealth;
	int RPSCount;

	bool Voice;
	bool Triple;
	int Knockback;
	bool Crits;
	bool Healing;
	bool Sapper;
	bool AmmoKits;
	bool HealthKits;
	bool Cosmetics;

	int Health(int client)
	{
		return GetClientHealth(client)+((this.Lives-1)*this.MaxHealth);
	}

	float Speed(int client)
	{
		return this.MaxSpeed+(0.7*(100.0-this.Health(client)*100.0/this.MaxLives/this.MaxHealth));
	}
}

enum struct ClientEnum
{
	bool Minion;
	TFTeam Team;

	char BGM[PLATFORM_MAX_PATH];
	float BGMAt;
	float GlowFor;
	float PopUpAt;
	int Damage;
	int Queue;
	int Pref[Pref_MAX];
	bool DisableHud;
}

enum struct WeaponEnum
{
	int Crit;
	int Stale;
	float Stun;
	float Uber;
	float Stab;
	float Fall;
	float Special;
	float Outline;
	float Damage[3];
	bool HealthKit;
	bool NoForce;
}

enum struct SpecialEnum
{
	KeyValues Kv;
	int Charset;
	bool Precached;
}

SpecialEnum Special[MAXSPECIALS];
ArrayList BossList;
int Specials;

bool Enabled;
ArrayList Charsets;
int Charset;

WeaponEnum Weapon[MAXTF2PLAYERS][3];
ClientEnum Client[MAXTF2PLAYERS];
BossEnum Boss[MAXTF2PLAYERS];

GlobalForward PreAbility;
GlobalForward OnAbility;
GlobalForward OnMusic;
GlobalForward OnMusic2;
GlobalForward OnTriggerHurt;
GlobalForward OnSpecialSelected;
GlobalForward OnAddQueuePoints;
GlobalForward OnLoadCharacterSet;
GlobalForward OnLoseLife;
GlobalForward OnAlivePlayersChanged;
GlobalForward OnBackstabbed;

// First-Load (No module dependencies)
#include "ff2_modules/stocks.sp"
#tryinclude "ff2_modules/tf2x10.sp"
#tryinclude "ff2_modules/tf2attributes.sp"
#include "ff2_modules/weapons.sp"

// Second-Load
#tryinclude "ff2_modules/tf2items.sp"	// weapons.sp
#tryinclude "ff2_modules/steamworks.sp"	// tf2x10.sp
#include "ff2_modules/sdkhooks.sp"	// tf2attributes.sp

// Third-Load
#include "ff2_modules/bosses.sp"	// convars.sp, sdkhooks.sp, tf2items.sp

// Fourth-Load
#tryinclude "ff2_modules/targetfilter.sp"	// bosses.sp
#include "ff2_modules/music.sp"			// bosses.sp
#include "ff2_modules/formula.sp"		// bosses.sp

// Last-Load
#include "ff2_modules/natives.sp"

// Require either one due to needing weapon attributes for bosses
#if !defined FF2_TF2ATTRIBUTES
  #if !defined FF2_TF2ITEMS
    #error "Must have either TF2Items or TF2Attributes compiled with"
  #endif
#endif

public Plugin myinfo =
{
	name		=	"Freak Fortress 2",
	author		=	"Many many people",
	description	=	"It's like Christmas Morning",
	version		=	PLUGIN_VERSION,
	url		=	"https://forums.alliedmods.net/forumdisplay.php?f=154",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freaks/"))
	{
		strcopy(error, err_max, "There is a duplicate copy of Freak Fortress 2 inside the /plugins/freaks folder.  Please remove it");
		return APLRes_Failure;
	}

	Native_Setup();

	PreAbility = GlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);  //Boss, plugin name, ability name, slot, enabled
	OnAbility = GlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);  //Boss, plugin name, ability name, status
	OnMusic = GlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
	OnMusic2 = GlobalForward("FF2_OnMusic2", ET_Hook, Param_String, Param_FloatByRef, Param_String, Param_String);
	OnTriggerHurt = GlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnSpecialSelected = GlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);  //Boss, character index, character name, preset
	OnAddQueuePoints = GlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet = GlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_CellByRef, Param_String);
	OnLoseLife = GlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);  //Boss, lives left, max lives
	OnAlivePlayersChanged = GlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);  //Players, bosses
	OnBackstabbed = GlobalForward("FF2_OnBackStabbed", ET_Hook, Param_Cell, Param_Cell, Param_Cell);  //Boss, client, attacker

	RegPluginLibrary("freak_fortress_2");

	#if defined FF2_TF2ITEMS
	TF2Items_Pre();
	#endif

	#if defined FF2_TF2ATTRIBUTES
	TF2Attributes_Pre();
	#endif

	#if defined FF2_STEAMWORKS
	SteamWorks_Pre();
	#endif
	return APLRes_Success;
}

public void OnPluginStart()
{
	PrintToServer("%s Freak Fortress %s Loading...", FORK_SUB_REVISION, BUILD_NUMBER);

	#if defined FF2_TF2ATTRIBUTES
	TF2Attributes_Setup();
	#endif

	#if defined FF2_TIMESTEN
	TimesTen_Setup();
	#endif

	#if defined FF2_TF2ITEMS
	TF2Items_Setup();
	#endif

	#if defined FF2_STEAMWORKS
	SteamWorks_Setup();
	#endif

	SDK_Setup();
	Bosses_Setup();

	#if defined FF2_TARGETFILTER
	TargetFilter_Setup();
	#endif

	AutoExecConfig(true, "FreakFortress2");
}

public void OnConfigsExecuted()
{
	Weapons_Setup();
	Bosses_Config();
}

public Action GlobalTimer(Handle timer)
{
	if(!Enabled)
		return Plugin_Stop;

	if(CheckRoundState() == 2)
		return Plugin_Stop;

	float engineTime = GetEngineTime();
	float gameTime = GetGameTime();

	bool sappers;
	int max;
	int best[10];
	int[] clients = new int[MaxClients];
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;

		clients[max++] = i;
		if(Boss[i].Active)
		{
			if(!sappers)
				sappers = Boss[i].Sapper;

			continue;
		}

		if(Damage[client] < 1)
			continue;

		for(int a; a<10; a++)
		{
			if(best[a] && Client[i].Damage<Client[best[a]].Damage)
				continue;

			int b = 9;
			while(b > a)
			{
				best[b] = best[--b];
			}
			best[a] = b;
			break;
		}
	}

	char bestHud[10][48];
	for(int i; i<10; i++)
	{
		if(!best[i])
			break;

		FormatEx(bestHud[i], sizeof(bestHud[]), "[%i] %N: %i", i+1, best[i], Client[best[index]].Damage);
	}

	for(int i; i<max; i++)
	{
		bool alive = IsPlayerAlive(clients[i]);
		int buttons = GetClientButtons(clients[i]);
		ClientThink(clients[i], engineTime, gameTime, alive);
		static char buffer[64];
		if(!(Client[clients[i]] & HUD_DAMAGE) && !(buttons & IN_SCORE) && (alive || IsClientObserver(clients[i]))
		{
			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
			int observer;
			if(alive)
			{
				observer = GetClientAimTarget(clients[i], true);
				if(observer!=client && IsValidClient(observer))
				{
					TFTeam team = TF2_GetClientTeam(clients[i]);
					if(TF2_GetClientTeam(observer) != team)
					{
						if(TF2_IsPlayerInCondition(observer, TFCond_Cloaked))
						{
							observer = 0;
						}
						else if(TF2_IsPlayerInCondition(observer, TFCond_Disguised))
						{
							observer = GetEntProp(observer, Prop_Send, "m_iDisguiseTargetIndex");
							if(!IsValidClient(observer) || TF2_GetClientTeam(observer)!=team)
								observer = 0;
						}
					}

					if(observer)
					{
						static float position[3], position2[3];
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
						GetEntPropVector(observer, Prop_Send, "m_vecOrigin", position2);
						if(GetVectorDistance(position, position2) > 400)
							observer = 0;
					}
				}
				else
				{
					observer = 0;
				}
			}
			else
			{
				observer = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if(observer==client || !IsValidClient(observer))
					observer = 0;
			}
		}
	}
}

void ClientThink(int client, float engineTime, float gameTime, bool alive)
{
	if(Client[client].BGMAt < engineTime)
		Music_Play(client, engineTime, -1);

	if(Client[client].PopUpAt < engineTime)
	{
		Client[client].PopUpAt = FAR_FUTURE;
		if(Client[client].Pref[Pref_Boss] == Pref_Undef)
			Pref_QuickToggle(client, -2);
	}

	if(!Client[client].GlowFor || !alive)
	{
	}
	else if(Client[client].GlowFor < gameTime)
	{
		Client[client].GlowFor = 0.0;
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	}
}

public Action MainMenuC(int client, int args)
{
	if(client)
	{
		MainMenu(client);
		return Plugin_Handled;
	}

	PrintToServer("Freak Fortress 2");
	#if defined DEV_REVISION
	PrintToServer("Version: %s.%s.%s %s", MAJOR_REVISION, MINOR_REVISION, STABLE_REVISION, DEV_REVISION);
	#else
	PrintToServer("Version: %s.%s.%s", MAJOR_REVISION, MINOR_REVISION, STABLE_REVISION);
	#endif
	#if defined FORK_SUB_REVISION
	  #if defined FORK_DEV_REVISION
	  PrintToServer("Fork: %s %s.%s.%s %s", FORK_SUB_REVISION, FORK_MAJOR_REVISION, FORK_MINOR_REVISION, FORK_STABLE_REVISION, FORK_DEV_REVISION);
	  #else
	  PrintToServer("Fork: %s %s.%s.%s", FORK_SUB_REVISION, FORK_MAJOR_REVISION, FORK_MINOR_REVISION, FORK_STABLE_REVISION);
	  #endif
	#endif
	PrintToServer("Build: %s", BUILD_NUMBER);
	PrintToServer("Date: %s", FORK_DATE_REVISION);
	PrintToServer("Status: %s", Enabled ? "Enabled" : "Disabled");

	PrintToServer("");

	#if defined FF2_STEAMWORKS
	PrintToServer("SteamWorks: %s", SteamWorks ? "Enabled" : "Library Not Found");
	#elseif defined _SteamWorks_Included
	PrintToServer("SteamWorks: Module Not Compiled");
	#else
	PrintToServer("SteamWorks: Include Not Compiled");
	#endif

	#if defined FF2_TARGETFILTER
	PrintToServer("Target Filter: Enabled");
	#else
	PrintToServer("Target Filter: Module Not Compiled");
	#endif

	#if defined FF2_TF2ATTRIBUTES
	bool statusCheck = TF2Attributes;
	PrintToServer("TF2Attributes: %s", TF2Attributes ? "Enabled" : "Library Not Found");
	#elseif defined _tf2attributes_included
	bool statusCheck;
	PrintToServer("TF2Attributes: Module Not Compiled");
	#else
	bool statusCheck;
	PrintToServer("TF2Attributes: Include Not Compiled");
	#endif

	#if defined FF2_TF2ITEMS
	statusCheck = (statusCheck || TF2Items);
	PrintToServer("TF2Items: %s", TF2Items ? "Enabled" : "Library Not Found");
	#elseif defined _tf2items_included
	PrintToServer("TF2Items: Module Not Compiled");
	#else
	PrintToServer("TF2Items: Include Not Compiled");
	#endif

	#if defined FF2_TIMESTEN
	PrintToServer("TF2x10: %s", TimesTen ? "Enabled" : "Library Not Found"));
	#else
	PrintToServer("TF2x10: Module Not Compiled");
	#endif

	PrintToServer("");
	PrintToServer("Weapon Attributes: %s", statusCheck ? "OK" : "TF2Attributes nor TF2Items are available");
	PrintToServer("Wearable Weapons: %s", SDKEquipWearable==null ? "Failed to create call via Gamedata" : "OK");
	PrintToServer("Boss KeyValues: %s", Enabled ? Special[0].Kv==INVALID_HANDLE ? "Failed to create boss KeyValues" : "OK" : "N/A");
	PrintToServer("Weapon KeyValues: %s", Enabled ? WeaponKV==null ? "Failed to create weapon KeyValues" : "OK" : "N/A");
	return Plugin_Handled;
}

void MainMenu(int client)
{
	Menu menu = new Menu(MainMenuH);
	char buffer[256];
	SetGlobalTransTarget(client);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Title");
	menu.SetTitle(buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Menu Pref");
	menu.AddItem("1", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Selection");
	menu.AddItem("2", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Help");
	menu.AddItem("3", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu New");
	menu.AddItem("4", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Queue");
	menu.AddItem("5", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Music");
	menu.AddItem("6", buffer);

	menu.Pagination = false;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenuH(Menu menu, MenuAction action, int client, int selection)
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
			int num = StringToInt(buffer);
			switch(num)
			{
				case 1:
					Pref_Menu(client);

				case 2:
					Pref_Bosses(client);

				case 3:
					// Stuff

				case 4:
					// Stuff

				case 5:
					// Stuff

				case 6:
					Music_Menu(client);
			}
		}
	}
}

#file "Unofficial Freak Fortress 2"
