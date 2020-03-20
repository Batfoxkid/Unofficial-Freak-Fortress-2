/*
	Optional:
	tf2x10.sp
*/

#define FF2_STATTRAK

ConVar CvarStatTrak;
ConVar CvarStatPlayers;

void StatTrak_Setup()
{
	CvarStatTrak = CreateConVar("ff2_stattrak", "0", "If to display StatTrak to players, 2 to make stats public to other players", _, true, 0.0, true, 2.0);
	CvarStatPlayers = CreateConVar("ff2_stattrak_players", "10", "How many players to enable StatTrak", _, true, 0.0, true, float(MAXTF2PLAYERS));

	CvarStatPlayers.AddChangeHook(StatTrak_CvarChange);
}

void StatTrak_Save(int client)
{
	if(!AreClientCookiesCached(client))
		return;

	char cookies[48];
	FormatEx(cookies, sizeof(cookies), "%i %i %i %i %i %i 0 0", BossWins[client], BossLosses[client], BossKills[client], BossDeaths[client], PlayerKills[client], PlayerMVPs[client]);
	SetClientCookie(client, StatCookies, cookies);
}
