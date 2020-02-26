#define FF2_TIMESTEN

bool TimesTen;
ConVar CvarTimesTen;

void TimesTen_Setup()
{
	CvarTimesTen = CreateConVar("ff2_tf2x10", "3.0", "Amount to multiply boss's health and ragedamage when TF2x10 is enabled", _, true, 0.00001);
}

float TimesTen_Value()
{
	return TimesTen ? CvarTimesTen.FloatValue : 1.0;
}

void TimesTen_Toggle(bool toggle)
{
	TimesTen = toggle;
}
