/*
	Top Module
*/

#define FF2_STOCKS

static const TFCond CritConditions[] =
{
	TFCond_Kritzkrieged,
	TFCond_HalloweenCritCandy,
	TFCond_CritCanteen,
	TFCond_CritOnFirstBlood,
	TFCond_CritOnWin,
	TFCond_CritOnFlagCapture,
	TFCond_CritOnKill,
	TFCond_CritMmmph,
	TFCond_CritOnDamage,
	TFCond_CritRuneTemp
};

static const TFCond MiniCritConditions[] =
{
	TFCond_Buffed,
	TFCond_CritCola,
	TFCond_NoHealingDamageBuff,
	TFCond_MiniCritOnKill
};

stock int OnlyScoutsLeft(int team)
{
	int scouts;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client)==team)
			continue;

		if(!Boss[client].Active && TF2_GetPlayerClass(client)!=TFClass_Scout)
			return 0;

		scouts++;
	}
	return scouts;
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon)) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
}

stock bool RemoveCond(int client, TFCond cond)
{
	if(!TF2_IsPlayerInCondition(client, cond))
		return false;

	TF2_RemoveCondition(client, cond);
	return true;	
}

stock int GetClientCloakIndex(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 4);
	if(!IsValidEntity(weapon))
		return -1;

	static char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if(strncmp(classname, "tf_wea", 6, false))
		return -1;

	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

stock void SpawnSmallHealthPackAt(int client, int team=0, int attacker)
{
	if(++Client[attacker].Stale[2] > 20))
		return;

	int entity = CreateEntityByName(Client[attacker].Stale[2]==1 ? "item_healthkit_medium" : "item_healthkit_small");
	if(!IsValidEntity(entity))
		return;

	DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Send, "m_iTeamNum", team, 4);
	SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	static float velocity[3] = {0.0, 0.0, 50.0};
	velocity[0] = float(GetRandomInt(-10, 10));
	velocity[1] = float(GetRandomInt(-10, 10));

	static float position[3];
	GetClientAbsOrigin(client, position);
	position[2] += 20.0;
	TeleportEntity(entity, position, NULL_VECTOR, velocity);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", attacker);
}

stock void IncrementHeadCount(int client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);

	SetEntProp(client, Prop_Send, "m_iDecapitations", GetEntProp(client, Prop_Send, "m_iDecapitations")+1);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);

	if(++Client[client].Stale[2] > 20))
		return;

	int health = GetClientHealth(client);
	int max = GetEntProp(client, Prop_Data, "m_iMaxHealth")*2;
	if(health >= max)
		return;

	health += (21-Client[client].Stale[2]);
	if(health > max)
		health = max;

	SetEntityHealth(client, health);
}

stock int FindTeleOwner(int client)
{
	int entity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	if(!IsValidEntity(entity))
		return -1;

	static char classname[32];
	if(!GetEntityClassname(entity, classname, sizeof(classname)) || !StrEqual(classname, "obj_teleporter", false))
		return -1;

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	return IsValidClient(owner, false) ? owner : -1;
}

stock bool IsPlayerCritBuffed(int client)
{
	for(int i; i<sizeof(CritConditions); i++)
	{
		if(TF2_IsPlayerInCondition(client, CritConditions[i]))
			return true;
	}
	return false;
}

stock bool IsPlayerMiniCritBuffed(int client)
{
	for(int i; i<sizeof(MiniCritConditions); i++)
	{
		if(TF2_IsPlayerInCondition(client, MiniCritConditions[i]))
			return true;
	}
	return false;
}

public Action Timer_DisguiseBackstab(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
		RandomlyDisguise(client);

	return Plugin_Continue;
}

stock TFClassType KvGetClass(Handle kv, const char[] string)
{
	static char buffer[24];
	KvGetString(kv, string, buffer, sizeof(buffer), "1");
	TFClassType class = view_as<TFClassType>(StringToInt(buffer));
	if(class != TFClass_Unknown)
		return class;

	class = TF2_GetClass(buffer);
	if(class == TFClass_Unknown)
		class = TFClass_Scout;

	return class;
}

stock void AssignTeam(int client, int team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") && Boss[client].Active)
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(KvGetClass(Special[Boss[client].Special].Kv, "class")));

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") && IsPlayerAlive(client))  //Welp
	{
		//PrintToConsoleAll("%N is a living spectator", client);
		if(IsBoss(client))
		{
			TF2_SetPlayerClass(client, KvGetClass(BossKV[Special[GetBossIndex(client)]], "class"));
		}
		else
		{
			//PrintToConsoleAll("Additional information: %N was not a boss", client);
			TF2_SetPlayerClass(client, TFClass_Heavy);
		}
		TF2_RespawnPlayer(client);
	}
}

stock void RandomlyDisguise(int client)	//Original code was mecha's, but the original code is broken and this uses a better method now.
{
	int disguiseTarget = -1;
	int team = GetClientTeam(client);

		ArrayList disguiseArray = new ArrayList();
		for(int clientcheck=1; clientcheck<=MaxClients; clientcheck++)
		{
			if(IsValidClient(clientcheck) && GetClientTeam(clientcheck)==team && clientcheck!=client)
				disguiseArray.Push(clientcheck);
		}

		if(disguiseArray.Length < 1)
		{
			disguiseTarget = client;
		}
		else
		{
			disguiseTarget = disguiseArray.Get(GetRandomInt(0, disguiseArray.Length-1));
			if(!IsValidClient(disguiseTarget))
				disguiseTarget = client;
		}
		delete disguiseArray;

		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			TF2_DisguisePlayer(client, view_as<TFTeam>(team), GetRandomInt(0, 1) ? TFClass_Medic : TFClass_Scout, disguiseTarget);
		}
		else
		{
			TF2_AddCondition(client, TFCond_Disguised, -1.0);
			SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
			SetEntProp(client, Prop_Send, "m_nDisguiseClass", GetRandomInt(0, 1) ? view_as<int>(TFClass_Medic) : view_as<int>(TFClass_Scout));
			SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguiseTarget);
			SetEntProp(client, Prop_Send, "m_iDisguiseHealth", 200);
		}
	}
}
