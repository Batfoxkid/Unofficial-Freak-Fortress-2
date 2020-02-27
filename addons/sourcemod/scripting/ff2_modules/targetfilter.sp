/*
	Requirement:
	bosses.sp
*/

#define FF2_TARGETFILTER

void TargetFilter_Setup()
{
	AddMultiTargetFilter("@hale", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-Boss players", false);
}

public bool BossTargetFilter(const char[] pattern, Handle clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || FindValueInArray(clients, client)!=-1)
			continue;

		if(IsBoss(client))
		{
			if(!non)
				PushArrayCell(clients, client);
		}
		else if(non)
		{
			PushArrayCell(clients, client);
		}
	}
	return true;
}
