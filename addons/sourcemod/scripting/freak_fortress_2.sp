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

/*
	Performance Changes

	This is mainly for server
	specific features that can
	be changed per community.
	This can help some low-end
	machines or high populated
	servers.
*/
#define SETTING_HUDDELAY	0.25	// Interval of clients' HUD
#define SETTING_TICKMODE	-1	// -1 for OnGameFrame, 0 for OnPlayerRunCmdPost, >0 for a Timer with that duration


#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <freak_fortress_2>
#include <colorlib>
#include <sdkhooks>
#include <tf2_stocks>
#undef REQUIRE_EXTENSIONS
#tryinclude <dhooks>
#tryinclude <tf2items>
#tryinclude <SteamWorks>
#tryinclude <smjansson>
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
#define FORK_DEV_REVISION	"Alpha"
#define FORK_DATE_REVISION	"SoonTM"

#define BUILD_NUMBER	FORK_MINOR_REVISION...""...FORK_STABLE_REVISION..."000"

#if defined FORK_DEV_REVISION
	#define PLUGIN_VERSION	FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION..." "...FORK_DEV_REVISION
#else
	#define PLUGIN_VERSION	FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION
#endif

#define MAJOR_REVISION	"1"
#define MINOR_REVISION	"11"
#define STABLE_REVISION	"0"
#define DEV_REVISION	"Beta"
#define DATE_REVISION	"--Unknown--"

#define CHANGELOG_URL	"https://batfoxkid.github.io/Unofficial-Freak-Fortress-2"
#define MAP_FILE	"data/freak_fortress_2/maps.cfg"

#define MAXENTITIES	2048
#define MAXSPECIALS	1024
#define MAXTF2PLAYERS	36

#define HUD_DAMAGE	(1 << 0)
#define HUD_ITEM	(1 << 1)
#define HUD_HEALTH	(1 << 2)
#define HUD_MESSAGE	(1 << 3)

enum
{
	Pref_Undef = 0,	// Default Value
	Pref_On,	// Enabled
	Pref_Off,	// Disabled
	Pref_Temp,	// Disabled for the map duration or current round

	Pref_Music = 0,	// Boss Music
	Pref_Voice,	// Boss Voicelines
	Pref_Help,	// Class Info
	Pref_Boss,	// Boss Toggle
	Pref_Duo,	// Companion Toggle
	Pref_Diff,	// Special Toggle or Difficulty Setting
	Pref_Dmg,	// Damage Tracker Players
	Pref_DmgPos,	// Damage Tracker Position
	Pref_Hud,	// HUD Flags
	Pref_MAX,

	RageMode_Full = 0,	// Take all of rage
	RageMode_Part,		// Take only required amount
	RageMode_None,		// Disable using rage

	Stat_Win = 0,	// Boss Wins
	Stat_Lose,	// Boss Loses
	Stat_Kill,	// Boss Kills
	Stat_Death,	// Boss Deaths
	Stat_MAX,
	Stat_Slain = 4,	// Killed Bosses
	Stat_Mvp,	// MVP Count

	Game_Invalid = 0,	// Unknown Type
	Game_Disabled,		// No Assets
	Game_Fun,		// Bosses Only
	Game_Arena,		// Full Gamemode
	Game_MAX
}

enum struct BossEnum
{
	bool Active;
	bool Leader;
	int Special;
	TFClassType Class;

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
	float Hazard;

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
	char Voice[PLATFORM_MAX_PATH];
	float BGMAt;
	float GlowFor;
	float PopUpAt;
	int Damage;
	int Queue;
	int Selection;
	int Pref[Pref_MAX];
	int Kills[view_as<int>(TFClassType)];
	int Mvps[view_as<int>(TFClassType)];
	int Stat[Stat_MAX];
	int Goombas[MAXTF2PLAYERS];
	bool DisableHud;

	bool Private;
	bool Cached;
}

enum struct WeaponEnum
{
	int Crit;
	int Shield;
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

#include "ff2_modules/configmap.sp"

enum struct SpecialEnum
{
	ConfigMap Cfg;
	int Charset;
	bool Precached;
	char File[PLATFORM_MAX_PATH];
}

SpecialEnum Special[MAXSPECIALS];
ArrayList BossList;
int Specials;

bool LastMann;
int Enabled;
int NextGamemode;
int ArenaRoundsLeft;
int Players;
int BossPlayers;
int MercPlayers;
int Override;
float HealthBarFor;
TFTeam BossTeam;
ArrayList Charsets;
int Charset;

WeaponEnum Weapon[MAXTF2PLAYERS][3];
ClientEnum Client[MAXTF2PLAYERS];
BossEnum Boss[MAXTF2PLAYERS];

ConVar CvarVersion;
ConVar CvarEnabled;
ConVar CvarDebug;

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

void MainMenu(int client) { MainMenuC(client, 0); }

#include "ff2_modules/stocks.sp"
#include "ff2_modules/preference.sp"
#tryinclude "ff2_modules/dhooks.sp"
#tryinclude "ff2_modules/doors.sp"
#tryinclude "ff2_modules/music.sp"
#tryinclude "ff2_modules/rtd.sp"
#tryinclude "ff2_modules/stattrak.sp"
#tryinclude "ff2_modules/targetfilter.sp"
#tryinclude "ff2_modules/tf2x10.sp"
#tryinclude "ff2_modules/tf2attributes.sp"
#tryinclude "ff2_modules/tts.sp"
#tryinclude "ff2_modules/weapons.sp"

#include "ff2_modules/formula.sp"	// tf2x10
#include "ff2_modules/sdkhooks.sp"	// dhooks, tts, tf2attributes
#tryinclude "ff2_modules/tf2items.sp"	// weapons
#tryinclude "ff2_modules/steamworks.sp"	// tf2x10

#include "ff2_modules/bosses.sp"	// convars, sdkhooks, tf2items
#tryinclude "ff2_modules/stomp.sp"	// sdkhooks

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

/*
	Setup Events
*/

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

	CvarVersion = CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CvarEnabled = CreateConVar("ff2_enabled", "1", "Backwards Compatibility ConVar", FCVAR_DONTRECORD, true, 0.0, true, 2.0);
	CvarDebug = CreateConVar("ff2_debug", "1", "If to display debug outputs", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	CreateConVar("ff2_oldjump", "1", "Backwards Compatibility ConVar", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	CreateConVar("ff2_base_jumper_stun", "0", "Backwards Compatibility ConVar", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	CreateConVar("ff2_solo_shame", "0", "Backwards Compatibility ConVar", FCVAR_DONTRECORD, true, 0.0, true, 1.0);

	Override = -1;
	ArenaRoundsLeft = -1;

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

	#if defined FF2_STATTRAK
	StatTrak_Setup();
	#endif

	SDK_Setup();
	Bosses_Setup();
	Pref_Setup();

	#if defined FF2_STOMP
	Stomp_Setup();
	#endif

	#if defined FF2_TTS
	TTS_Setup();
	#endif

	#if defined FF2_TARGETFILTER
	TargetFilter_Setup();
	#endif

	HookEvent("teamplay_round_start", OnRoundSetup, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd);

	HookEvent("teamplay_point_startcapture", OnStartCapture, EventHookMode_PostNoCopy);
	HookEvent("teamplay_capture_broken", OnBreakCapture);

	HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Pre);
	HookEvent("player_healed", OnPlayerHealed, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("player_chargedeployed", OnUberDeployed);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Pre);
	HookEvent("rps_taunt_event", OnRPS);

	AddCommandListener(OnJoinTeam, "jointeam");
	AddCommandListener(OnAutoTeam, "autoteam");

	AutoExecConfig(true, "FreakFortress2");

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("freak_fortress_2_weapons.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	for(int client; client<MAXTF2PLAYERS; client++)
	{
		ResetClientVars(client);
		if(IsValidClient(client))
			OnClientPostAdminCheck(client);
	}
}

public void OnPluginEnd()
{
	OnMapEnd();
	//hostName.SetString(oldName);
	if(Enabled!=Game_Arena || CheckRoundState()!=1)
		return;

	ForceTeamWin(0);
	FPrintToChatAll("%t", "Unloaded");
}

public void OnMapStart()
{
	if(FileExists("sound/saxton_hale/9000.wav", true))
	{
		AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
		PrecacheSound("saxton_hale/9000.wav", true);
	}

	#if SETTING_TICKMODE>0
	CreateTimer(SETTING_TICKMODE, OnGameTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	#endif
}

public void OnMapEnd()
{
	if(Enabled || Enabled2)
		DisableFF2();
}

public void OnConfigsExecuted()
{
	CvarVersion.SetString(PLUGIN_VERSION);

	char buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	if(CvarEnabled.BoolValue)
	{
		int gamemode = CheckGamemode(buffer);
		if(gamemode == Game_Invalid)
		{
			Enabled = CvarEnabled.IntValue==2 ? Game_Arena : Game_Disabled;
		}
		else
		{
			Enabled = gamemode;
		}
	}
	else
	{
		Enabled = Game_Disabled;
	}

	RoundCount = 

	#if defined FF2_STEAMWORKS
	if(Enabled == Game_Arena)
		SteamWorks_Toggle(true);
	#endif

	#if defined FF2_WEAPONS
	Weapons_Setup();
	#endif

	#if defined FF2_TTS
	TTS_Check(buffer);
	#endif

	Bosses_Config();
}

/*
	Player Events
*/

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);

	#if defined FF2_STEAMWORKS
	SteamWorks_Client(client);
	#endif

	Pref_SetupClient(client, GetEngineTime());
}

public void OnClientDisconnect(int client)
{
	Pref_SaveClient(client);
	ResetClientVars(client);
}

public Action OnJoinTeam(int client, const char[] command, int args)
{
	if(!args)
		return Plugin_Continue;

	if(Boss[client].Active)
		return Plugin_Handled;

	if(Enabled != Game_Arena)
		return Plugin_Continue;

	int state = CheckRoundState();
	if(state == -1)
		return Plugin_Continue;

	if(GetClientTeam(client) > view_as<int>(TFTeam_Spectator))
	{
		if(GetConVarBool(FindConVar("mp_allowspectators"))
		{
			static char buffer[10];
			GetCmdArg(1, buffer, sizeof(buffer));
			if(StrEqual(buffer, "spectate", false))
				ChangeClientTeam(client, view_as<int>(TFTeam_Spectator));
		}
		return Plugin_Handled;
	}
	
	ChangeClientTeam(client, Client[client].Team);
	if(state != 1)
		ShowVGUIPanel(client, Client[client].Team==TFTeam_Red ? "class_red" : "class_blue");

	return Plugin_Handled;
}

public Action OnAutoTeam(int client, const char[] command, int args)
{
	if(Enabled!=Game_Arena || CheckRoundState()==-1)
		return Plugin_Continue;

	if(GetClientTeam(client) > view_as<int>(TFTeam_Spectator))
		return Plugin_Handled;

	ChangeClientTeam(client, Client[client].Team);
	ShowVGUIPanel(client, Client[client].Team==TFTeam_Red ? "class_red" : "class_blue");
	return Plugin_Handled;
}

/*
	Game Events
*/

public void OnRoundSetup(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled <= Game_Disabled)
		return;

	float gameTime = GetGameTime();
	static float time;
	if(time > gameTime)	// teamplay_round_start can fire twice sometimes...
		return;

	time = gameTime+1.0;
	for(int client; client<MAXTF2PLAYERS; client++)
	{
		Boss[client].Active = false;
		Client[client].Minion = false;
		Client[client].Voice[0] = 0;
		Client[client].Damage = 0;
		for(int i; i<MAXTF2PLAYERS; i++)
		{
			Client[client].Goombas[i] = 0;
		}
	}

	if(NextGamemode != Game_Invalid)
	{
		Enabled = NextGamemode;
		NextGamemode = Game_Invalid;
		if(Enabled == Game_Disabled)
			return;
	}

	#if defined FF2_TTS
	TTS_Start();
	#endif
/*
		if(IsValidClient(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
		{
			Players++;
			if(!IsFakeClient(client))
				playing2++;

			if(IsBoss(client))
				bosses++;

			if(GetClientTeam(client)==BossTeam)
			{
				playingboss++;
			}
			else
			{
				playingmerc++;
			}
		}
	}
*/
	if(Enabled != Game_Arena)
		return;

	int client = GetNextBossPlayer();
	if(!client)
	{
		Enabled = Game_Fun;
		NextGamemode = Game_Arena;
		return;
	}

	Boss[client].Active = true;
	Boss[client].Special = Client[client].Selection;
	Bosses_Create(client);

	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		if(Boss[client].Active)
		{
			AssignTeam(client, view_as<int>(Boss[client].Team));
			continue;
		}

		if(GetClientTeam(client) == BossTeam)
			Client[client].RefreshAt = gameTime+0.1;
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && (GetClientTeam(client)!=OtherTeam && !Enabled3))
			CreateTimer(0.1, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled <= Game_Disabled)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client) || !Boss[client].Active)
		return Plugin_Continue;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("damageamount");
	int custom = event.GetInt("custom");
	if(!(custom & TF_CUSTOM_BACKSTAB) && !(custom & TF_CUSTOM_COMBO_PUNCH) && !(custom & TF_CUSTOM_TELEFRAG) && event.GetBool("minicrit") && event.GetBool("allseecrit"))
		event.SetBool("allseecrit", false);

	if(custom == TF_CUSTOM_BOOTS_STOMP)
		event.SetInt("damageamount", damage*5);
}

#if SETTING_TICKMODE>0
public Action OnGameTimer(Handle timer)
#elseif SETTING_TICKMODE<0
public void OnGameFrame()
#else
public void OnPlayerRunCmdPost(int nullVar1, int nullVar2, int nullVar3, const float nullVar4[3], const float nullVar5[3], int nullVar6, int nullVar7, int nullVar8, int nullVar9, int nullVar0, const int nullVar[2])
#endif
{
	if(Enabled <= Game_Disabled)
		return;

	float engineTime = GetEngineTime();

	static float hudAt;
	if(hudAt > engineTime)
		return;

	hudAt = engineTime+SETTING_HUDDELAY;
	float gameTime = GetGameTime();
	if(Enabled == Game_Arena)
	{
		int roundState = CheckRoundState();
		if(!roundState || roundState==2)
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(!IsValidClient(client))
					continue;

				if(Client[client].RefreshAt < gameTime)
				{
					Client[client].RefreshAt = FAR_FUTURE;
					if(alive && !Client[client].Minion)
						RefreshClient(client);
				}
			}
			return;
		}
	}

	bool sappers, found;
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
			found = true;
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

	if(Enabled==Game_Fun && !found)
		return;

	char bestHud[10][48];
	for(int i; i<10; i++)
	{
		if(!best[i])
			break;

		FormatEx(bestHud[i], sizeof(bestHud[]), "[%i] %N: %i", i+1, best[i], Client[best[index]].Damage);
	}

	#if defined FF2_STATTRAK
	int stattrack = StatEnabled ? CvarStatTrak.IntValue : 0;
	#else
	int stattrak;
	#endif
	char buffer[256];
	for(int i; i<max; i++)
	{
		bool alive = IsPlayerAlive(clients[i]);
		int buttons = GetClientButtons(clients[i]);
		if(!Client[clients[i]].DisableHud && !(Client[clients[i]] & HUD_DAMAGE) && !(buttons & IN_SCORE) && (alive || IsClientObserver(clients[i]))
		{
			int observer;
			if(alive)
			{
				observer = GetClientAimTarget(clients[i], true);
				if(observer!=clients[i] && IsValidClient(observer))
				{
					int team = GetClientTeam(clients[i]);
					if(GetClientTeam(observer) != team)
					{
						if(TF2_IsPlayerInCondition(observer, TFCond_Disguised) && !IsPlayerInvis(observer))
						{
							observer = GetEntProp(observer, Prop_Send, "m_iDisguiseTargetIndex");
							if(!IsValidClient(observer) || GetClientTeam(observer)!=team)
								observer = 0;
						}
						else
						{
							observer = 0;
						}
					}

					if(observer)
					{
						static float position[3], position2[3];
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
						GetEntPropVector(observer, Prop_Send, "m_vecOrigin", position2);
						if(GetVectorDistance(position, position2) > 800)
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

			SetGlobalTransTarget(client);

			if(observer)
			{
				if(!Boss[client].Active)
				{
					FormatEx(buffer, sizeof(buffer), "%t", "Hud Stats Spec", "It Is You", Client[client].Damage, Client[client].Healing, Client[client].Assist);
				}
				else if(stattrack)
				{
					FormatEx(buffer, sizeof(buffer), "%t", "Hud Boss Spec", "It Is You", Client[client].Stat[Stat_Win], Client[client].Stat[Stat_Lose], Client[client].Stat[Stat_Kill], Client[client].Stat[Stat_Death]);
				}
				else
				{
					buffer[0] = 0;
				}

				static char buffer2[64];
				if(!Boss[observer].Active)
				{
					GetClientName(client, buffer2, sizeof(buffer2));
					SetHudTextParams(-1.0, 0.83, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
					ShowSyncHudText(client, HudDamage, "%t\n%s", "Hud Stats Spec", buffer2, Client[observer].Damage, Client[observer].Healing, Client[observer].Assist, buffer);
				}
				else if(stattrack == 2)
				{
					GetClientName(client, buffer2, sizeof(buffer2));
					SetHudTextParams(-1.0, 0.83, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
					ShowSyncHudText(client, HudDamage, "%t\n%s", "Hud Boss Spec", buffer2, Client[observer].Stat[Stat_Win], Client[observer].Stat[Stat_Lose], Client[observer].Stat[Stat_Kill], Client[observer].Stat[Stat_Death], buffer);
				}
				else if(buffer[0])
				{
					SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
					ShowSyncHudText(client, HudDamage, buffer);
				}
			}
			else if(!Boss[client].Active)
			{
				SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
				FormatEx(buffer, sizeof(buffer), "%t", "Hud Stats", Client[client].Damage, Client[client].Healing, Client[client].Assist);
			}
			else if(stattrak)
			{
				SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
				FormatEx(buffer, sizeof(buffer), "%t", "Hud Boss", Client[client].[Stat_Win], Client[client].Stat[Stat_Lose], Client[client].Stat[Stat_Kill], Client[client].Stat[Stat_Death]);
			}
		}

		#if defined FF2_MUSIC
		if(Client[client].BGMAt < engineTime)
			Music_Play(client, engineTime, -1);
		#endif

		if(Client[client].PopUpAt < engineTime)
		{
			Client[client].PopUpAt = FAR_FUTURE;
			if(Client[client].Pref[Pref_Boss] == Pref_Undef)
				Pref_QuickToggle(client, -2);
		}

		if(Client[client].RefreshAt < gameTime)
		{
			Client[client].RefreshAt = FAR_FUTURE;
			if(alive && !Client[client].Minion)
				RefreshClient(client);
		}

		if(!alive)
			continue;

		if(!Client[client].GlowFor)
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
}

/*
	Functions
*/

int CheckGamemode(const char[] map)
{
	static char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), MAP_FILE);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), MAP_FILE);
		if(!FileExists(config))
		{
			LogToFile(eLog, "[Maps] Unable to find '%s'", MAP_FILE);
			return Game_Invalid;
		}
	}

	int result = Game_Invalid;
	KeyValues kv = new KeyValues("maps");
	if(kv.ImportFromFile(config))
	{
		do
		{
			kv.GetSectionName(buffer, sizeof(buffer));
			int amount = ReplaceString(buffer, sizeof(buffer), "*", "");
			switch(amount)
			{
				case 0:
				{
					if(!StrEqual(map, buffer, false))
						continue;
				}
				case 1:
				{
					if(StrContains(map, buffer, false))
						continue;
				}
				default:
				{
					if(StrContains(map, buffer, false) == -1)
						continue;
				}
			}

			#if defined FF2_DOORS
			result = kv.GetNum("doors", -1);
			DoorEnabled = result ? result<0 ? Doors_Check(map) : true : false;
			#endif

			#if defined FF2_TTS
			float tts = kv.GetFloat("hazard", -1.0);
			TTSEnabled = tts<0 ? TTS_Check(map) : tts;
			#endif

			result = kv.GetNum("mode", 0)+2;
			if(result<=Game_Invalid || result>=Game_MAX)
				result = Game_Invalid;

			break;
		} while(kv.GotoNextKey());
	}
	else
	{
		File file = OpenFile(config, "r");
		if(file == INVALID_HANDLE)
		{
			LogToFile(eLog, "[Maps] Error reading from '%s'", MAP_FILE);
		}
		else
		{
			int tries;
			while(file.ReadLine(config, sizeof(config)))
			{
				tries++;
				if(tries >= 100)
				{
					LogToFile(eLog, "[Maps] An infinite loop occurred while trying to check the map");
					break;
				}

				strcopy(config, strlen(config)-1, config);
				if(!strncmp(config, "//", 2, false))
					continue;

				if(!StrContains(map, config, false) || !StrContains(config, "all", false))
				{
					result = Game_Arena;
					break;
				}
			}
			delete file;
		}
	}
	delete kv;
	return result;
}

void GameOverScreen(TFTeam winner, float duration)
{
	int leader = GetZeroBoss();
	if(leader != -1)
	{
		if(team == BossTeam)
		{
			PlayBossSound(leader, "sound_win", 1, _, false);
			if(!PlayBossSound(leader, "sound_outtromusic_win", 2))
				PlayBossSound(leader, "sound_outtromusic", 2);
		}
		else if(team)
		{
			if(!PlayBossSound(leader, "sound_outtromusic_lose", 2))
				PlayBossSound(leader, "sound_outtromusic", 2);
		}
		else
		{
			if(IsPlayerAlive(leader))
				PlayBossSound(leader, "sound_stalemate", 1, _, false);

			if(!PlayBossSound(leader, "sound_outtromusic_stalemate", 2))
			{
				if(!PlayBossSound(leader, "sound_outtromusic_lose", 2))
					PlayBossSound(leader, "sound_outtromusic", 2);
			}
		}
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
		}
	}
}

void RefreshClient(int client)
{
	if(Boss[client].Active)
	{
		if(!IsVoteInProgress())
			Boss_Info(client);

		Boss[client].Leader = false;
		Bosses_Create(client);
	}

	if(Client[client].Pref[Pref_Help]<Toggle_Off && !IsVoteInProgress())
		Weapons_Info(client);

	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
	Client[client].Team = BossTeam==TFTeam_Blue ? TFTeam_Red : TFTeam_Blue;
	AssignTeam(client, view_as<int>(Client[client].Team));
	RequestFrame(Weapons_Check, GetClientUserId(client));
}

void ResetClientVars(int client)
{
	Client[client].BGMAt = FAR_FUTURE;
	Client[client].PopUpAt = FAR_FUTURE;
	Client[client].GlowFor = 0.0;
	Client[client].RefreshAt = FAR_FUTURE;
	#if !defined FF2_STEAMWORKS
	Client[client].Private = false;
	#endif

	Boss[client].Active = false;
}

public Action MainMenuC(int client, int args)
{
	if(client)
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

		#if defined FF2_STATTRAK
		FormatEx(buffer, sizeof(buffer), "%t", "Menu Stats");
		menu.AddItem("7", buffer);
		#endif

		menu.Pagination = false;
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
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
	#if defined FORK_SUB_REVISION
	PrintToServer("Date: %s", FORK_DATE_REVISION);
	#else
	PrintToServer("Date: %s", DATE_REVISION);
	#ebduf
	PrintToServer("Status: %s", Enabled>Game_Disabled ? "Enabled" : "Disabled");

	PrintToServer("");

	#if defined FF2_DHOOKS
	PrintToServer("DHooks: %s", GetFeatureStatus(FeatureType_Native, "DHookCreateDetour")==FeatureStatus_Available ? "Enabled" : GetFeatureStatus(FeatureType_Native, "DHookCreate")==FeatureStatus_Available ? "Incorrect Version" : "Library Not Found");
	#elseif defined _dhooks_included
	PrintToServer("DHooks: Module Not Compiled");
	#else
	PrintToServer("DHooks: Include Not Compiled");
	#endif

	#if defined FF2_DOORS
	PrintToServer("Doors: %s", DoorEnabled ? "Enabled" : "Disabled");
	#else
	PrintToServer("Doors: Module Not Compiled");
	#endif

	#if defined FF2_MUSIC
	PrintToServer("Music: %s", BGMs>0 ? "Enabled" : "Disabled");
	#else
	PrintToServer("Music: Module Not Compiled");
	#endif

	#if defined FF2_STEAMWORKS
	PrintToServer("SMJansson: %s", GetFeatureStatus(FeatureType_Native, "json_load")==FeatureStatus_Available ? "Enabled" : "Library Not Found");
	#elseif defined _jansson_included_
	PrintToServer("SMJansson: Module Not Compiled");
	#else
	PrintToServer("SMJansson: Include Not Compiled");
	#endif

	#if defined FF2_STATTRAK
	PrintToServer("StatTrak: %s", StatEnabled ? "Enabled" : "Disabled");
	#else
	PrintToServer("StatTrak: Module Not Compiled");
	#endif

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
	PrintToServer("TF2x10: %s", TimesTen ? "Enabled" : "Library Not Found");
	#else
	PrintToServer("TF2x10: Module Not Compiled");
	#endif

	#if defined FF2_TTS
	PrintToServer("Teleport-to-Spawn: %s", TTSEnabled ? "Enabled" : "Disabled");
	#else
	PrintToServer("Teleport-to-Spawn: Module Not Compiled");
	#endif

	#if defined FF2_WEAPONS
	PrintToServer("Weapons: %s", WeaponKV==null ? "Disabled" : "Enabled");
	#else
	PrintToServer("Weapons: Module Not Compiled");
	#endif

	PrintToServer("");
	PrintToServer("Weapon Attributes: %s", statusCheck ? "OK" : "TF2Attributes nor TF2Items are available");
	PrintToServer("Wearable Weapons: %s", SDKEquipWearable==null ? "Failed to create call via Gamedata" : "OK");
	PrintToServer("Boss KeyValues: %s", Enabled>Game_Disabled ? Special[0].Cfg==null ? "Failed to create boss ConfigMap" : "OK" : "N/A");
	#if defined FF2_WEAPONS
	PrintToServer("Weapon KeyValues: %s", Enabled>Game_Disabled ? WeaponKV==null ? "Failed to create weapon KeyValues" : "OK" : "N/A");
	#endif
	return Plugin_Handled;
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

				#if defined FF2_STATTRAK
				case 7:
					StatTrak_Command(client, 0);
				#endif
			}
		}
	}
}

#file "Unofficial Freak Fortress 2"
