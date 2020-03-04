/*
	Requirement:
	bosses.sp
*/

#define FF2_MUSIC

#define MAXSONGS	10

int BGMs;
char BGMPath[MAXSONGS][PLATFORM_MAX_PATH];
float BGMTime[MAXSONGS]
char BGMName[MAXSONGS][64];
char BGMArtist[MAXSONGS][64];

void Music_Setup()
{
	BGMs = 0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(Boss[client].Active)
			AddMusicTracks(Boss[client].Special);
	}
}

static void AddMusicTracks(int boss)
{
	Special[boss].Kv.Rewind();
	if(!Special[boss].Kv.JumpToKey("sound_bgm"))
		return;

	char filepath[PLATFORM_MAX_PATH], key[8];
	if(Special[boss].Kv.GoFirstSubKey())
	{
		do
		{
		} while(BGMs<MAXSONGS && Special[boss].Kv.GotoNextKey())
	}
}
