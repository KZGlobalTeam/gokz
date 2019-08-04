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
			HookSingleEntityOutput(entity, "OnStartTouch", OnStartZoneStartTouch);
			HookSingleEntityOutput(entity, "OnEndTouch", OnStartZoneEndTouch);
		}
		else if (StrEqual(GOKZ_END_ZONE_NAME, tempString, false))
		{
			HookSingleEntityOutput(entity, "OnStartTouch", OnEndZoneStartTouch);
		}
		else if (MatchRegex(RE_BonusStartZone, tempString) > 0)
		{
			HookSingleEntityOutput(entity, "OnStartTouch", OnBonusStartZoneStartTouch);
			HookSingleEntityOutput(entity, "OnEndTouch", OnBonusStartZoneEndTouch);
		}
		else if (MatchRegex(RE_BonusEndZone, tempString) > 0)
		{
			HookSingleEntityOutput(entity, "OnStartTouch", OnBonusEndZoneStartTouch);
		}
	}
}

public void OnStartZoneStartTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	if (GOKZ_GetCourse(activator) != 0)
	{
		SetCustomStartPositionToMap(activator, 0, true);
	}
}

public void OnStartZoneEndTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	// Prevent pre-hopping and exploits
	if (GOKZ_GetValidJump(activator) && !GOKZ_GetHitPerf(activator))
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

public void OnBonusStartZoneStartTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	int course = GetStartZoneBonusNumber(caller);
	if (course == -1)
	{
		return;
	}
	
	if (GOKZ_GetCourse(activator) != course)
	{
		SetCustomStartPositionToMap(activator, course, true);
	}
}

public void OnBonusStartZoneEndTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	int course = GetStartZoneBonusNumber(caller);
	if (course == -1)
	{
		return;
	}
	
	// Prevent pre-hopping and exploits
	if (GOKZ_GetValidJump(activator) && !GOKZ_GetHitPerf(activator))
	{
		GOKZ_StartTimer(activator, course, true);
	}
}

public void OnBonusEndZoneStartTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	int course = GetEndZoneBonusNumber(caller);
	if (course == -1)
	{
		return;
	}
	
	GOKZ_EndTimer(activator, course);
}



// =====[ PRIVATE ]=====

static int GetStartZoneBonusNumber(int entity)
{
	return GetZoneBonusNumber(entity, RE_BonusStartZone);
}

static int GetEndZoneBonusNumber(int entity)
{
	return GetZoneBonusNumber(entity, RE_BonusEndZone);
}

static int GetZoneBonusNumber(int entity, Regex re)
{
	int course;
	char tempString[32];
	GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString));
	
	if (re.Match(tempString) > 0)
	{
		re.GetSubString(1, tempString, sizeof(tempString));
		course = StringToInt(tempString);
		
		// Check validity
		if (course < 0 && course >= GOKZ_MAX_COURSES)
		{
			course = -1;
		}
	}
	
	return course;
} 