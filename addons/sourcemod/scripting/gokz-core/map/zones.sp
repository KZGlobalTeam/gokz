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
	char buffer[32];
	
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if (!StrEqual("trigger_multiple", buffer, false))
	{
		return;
	}
	
	if (GetEntityName(entity, buffer, sizeof(buffer)) == 0)
	{
		return;
	}
	
	int course = 0;
	if (StrEqual(GOKZ_START_ZONE_NAME, buffer, false))
	{
		HookSingleEntityOutput(entity, "OnStartTouch", OnStartZoneStartTouch);
		HookSingleEntityOutput(entity, "OnEndTouch", OnStartZoneEndTouch);
		RegisterCourseStart(course);
	}
	else if (StrEqual(GOKZ_END_ZONE_NAME, buffer, false))
	{
		HookSingleEntityOutput(entity, "OnStartTouch", OnEndZoneStartTouch);
		RegisterCourseEnd(course);
	}
	else if ((course = GetStartZoneBonusNumber(entity)) != -1)
	{
		HookSingleEntityOutput(entity, "OnStartTouch", OnBonusStartZoneStartTouch);
		HookSingleEntityOutput(entity, "OnEndTouch", OnBonusStartZoneEndTouch);
		RegisterCourseStart(course);
	}
	else if ((course = GetEndZoneBonusNumber(entity)) != -1)
	{
		HookSingleEntityOutput(entity, "OnStartTouch", OnBonusEndZoneStartTouch);
		RegisterCourseEnd(course);
	}
}

public void OnStartZoneStartTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	// Set start position to course if they weren't running it before
	if (GOKZ_GetCourse(activator) != 0)
	{
		GOKZ_StopTimer(activator);
		SetCurrentCourse(activator, 0);
		SetCustomStartPositionToMap(activator, 0);
	}
}

public void OnStartZoneEndTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	GOKZ_StartTimer(activator, 0, true);
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
	if (!GOKZ_IsValidCourse(course, true))
	{
		return;
	}
	
	// Set start position to course if they weren't running it before
	if (GOKZ_GetCourse(activator) != course)
	{
		GOKZ_StopTimer(activator);
		SetCurrentCourse(activator, course);
		SetCustomStartPositionToMap(activator, course);
	}
}

public void OnBonusStartZoneEndTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	int course = GetStartZoneBonusNumber(caller);
	if (!GOKZ_IsValidCourse(course, true))
	{
		return;
	}
	
	GOKZ_StartTimer(activator, course, true);
}

public void OnBonusEndZoneStartTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	int course = GetEndZoneBonusNumber(caller);
	if (!GOKZ_IsValidCourse(course, true))
	{
		return;
	}
	
	GOKZ_EndTimer(activator, course);
}



// =====[ PRIVATE ]=====

static int GetStartZoneBonusNumber(int entity)
{
	return MatchIntFromEntityName(entity, RE_BonusStartZone, 1);
}

static int GetEndZoneBonusNumber(int entity)
{
	return MatchIntFromEntityName(entity, RE_BonusEndZone, 1);
} 