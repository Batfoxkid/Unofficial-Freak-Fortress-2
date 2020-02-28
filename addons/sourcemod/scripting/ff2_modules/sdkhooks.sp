/*
	Optional:
	tf2attributes.sp
*/

#define FF2_SDKHOOKS

static Handle SDKEquipWearable;

void SDK_Setup()
{
	GameData gameData = new GameData("ff2");
	if(gameData == INVALID_HANDLE)
	{
		LogError2("[Gamedata] Failed to find ff2.txt");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(SDKEquipWearable == null)
		LogError2("[Gamedata] Failed to create call: CBasePlayer::EquipWearable");

	delete gameData;
}

stock int SDK_SpawnWeapon(int client, const char[] name, int index, int level, int quality, char[] attributes)
{
	if(StrEqual(name, "saxxy"))
	{ 
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:	strcopy(name, 64, "tf_weapon_bat");
			case TFClass_Pyro:	strcopy(name, 64, "tf_weapon_fireaxe");
			case TFClass_DemoMan:	strcopy(name, 64, "tf_weapon_bottle");
			case TFClass_Heavy:	strcopy(name, 64, "tf_weapon_fists");
			case TFClass_Engineer:	strcopy(name, 64, "tf_weapon_wrench");
			case TFClass_Medic:	strcopy(name, 64, "tf_weapon_bonesaw");
			case TFClass_Sniper:	strcopy(name, 64, "tf_weapon_club");
			case TFClass_Spy:	strcopy(name, 64, "tf_weapon_knife");
			default:		strcopy(name, 64, "tf_weapon_shovel");
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun"))
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Pyro:	strcopy(name, 64, "tf_weapon_shotgun_pyro");
			case TFClass_Heavy:	strcopy(name, 64, "tf_weapon_shotgun_hwg");
			case TFClass_Engineer:	strcopy(name, 64, "tf_weapon_shotgun_primary");
			default:		strcopy(name, 64, "tf_weapon_shotgun_soldier");
		}
	}

	int entity = CreateEntityByName(name);
	if(!IsValidEntity(entity))
		return -1;

	SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(entity, Prop_Send, "m_bInitialized", 1);

	static char netClass[64];
	GetEntityNetClass(entity, netClass, sizeof(netClass));
	SetEntData(entity, FindSendPropInfo(netClass, "m_iEntityQuality"), quality);
	SetEntData(entity, FindSendPropInfo(netClass, "m_iEntityLevel"), level);

	SetEntProp(entity, Prop_Send, "m_iEntityQuality", quality);
	SetEntProp(entity, Prop_Send, "m_iEntityLevel", level);

	#if defined FF2_TF2ATTRIBUTES
	if(attributes[0] && TF2Attributes)
	{
		char atts[32][32];
		int count = ExplodeString(attributes, " ; ", atts, 32, 32);
		if(count > 1)
		{
			for(int i; i<count; i+=2)
			{
				TF2Attrib_SetByDefIndex(entity, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			}
		}
	}
	#endif

	DispatchSpawn(entity);
	if(!StrContains(name, "tf_weap"))
	{
		EquipPlayerWeapon(client, entity);
		return entity;
	}

	if(SDKEquipWearable != null)
		SDKCall(SDKEquipWearable, client, entity);

	return entity;
}
