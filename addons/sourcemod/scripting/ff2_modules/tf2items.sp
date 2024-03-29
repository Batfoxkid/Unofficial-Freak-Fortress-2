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
	if(Boss[client].Active)
	{
		if(!StrEqual(classname, "tf_wearable", false))
			return Plugin_Continue;

		switch(index)
		{
			case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
			{
				return Plugin_Continue;
			}
			case 131, 133, 405, 406, 444, 608, 1099, 1144:	// Wearable weapons
			{
				return Plugin_Stop;
			}
			default:
			{
				return Boss[Boss[client].Special].Cosmetics ? Plugin_Continue : Plugin_Stop;
			}
		}
	}

	if(Enabled!=Game_Arena || WeaponCfg==null)
		return Plugin_Continue;

	ConfigMap cfg = WeaponCfg.GetSection("Weapons");
	StringMapSnapshot snap = cfg.Snapshot();
	if(!snap)
		return Plugin_Continue;

	int entries = snap.Length;
	if(entries)
	{
		bool found;
		for(int i; i<entries; i++)
		{
			int length = snap.KeyBufferSize(i)+1;
			char[] buffer = new char[length];
			snap.GetKey(i, buffer, length);
			PackVal val;
			cfg.GetArray(buffer, val, sizeof(val));
			if(val.tag != KeyValType_Section)
				continue;

			val.data.Reset();
			ConfigMap section = val.data.ReadCell();

			static char attrib[256], names[8][MAX_CLASSNAME_LENGTH];
			if(section.GetString("skip", attrib, sizeof(attrib)))
			{
				length = ExplodeString(attrib, " ; ", names, sizeof(names), sizeof(names[]));
				for(int x; x<length; x++)
				{
					if(StringToInt(names[x]) != index)
						continue;

					found = true;
					break;
				}

				if(!found)
					continue;

				found = false;
			}

			bool old = !StrContains(buffer, "weapon");
			if(old)
			{
				if(!section.GetString("classname", attrib, sizeof(attrib)))
				{
					if(!section.GetString("index", attrib, sizeof(attrib)))
						continue;
				}

				length = ExplodeString(attrib, " ; ", names, sizeof(names), sizeof(names[]));
			}
			else
			{
				length = ExplodeString(buffer, " ; ", names, sizeof(names), sizeof(names[]));
			}

			length = ExplodeString(buffer, " ; ", names, sizeof(names), sizeof(names[]));
			for(int x; x<length; x++)
			{
				if(StrContains(names[x], "tf_") == -1)
				{
					if(StringToInt(names[x]) != index)
						continue;
				}
				else if(StrContains(names[x], "*") == -1)
				{
					if(!StrEqual(names[x], classname))
						continue;
				}
				else if(ReplaceString(names[x], sizeof(names[]), "*", "") > 1)
				{
					if(StrContains(names[x], classname) == -1)
						continue;
				}
				else if(!StrContains(names[x], classname))
				{
					continue;
				}

				found = true;
				break;
			}

			if(!found)
				continue;

			if(old)
			{
				found = (section.GetInt("mode", length) && length>1);
				length = 0;
				names[0][0] = 0;
			}
			else
			{
				found = (section.GetInt("preserve", length) && length);
				length = (section.GetInt("index", length)) ? length : -1;
				if(!section.GetString("classname", names[0], sizeof(names[])))
					names[0][0] = 0;
			}

			if(!section.GetString("attributes", attrib, sizeof(attrib)))
				attrib[0] = 0;

			Handle itemOverride = PrepareItemHandle(item, names[0], length, attrib, found);
			if(itemOverride == INVALID_HANDLE)
				break;

			item = itemOverride;
			delete snap;
			return Plugin_Changed;
		}
	}
	delete snap;
	return Plugin_Continue;
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

			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(weaponAttribsArray[i+1]));
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

stock int TF2Items_SpawnWeapon(int client, char[] name, int index, int level, int qual, const char[] att)
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
