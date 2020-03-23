/*
	Required:
	weapons.sp

	Functions:
	void TF2Items_Pre()
	void TF2Items_Setup()
	int TF2Items_SpawnWeapon(int client, const char[] name, int index, int level, int qual, const char[] att)
*/

#if !defined _tf2items_included
  #endinput
#endif

#define FF2_TF2ITEMS

bool TF2Items;

void TF2Items_Pre()
{
	MarkNativeAsOptional("TF2Items_CreateItem");
	MarkNativeAsOptional("TF2Items_GetAttributeId");
	MarkNativeAsOptional("TF2Items_GetAttributeValue");
	MarkNativeAsOptional("TF2Items_GetNumAttributes");
	MarkNativeAsOptional("TF2Items_GiveNamedItem");
	MarkNativeAsOptional("TF2Items_SetAttribute");
	MarkNativeAsOptional("TF2Items_SetClassname");
	MarkNativeAsOptional("TF2Items_SetFlags");
	MarkNativeAsOptional("TF2Items_SetItemIndex");
	MarkNativeAsOptional("TF2Items_SetLevel");
	MarkNativeAsOptional("TF2Items_SetNumAttributes");
	MarkNativeAsOptional("TF2Items_SetQuality");
}

void TF2Items_Setup()
{
	TF2Items = LibraryExists("TF2Items");
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int index, Handle &item)
{
	if(Enabled!=Game_Arena || WeaponKV==null)
		return Plugin_Continue;

	WeaponKV.Rewind();
	WeaponKv.GotoFirstSubKey();
	do
	{
		static char attrib[256];
		if(!WeaponKv.GetSectionName(attrib, sizeof(attrib))
			continue;

		static char names[8][MAX_CLASSNAME_LENGTH];
		int num = ExplodeString(attrib, " ; ", names, sizeof(names), sizeof(names[]));
		bool found;
		for(int i; i<num; i++)
		{
			if(StrContains(names[i], "tf_") == -1)
			{
				if(StringToInt(names[i]) != index)
					continue;
			}
			else if(StrContains(names[i], "*") == -1)
			{
				if(!StrEqual(names[i], classname))
					continue;
			}
			else if(ReplaceString(names[i], sizeof(names[]), "*", "") > 1)
			{
				if(StrContains(names[i], classname) == -1)
					continue;
			}
			else if(!StrContains(names[i], classname))
			{
				continue;
				
			}
			mode = true;
			break;
		}

		if(!found)
			continue;

		found = view_as<bool>(WeaponKV.GetNum("preserve"));
		num = WeaponKV.GetNum("index", index, -1);
		WeaponKV.GetString("classname", names[0], sizeof(names[]));
		WeaponKV.GetString("attributes", attrib, sizeof(attrib));

		Handle itemOverride = PrepareItemHandle(item, names[0], num, attrib, found);
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
	int attribCount = ExplodeString(att, " ; ", weaponAttribsArray, sizeof(weaponAttribsArray), sizeof(weaponAttribsArray[]));

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
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], sizeof(weaponAttribsArray[]));
					FloatToString(TF2Items_GetAttributeValue(item, i), weaponAttribsArray[i+1+attribCount], sizeof(weaponAttribsArray[]));
				}
			}
			attribCount += 2*addattribs;
		}

		if(weapon != item)
			delete item;
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

stock int TF2Items_SpawnWeapon(int client, const char[] name, int index, int level, int qual, const char[] att)
{
	Handle weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(weapon == INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
		--count;

	if(count > 0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib = StringToInt(atts[i]);
			if(!attrib)
			{
				LogError2("[Boss] Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				delete weapon;
				return -1;
			}

			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	int entity = TF2Items_GiveNamedItem(client, weapon);
	delete weapon;
	if(entity == -1)
		return -1;

	EquipPlayerWeapon(client, entity);
	return entity;
}
