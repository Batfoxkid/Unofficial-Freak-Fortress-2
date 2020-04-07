/*
	Required:
	sdkhooks.sp

	Functions:
	void DHook_Setup(GameData gameData)

	Credits:
	Ragenewb
*/

#if !defined _dhooks_included
  #endinput
#endif

#define FF2_DHOOKS

void DHook_Setup(GameData gameData)
{
	if(GetFeatureStatus(FeatureType_Native, "DHookCreateDetour") != FeatureStatus_Available)
		return;

	Handle hook = DHookCreateDetourEx(gameData, "CTFPlayer::RegenThink", CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	if(!hook || !DHookEnableDetour(hook, false, DHook_Regen))
		LogError2("[Gamedata] Could not load detour for CTFPlayer::RegenThink.");

	hook = DHookCreateDetourEx(gameData, "CWeaponMedigun::AllowedToHealTarget", CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if(hook)
	{
		DHookAddParam(hook, HookParamType_CBaseEntity);
		if(!DHookEnableDetour(hook, false, DHook_Healing))
			LogError2("[Gamedata] Could not load detour for CWeaponMedigun::AllowedToHealTarget.");
	}
	else
	{
		LogError2("[Gamedata] Could not load detour for CWeaponMedigun::AllowedToHealTarget.");
	}

	hook = DHookCreateDetourEx(gameData, "CObjectDispenser::CouldHealTarget", CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if(hook)
	{
		DHookAddParam(hook, HookParamType_CBaseEntity);
		if(!DHookEnableDetour(hook, false, DHook_Healing))
			LogError2("[Gamedata] Could not load detour for CObjectDispenser::CouldHealTarget.");
	}
	else
	{
		LogError2("[Gamedata] Could not load detour for CObjectDispenser::CouldHealTarget.");
	}
}

public MRESReturn DHook_Regen(int client)
{
	if(Enabled <= Game_Disabled)
		return MRES_Ignored;

	if(!Boss[client].Active || Boss[client].Healing || TF2_GetPlayerClass(client)!=TFClass_Medic)
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

static Handle DHookCreateDetourEx(Handle gameData, const char[] name, CallingConvention call, ReturnType type, ThisPointerType pointer)
{
	Handle hook = DHookCreateDetour(Address_Null, call, type, pointer);
	if(hook)
		DHookSetFromConf(hook, gameData, SDKConf_Signature, name);

	return hook;
}