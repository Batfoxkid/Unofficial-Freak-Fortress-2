#if !defined _SteamWorks_Included
  #endinput
#endif

#define FF2_STEAMWORKS

bool SteamWorks;
static bool IsEnabled;
static ConVar CvarSteamWorks;

void SteamWorks_Pre()
{
	MarkNativeAsOptional("SteamWorks_SetGameDescription");
}

void SteamWorks_Setup()
{
	CvarSteamWorks = CreateConVar("ff2_server_gamedesc", "1", "If the show 'Freak Fortress 2' in game description (requires SteamWorks)", _, true, 0.0, true, 1.0);
	SteamWorks = LibraryExists("SteamWorks");
}

void SteamWorks_Toggle(bool toggle)
{
	if(!IsEnabled && !CvarSteamWorks.BoolValue)
		return;

	if(!toggle)
	{
		SteamWorks_SetGameDescription("Team Fortress");
		IsEnabled = false;
		return;
	}

	char buffer[64];
	#if defined FF2_TIMESTEN
	FormatEx(buffer, sizeof(buffer), "Freak Fortress 2 %s(%s)", TimesTen ? "x10 " : "", PLUGIN_VERSION);
	#else
	FormatEx(buffer, sizeof(buffer), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
	#endif
	IsEnabled = true;
	SteamWorks_SetGameDescription(buffer);
}
