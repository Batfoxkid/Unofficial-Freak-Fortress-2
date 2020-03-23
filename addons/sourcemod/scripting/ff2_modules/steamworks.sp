/*
	Optional:
	tf2x10.sp

	Functions:
	void SteamWorks_Pre()
	void SteamWorks_Setup()
	void SteamWorks_Toggle(bool toggle)
	void SteamWorks_Client(int client)
*/

#if !defined _SteamWorks_Included
  #endinput
#endif

#define FF2_STEAMWORKS

#define PLAYERURL "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/"

bool SteamWorks;
static bool IsEnabled;
static ConVar CvarSteamWorks;
static ConVar CvarKey;
static char Key[64];

void SteamWorks_Pre()
{
	MarkNativeAsOptional("SteamWorks_SetGameDescription");

	#if defined _jansson_included_
	MarkNativeAsOptional("SteamWorks_CreateHTTPRequest");
	MarkNativeAsOptional("SteamWorks_SetHTTPRequestGetOrPostParameter");
	MarkNativeAsOptional("SteamWorks_SetHTTPRequestContextValue");
	MarkNativeAsOptional("SteamWorks_SetHTTPCallbacks");
	MarkNativeAsOptional("SteamWorks_SendHTTPRequest");
	MarkNativeAsOptional("SteamWorks_GetHTTPResponseBodySize");
	MarkNativeAsOptional("SteamWorks_GetHTTPResponseBodyData");
	MarkNativeAsOptional("json_load");
	MarkNativeAsOptional("json_object_get");
	MarkNativeAsOptional("json_array_get");
	MarkNativeAsOptional("json_object_get_int");
	#endif
}

void SteamWorks_Setup()
{
	CvarSteamWorks = CreateConVar("ff2_server_gamedesc", "1", "If the show 'Freak Fortress 2' in game description (requires SteamWorks)", _, true, 0.0, true, 1.0);
	SteamWorks = LibraryExists("SteamWorks");

#if defined _jansson_included_
	CvarKey = CreateConVar("ff2_server_steamapikey", "", "If API key is set, will make StatTrak private to those with private profiles (requires SteamWorks and SMJansson)", FCVAR_PROTECTED);
	CvarKey.AddChangeHook(SteamWorks_KeyChange);
}

// Overkill key protection?
public void SteamWorks_KeyChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(Key, sizeof(Key), newValue);
	cvar.RemoveChangeHook(SteamWorks_KeyChange);
	cvar.SetString("");
	cvar.AddChangeHook(SteamWorks_KeyChange);
#endif
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

void SteamWorks_Client(int client)
{
#if defined _jansson_included_
	if(!Key[0] || !IsEnabled || GetFeatureStatus(FeatureType_Native, "json_load")!=FeatureStatus_Available)
	{
		Client[client].Private = false;
		return;
	}

	Client[client].Private = true;

	static char buffer[64];
	if(!GetClientAuthId(client, AuthId_SteamID64, buffer, sizeof(buffer))
		return;

	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, PLAYERURL);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "key", Key);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "steamids", buffer);
	SteamWorks_SetHTTPRequestContextValue(request, GetClientUserId(client));
	SteamWorks_SetHTTPCallbacks(request, SteamWorks_Finish);
	if(!SteamWorks_SendHTTPRequest(request))
		delete request;
}

public int SteamWorks_Finish(Handle request, bool failed, bool success, EHTTPStatusCode status, int userid)
{
	if(success && status==k_EHTTPStatusCode200OK)
	{
		int length;
		SteamWorks_GetHTTPResponseBodySize(request, length);
		if(length > 2047)
			return;

		char[] buffer = new char[length];
		SteamWorks_GetHTTPResponseBodyData(hRequest, buffer, length);

		Handle json = json_load(sBody);
		Handle response = json_object_get(json, "response");
		Handle players = json_object_get(response, "players");
		Handle player = json_array_get(players, 0);
		if(player == INVALID_HANDLE)
			return;

		int state = json_object_get_int(player, "communityvisibilitystate");
		if(player == INVALID_HANDLE)
			return;

		Client[client].Private = (state!=3 || json_object_get_int(player, "profilestate")!=1);
	}

	delete request;
#else
	Client[client].Private = false;
#endif
}