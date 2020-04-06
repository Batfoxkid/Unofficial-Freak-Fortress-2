#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include "ff2_modules/configmap.sp"

public void OnPluginStart()
{
	RegServerCmd("ff2_showconfig", OnCommand, "StringMap Testing");
}

public Action OnCommand(int args)
{
	if(args != 1)
	{
		PrintToServer("[SM] Usage: ff2_showconfig <filepath>");
		return Plugin_Handled;
	}

	char path[PLATFORM_MAX_PATH];
	GetCmdArgString(path, sizeof(path));
	ConfigMap cfg = new ConfigMap(path);
	if(cfg == null)
		return Plugin_Handled;

	StringMapSnapshot snap = cfg.Snapshot();
	if(!snap)
	{
		delete cfg;
		return Plugin_Handled;
	}

	int entries = snap.Length;
	for(int i; i<entries; i++)
	{
		int strsize = snap.KeyBufferSize(i)+1;
		char[] key_buffer = new char[strsize];
		snap.GetKey(i, key_buffer, strsize);
		PackVal val;
		cfg.GetArray(key_buffer, val, sizeof(val));
		if(val.tag == KeyValType_Section)
		{
			val.data.Reset();
			ConfigMap section = val.data.ReadCell();
			PrintCfg2(section);
		}
	}

	delete snap;
	delete cfg;
	return Plugin_Handled;
}

stock void PrintCfg2(ConfigMap cfg)
{
	if(cfg == null)
		return;

	StringMapSnapshot snap = cfg.Snapshot();
	if(!snap)
	{
		delete cfg;
		return;
	}

	int entries = snap.Length;
	for(int i; i<entries; i++)
	{
		int strsize = snap.KeyBufferSize(i)+1;
		char[] key_buffer = new char[strsize];
		snap.GetKey(i, key_buffer, strsize);
		PackVal val;
		cfg.GetArray(key_buffer, val, sizeof(val));
		switch(val.tag)
		{
			case KeyValType_Value:
			{
				val.data.Reset();
				char buffer[256];
				val.data.ReadString(buffer, sizeof(buffer));
				PrintToServer("ConfigMap :: key: '%s', val.data: '%s'", key_buffer, buffer);
			}
			case KeyValType_Section:
			{
				PrintToServer("ConfigMap :: \t\tkey: '%s', Section", key_buffer);
				val.data.Reset();
				ConfigMap section = val.data.ReadCell();
				PrintCfg2(section);
			}
		}
	}

	delete snap;
	delete cfg;
}

stock void LogError2(const char[] buffer, any ...)
{
	char message[192];
	VFormat(message, sizeof(message), buffer, 2);
	PrintToServer(message);
}