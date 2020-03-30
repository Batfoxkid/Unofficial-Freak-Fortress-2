/*
	Functions:
	void TargetFilter_Setup()
*/

#define FF2_TARGETFILTER

void TargetFilter_Setup()
{
	AddMultiTargetFilter("@hale", TargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!hale", TargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@boss", TargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!boss", TargetFilter, "all non-Boss players", false);
}

public bool TargetFilter(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Boss[client].Active)
		{
			if(!non)
				clients.Push(client);
		}
		else if(non)
		{
			clients.Push(client);
		}
	}
	return true;
}
