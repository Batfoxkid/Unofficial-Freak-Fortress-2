/*
	Requires:
	sdkhooks

	Functions:
	void Stomp_Setup()
*/

#define FF2_STOMP

static ConVar Cvar;

void Stomp_Setup()
{
	Cvar = CreateConVar("ff2_boss_goomba", "300.0", "How much jump power upon Goomba stomping a boss", _, true, 0.0);
}

public Action OnStomp(int attacker, int victim, float &multi, float &damage, float &power)
{
	if(Enabled <= Game_Disabled)
		return Plugin_Continue;

	if(Boss[victim].Active)
	{
		int health;
		int team = GetClientTeam(victim);
		for(int i=1; i<=MaxClients; i++)
		{
			if(i==victim || (Boss[i].Active && GetClientTeam(i)==team))
				health += Boss[i].MaxHealth*Boss[i].MaxLives;
		}

		multi = 0.0;
		#if defined FF2_TIMESTEN
		damage = Pow(float(health), 0.65-(Client[attacker].Goombas[victim]++*0.005))*(1.0+(0.5*(TimesTen_Value()-1.0)));
		#else
		damage = Pow(float(health), 0.65-(Client[attacker].Goombas[victim]++*0.005));
		#endif
		power = Cvar.FloatValue;
	}
	else if(Boss[attacker].Active)
	{
		power = 0.0;
	}
	else
	{
		return Plugin_Continue;
	}

	int flags;
	if(OnTakeDamageAlive(victim, attacker, attacker, damage, flags, attacker, NULL_VECTOR, NULL_VECTOR, TF_CUSTOM_BOOTS_STOMP) > Plugin_Changed)
		return Plugin_Handled;

	return Plugin_Changed;
}

public int OnStompPost(int attacker, int victim, float multi, float damage, float power)
{
	if(Enabled <= Game_Disabled)
		return;

	static char buffer[64];
	if(Boss[victim].Active)
	{
		CfgGetLang(Special[Boss[victim].Special].Cfg, "character.name", buffer, sizeof(buffer), attacker);
	}
	else
	{
		GetClientName(victim, buffer, sizeof(buffer));
	}

	if(Boss[attacker].Active)
	{
		PrintHintText(attacker, "%t", "Goomba Stomp", buffer);
		CfgGetLang(Special[Boss[attacker].Special].Cfg, "character.name", buffer, sizeof(buffer), victim);
	}
	else
	{
		PrintHintText(attacker, "%t", "Goomba Stomps", buffer, Client[attacker].Goombas[victim]);
		GetClientName(attacker, buffer, sizeof(buffer));
	}
	PrintHintText(victim, "%t", "Goomba Stomped", buffer);
}
