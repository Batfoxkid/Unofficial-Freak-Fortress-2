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
		return this.MaxSpeed+0.7*(100.0-Health(client)*100.0/this.MaxLives/this.MaxHealth));
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
	description	=	"RUUUUNN!! COWAAAARRDSS!",
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

public Action MainMenuC(int client, int args)
{
	if(client)
	{
		MainMenu(client);
		return Plugin_Handled;
	}

	PrintToServer("%s Freak Fortress 2", FORK_SUB_REVISION);
	PrintToServer("Version: %s", PLUGIN_VERSION);
	PrintToServer("Build: %s", BUILD_NUMBER);
}

void MainMenu(int client)
{
	Menu menu = new Menu(MainMenuH);
	char buffer[256];
	SetGlobalTransTarget(client);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Title");
	menu.SetTitle(buffer);

	FormatEx(buffer, sizeof(buffer), "%t", "Menu Pref");
	menu.AddItem(buffer, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Selection");
	menu.AddItem(buffer, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Help");
	menu.AddItem(buffer, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu New");
	menu.AddItem(buffer, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Queue");
	menu.AddItem(buffer, buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "Menu Music");
	menu.AddItem(buffer, buffer);

	menu.Pagination = false;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

#file "Unofficial Freak Fortress 2"
