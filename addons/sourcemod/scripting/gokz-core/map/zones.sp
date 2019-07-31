/*
	Hooks between specifically named trigger_multiples and GOKZ.
*/



static Regex RE_BonusStartZone;
static Regex RE_BonusEndZone;



// =====[ EVENTS ]=====

void OnPluginStart_MapZones()
{
	RE_BonusStartZone = CompileRegex(GOKZ_BONUS_START_ZONE_NAME_REGEX);
	RE_BonusEndZone = CompileRegex(GOKZ_BONUS_END_ZONE_NAME_REGEX);
}

void OnEntitySpawned_MapZones(int entity)
{
	char tempString[32];
	
	GetEntityClassname(entity, tempString, sizeof(tempString));
	if (!StrEqual("trigger_multiple", tempString, false))
	{
		return;
	}
	
	if (GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString)) > 0)
	{
		if (StrEqual(GOKZ_START_ZONE_NAME, tempString, false))
		{
			HookSingleEntityOutput(entity, "OnEndTouch", OnStartZoneEndTouch);
		}
		else if (StrEqual(GOKZ_END_ZONE_NAME, tempString, false))
		{
			HookSingleEntityOutput(entity, "OnStartTouch", OnEndZoneStartTouch);
		}
		else if (MatchRegex(RE_BonusStartZone, tempString) > 0)
		{
			HookSingleEntityOutput(entity, "OnEndTouch", OnBonusStartZoneEndTouch);
		}
		else if (MatchRegex(RE_BonusEndZone, tempString) > 0)
		{
			HookSingleEntityOutput(entity, "OnStartTouch", OnBonusEndZoneStartTouch);
		}
	}
}

public void OnStartZoneEndTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	// Prevent pre-hopping
	if (!GOKZ_GetHitPerf(activator))
	{
		GOKZ_StartTimer(activator, 0, true);
	}
}

public void OnEndZoneStartTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	GOKZ_EndTimer(activator, 0);
}

public void OnBonusStartZoneEndTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator)) {
		return;
	}
	
	char tempString[32];
	GetEntPropString(caller, Prop_Data, "m_iName", tempString, sizeof(tempString));
	
	if (MatchRegex(RE_BonusStartZone, tempString) > 0)
	{
		GetRegexSubString(RE_BonusStartZone, 1, tempString, sizeof(tempString));
		int course = StringToInt(tempString);
		if (course > 0 && course < GOKZ_MAX_COURSES)
		{
			// Prevent pre-hopping
			if (!GOKZ_GetHitPerf(activator))
			{
				GOKZ_StartTimer(activator, course, true);
			}
		}
	}
}

public void OnBonusEndZoneStartTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	char tempString[32];
	GetEntPropString(caller, Prop_Data, "m_iName", tempString, sizeof(tempString));
	
	if (MatchRegex(RE_BonusEndZone, tempString) > 0)
	{
		GetRegexSubString(RE_BonusEndZone, 1, tempString, sizeof(tempString));
		int course = StringToInt(tempString);
		if (course > 0 && course < GOKZ_MAX_COURSES)
		{
			GOKZ_EndTimer(activator, course);
		}
	}
} 