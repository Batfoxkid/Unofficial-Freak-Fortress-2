/*
	Top Module
*/

#define FF2_TIMESTEN

bool TimesTen;
static ConVar CvarTimesTen;

void TimesTen_Setup()
{
	CvarTimesTen = CreateConVar("ff2_boss_tf2x10", "3.0", "Amount to multiply boss's health and ragedamage when TF2x10 is enabled", _, true, 0.00001);
	TimesTen = LibraryExists("tf2x10");
}

float TimesTen_Value()
{
	return TimesTen ? CvarTimesTen.FloatValue : 1.0;
}
