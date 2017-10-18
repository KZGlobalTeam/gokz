/*
	ConVars
	
	ConVars for server control over features of the plugin.
*/



ConVar gCV_gokz_settings_enforcer;
ConVar gCV_EnforcedCVar[ENFORCEDCVAR_COUNT];
float gF_EnforcedCVarValues[ENFORCEDCVAR_COUNT] =  { 0.0, 0.0, 0.0 };



// =========================  PUBLIC  ========================= //

void CreateConVars()
{
	gCV_gokz_settings_enforcer = CreateConVar("gokz_settings_enforcer", "1", "Whether GOKZ enforces convars required for global records.", _, true, 0.0, true, 1.0);
	gCV_gokz_settings_enforcer.AddChangeHook(OnConVarChanged);
	
	for (int i = 0; i < ENFORCEDCVAR_COUNT; i++)
	{
		gCV_EnforcedCVar[i] = FindConVar(gC_EnforcedCVars[i]);
		gCV_EnforcedCVar[i].FloatValue = gF_EnforcedCVarValues[i];
		gCV_EnforcedCVar[i].AddChangeHook(OnEnforcedConVarChanged);
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gCV_gokz_settings_enforcer && !gCV_gokz_settings_enforcer.BoolValue)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			InvalidateRun(i);
		}
	}
}

public void OnEnforcedConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (gCV_gokz_settings_enforcer.BoolValue)
	{
		for (int i = 0; i < ENFORCEDCVAR_COUNT; i++)
		{
			if (convar == gCV_EnforcedCVar[i])
			{
				gCV_EnforcedCVar[i].FloatValue = gF_EnforcedCVarValues[i];
				return;
			}
		}
	}
} 