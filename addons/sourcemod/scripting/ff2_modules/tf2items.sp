#define FF2_TF2ITEMS

#define WEAPON_CONFIG	"data/freak_fortress_2/weapons.cfg"

static KeyValues WeaponKV;

void TF2Items_Setup()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), WEAPON_CONFIG);
	if(!FileExists(config))
	{
		LogError2("[Weapons] Could not find '%s'!", WEAPON_CONFIG);
		WeaponKV = null;
		return;
	}

	WeaponKV = CreateKeyValues("Weapons");
	if(WeaponKV.ImportFromFile(config))
		return;

	LogError2("[Weapons] '%s' is improperly formatted!", WEAPON_CONFIG);
	WeaponKV = null;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int index, Handle &item)
{
	if(!Enabled || WeaponKV==null)
		return Plugin_Continue;

	WeaponKV.Rewind();
	WeaponKv.GotoFirstSubKey();
	do
	{
		static char attrib[256];
		if(!WeaponKv.GetSectionName(attrib, sizeof(attrib))
			continue;

		static char names[8][36];
		int num = ExplodeString(attrib, " ; ", names, sizeof(names), sizeof(names[]));
		bool mode;
		for(int i; i<num; i++)
		{
			if(StrContains(names[i], "tf_") == -1)
			{
				if(StringToInt(names[i]) != index)
					continue;

				mode = true;
				break;
			}

			if(StrContains(names[i], "*") == -1)
			{
				if(!StrEqual(names[i], classname))
					continue;

				mode = true;
				break;
			}

			bool full = ReplaceString(names[i], 36, "*", "")>1;
			if((full && StrContains(names[i], classname)==-1) || (!full && !StrContains(names[i], classname)))
				continue;

			mode = true;
			break;
		}

		if(!mode)
			continue;

		mode = WeaponKV.GetNum("preserve");
		num = WeaponKV.GetNum("index", index, -1);
		WeaponKV.GetString("classname", names[0], sizeof(names[]));
		WeaponKV.GetString("attributes", attrib, sizeof(attrib));

		Handle itemOverride = PrepareItemHandle(item, names[0], num, attrib, mode);
		if(itemOverride == null)
			break;

		item = itemOverride;
		return Plugin_Changed;
	} while(WeaponKV.GotoNextKey());
}

static Handle PrepareItemHandle(Handle item, char[] name="", int index=-1, const char[] att="", bool dontPreserve=false)
{
	int addattribs;

	static char weaponAttribsArray[32][32];
	int attribCount = ExplodeString(att, ";", weaponAttribsArray, 32, 32);

	if(attribCount % 2)
		--attribCount;

	int flags = OVERRIDE_ATTRIBUTES;
	if(!dontPreserve)
		flags |= PRESERVE_ATTRIBUTES;

	Handle weapon = TF2Items_CreateItem(flags);
	if(item != INVALID_HANDLE)
	{
		addattribs = TF2Items_GetNumAttributes(item);
		if(addattribs > 0)
		{
			for(int i; i<2*addattribs; i+=2)
			{
				bool dontAdd;
				int attribIndex = TF2Items_GetAttributeId(item, i);
				for(int z; z<attribCount+i; z+=2)
				{
					if(StringToInt(weaponAttribsArray[z]) != attribIndex)
						continue;

					dontAdd = true;
					break;
				}

				if(!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(item, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}
			attribCount += 2*addattribs;
		}

		if(weapon != item)  //FlaminSarge: Item might be equal to weapon, so closing item's handle would also close weapon's
			delete item;  //probably returns false but whatever (rswallen-apparently not)
	}

	if(name[0])
	{
		flags |= OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(weapon, name);
	}

	if(index >= 0)
	{
		flags |= OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(weapon, index);
	}

	if(attribCount > 0)
	{
		TF2Items_SetNumAttributes(weapon, attribCount/2);
		int i2;
		for(int i; i<attribCount && i2<16; i+=2)
		{
			int attrib = StringToInt(weaponAttribsArray[i]);
			if(!attrib)
			{
				LogError2("[Weapons] Bad weapon attribute passed: %s ; %s", weaponAttribsArray[i], weaponAttribsArray[i+1]);
				delete weapon;
				return INVALID_HANDLE;
			}

			TF2Items_SetAttribute(weapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}
	TF2Items_SetFlags(weapon, flags);
	return weapon;
}
