/*
	Functions:
	void RTD_Setup()
*/

#define FF2_RTD

static ConVar Cvar;

void RTD_Setup()
{
	Cvar = CreateConVar("ff2_boss_rtd", "0", "Can boss use Roll the Dice", _, true, 0.0, true, 1.0);
}

public Action RTD_CanRollDice(int client)
{
	return (Boss[client].Active && !Cvar.BoolValue) ? Plugin_Handled : Plugin_Continue;
}

public Action RTD2_CanRollDice(int client)
{
	return (Boss[client].Active && !Cvar.BoolValue) ? Plugin_Handled : Plugin_Continue;
}