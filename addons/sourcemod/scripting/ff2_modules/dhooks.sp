/*
	Functions:
	void DHook_Setup(GameData gameData)
	void DHook_MapStart()

	Credits:
	Ragenewb - RegenThink/AllowedToHealTarget/CouldHealTarget
	Redsun Servers - SetWinningTeam/RoundRespawn
	Slender Fortress - IsInTraining
*/

#if !defined _dhooks_included
  #endinput
#endif

#define FF2_DHOOKS

float EndHudAt;

Handle StartHook;
Handle TrainHook;
static Handle TeamHook;

void DHook_Setup(GameData gameData)
{
	if(GetFeatureStatus(FeatureType_Native, "DHookCreateDetour") != FeatureStatus_Available)
		return;

	Handle hook = DHookCreateDetourEx(gameData, "CTFPlayer::RegenThink", CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	if(hook)
	{
		if(!DHookEnableDetour(hook, false, DHook_Regen))
			LogError2("[Gamedata] Could not enable detour for CTFPlayer::RegenThink");
	}
	else
	{
		LogError2("[Gamedata] Could not find CTFPlayer::RegenThink");
	}

	hook = DHookCreateDetourEx(gameData, "CWeaponMedigun::AllowedToHealTarget", CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if(hook)
	{
		DHookAddParam(hook, HookParamType_CBaseEntity);
		if(!DHookEnableDetour(hook, false, DHook_Healing))
			LogError2("[Gamedata] Could not enable detour for CWeaponMedigun::AllowedToHealTarget");
	}
	else
	{
		LogError2("[Gamedata] Could not find CWeaponMedigun::AllowedToHealTarget");
	}

	hook = DHookCreateDetourEx(gameData, "CObjectDispenser::CouldHealTarget", CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if(hook)
	{
		DHookAddParam(hook, HookParamType_CBaseEntity);
		if(!DHookEnableDetour(hook, false, DHook_Healing))
			LogError2("[Gamedata] Could not enable detour for CObjectDispenser::CouldHealTarget");
	}
	else
	{
		LogError2("[Gamedata] Could not find CObjectDispenser::CouldHealTarget");
	}

	int offset = gameData.GetOffset("CTFGameRules::SetWinningTeam");
	TeamHook = DHookCreate(offset, HookType_GameRules, ReturnType_Void, ThisPointer_Ignore);
	if(TeamHook)
	{
		DHookAddParam(TeamHook, HookParamType_Int);
		DHookAddParam(TeamHook, HookParamType_Int);
		DHookAddParam(TeamHook, HookParamType_Bool);
		DHookAddParam(TeamHook, HookParamType_Bool);
		DHookAddParam(TeamHook, HookParamType_Bool);
		DHookAddParam(TeamHook, HookParamType_Bool);
	}
	else
	{
		LogError2("[Gamedata] Could not find CTFGameRules::SetWinningTeam");
	}

	offset = gameData.GetOffset("CTeamplayRoundBasedRules::RoundRespawn");
	StartHook = DHookCreate(offset, HookType_GameRules, ReturnType_Void, ThisPointer_Ignore);
	if(!StartHook)
		LogError2("[Gamedata] Could not find CTeamplayRoundBasedRules::RoundRespawn");

	offset = gameData.GetOffset("CTFGameRules::IsInTraining");
	TrainHook = DHookCreate(offset, HookType_GameRules, ReturnType_Bool, ThisPointer_Address);
	if(!TrainHook)
		LogError2("[Gamedata] Could not find CTFGameRules::IsInTraining");
}

void DHook_MapStart()
{
	if(TeamHook)
		DHookGamerules(TeamHook, false, _, DHook_SetWinningTeam);

	if(StartHook)
		DHookGamerules(StartHook, false, _, DHook_RoundSetup);

	if(TrainHook)
		DHookGamerules(TrainHook, false, _, DHook_Training);
}

public MRESReturn DHook_Regen(int client)
{
	if(Enabled<=Game_Disabled || !Boss[client].Active || Boss[client].Healing || TF2_GetPlayerClass(client)!=TFClass_Medic)
		return MRES_Ignored;

	return MRES_Supercede;
}

public MRESReturn DHook_Healing(int client, Handle handle, Handle params)
{
	if(Enabled <= Game_Disabled)
		return MRES_Ignored;

	int target = DHookGetParam(params, 1);
	if(target<1 || target>MaxClients)
		return MRES_Ignored;

	if(!Boss[target].Active || Boss[target].Healing || GetEntProp(client, Prop_Send, "m_iTeamNum")!=GetClientTeam(target))
		return MRES_Ignored;

	DHookSetReturn(handle, false);
	return MRES_Supercede;
}

public MRESReturn DHook_SetWinningTeam(Handle params)
{
	if(Enabled != Game_Arena)
		return MRES_Ignored;

	if(EndRound == -1)
		return MRES_Supercede;

	DHookSetParam(params, 4, false);
	return MRES_ChangedOverride;
}

public MRESReturn DHook_RoundSetup(Handle params)
{
	OnRoundSetupPre(false);
	return MRES_Ignored;
}

public MRESReturn DHook_Training(Address address, Handle retur)
{
	DHookSetReturn(retur, false);
	return MRES_Supercede;
}

static Handle DHookCreateDetourEx(Handle gameData, const char[] name, CallingConvention call, ReturnType type, ThisPointerType pointer)
{
	Handle hook = DHookCreateDetour(Address_Null, call, type, pointer);
	if(hook)
		DHookSetFromConf(hook, gameData, SDKConf_Signature, name);

	return hook;
}
