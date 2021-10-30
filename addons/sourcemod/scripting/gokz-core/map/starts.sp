/*
	Hooks between start destinations and GOKZ.
*/



static Regex RE_BonusStart;
static bool startExists[GOKZ_MAX_COURSES];
static float startOrigin[GOKZ_MAX_COURSES][3];
static float startAngles[GOKZ_MAX_COURSES][3];

// Used for SearchStart
static Regex RE_BonusStartButton;
static Regex RE_BonusStartZone;
static CourseTimerType startType[GOKZ_MAX_COURSES];
static float searchStartOrigin[GOKZ_MAX_COURSES][3];
static float searchStartAngles[GOKZ_MAX_COURSES][3];

// =====[ EVENTS ]=====

void OnPluginStart_MapStarts()
{
	RE_BonusStart = CompileRegex(GOKZ_BONUS_START_NAME_REGEX);
	RE_BonusStartButton = CompileRegex(GOKZ_BONUS_START_BUTTON_NAME_REGEX);
	RE_BonusStartZone = CompileRegex(GOKZ_BONUS_START_ZONE_NAME_REGEX);
}

void OnEntitySpawned_MapStarts(int entity)
{
	char buffer[32];
	
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if (!StrEqual("info_teleport_destination", buffer, false))
	{
		return;
	}
	
	if (GetEntityName(entity, buffer, sizeof(buffer)) == 0)
	{
		return;
	}
	
	if (StrEqual(GOKZ_START_NAME, buffer, false))
	{
		StoreStart(0, entity);
	}
	else
	{
		int course = GetStartBonusNumber(entity);
		if (GOKZ_IsValidCourse(course, true))
		{
			StoreStart(course, entity);
		}
	}
}

void OnEntitySpawnedPost_MapStarts(int entity)
{
	char buffer[32];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	
	if (StrEqual("trigger_multiple", buffer, false))
	{
		bool isStartZone;
		if (GetEntityName(entity, buffer, sizeof(buffer)) != 0)
		{
			if (StrEqual(GOKZ_START_ZONE_NAME, buffer, false))
			{
				isStartZone = true;
				StoreSearchStart(0, entity, CourseTimerType_ZoneNew);
			}
			else if (GetStartZoneBonusNumber(entity) != -1)
			{
				int course = GetStartZoneBonusNumber(entity);
				if (GOKZ_IsValidCourse(course, true))
				{
					isStartZone = true;
					StoreSearchStart(course, entity, CourseTimerType_ZoneNew);
				}
			}
		}
		if (!isStartZone)
		{
			TimerButtonTrigger trigger;
			if (IsTimerButtonTrigger(entity, trigger) && trigger.isStartTimer)
			{
				StoreSearchStart(trigger.course, entity, CourseTimerType_ZoneLegacy);
			}
		}

	}
	else if (StrEqual("func_button", buffer, false))
	{
		bool isStartButton;
		if (GetEntityName(entity, buffer, sizeof(buffer)) != 0)
		{
			if (StrEqual(GOKZ_START_BUTTON_NAME, buffer, false))
			{
				isStartButton = true;
				StoreSearchStart(0, entity, CourseTimerType_Button);
			}
			else
			{
				int course = GetStartButtonBonusNumber(entity);
				if (GOKZ_IsValidCourse(course, true))
				{
					isStartButton = true;
					StoreSearchStart(course, entity, CourseTimerType_Button);
				}
			}
		}
		if (!isStartButton)
		{
			TimerButtonTrigger trigger;
			if (IsTimerButtonTrigger(entity, trigger) && trigger.isStartTimer)
			{
				StoreSearchStart(trigger.course, entity, CourseTimerType_Button);
			}
		}
	}
}

void OnMapStart_MapStarts()
{
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		startExists[course] = false;
		startType[course] = CourseTimerType_None;
	}
}

bool GetMapStartPosition(int course, float origin[3], float angles[3])
{
	if (!startExists[course])
	{
		return false;
	}
	
	origin = startOrigin[course];
	angles = startAngles[course];
	
	return true;
}

bool GetSearchStartPosition(int course, float origin[3], float angles[3])
{
	if (startType[course] == CourseTimerType_None)
	{
		return false;
	}

	origin = searchStartOrigin[course];
	angles = searchStartAngles[course];

	return true;
}

// =====[ PRIVATE ]=====

static void StoreStart(int course, int entity)
{
	float origin[3], angles[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);
	angles[2] = 0.0; // Roll should always be 0.0
	
	startExists[course] = true;
	startOrigin[course] = origin;
	startAngles[course] = angles;
}

static void StoreSearchStart(int course, int entity, CourseTimerType type)
{
	// If StoreSearchStart is called, then there is at least an end position (even though it might not be a valid one)
	if (startType[course] < CourseTimerType_Default)
	{
		startType[course] = CourseTimerType_Default;
	}

	// Real zone is always better than "fake" zones which are better than buttons
	// as the buttons found in a map with fake zones aren't meant to be visible.
	if (startType[course] >= type)
	{
		return;
	}

	float origin[3], distFromCenter[3];
	GetEntityPositions(entity, origin, searchStartOrigin[course], searchStartAngles[course], distFromCenter);
	
	// If it is a button or the center of the center of the zone is invalid
	if (type == CourseTimerType_Button || !IsSpawnValid(searchStartOrigin[course]))
	{
		// Attempt with various positions around the entity, pick the first valid one.
		if (!FindValidPositionAroundTimerEntity(entity, searchStartOrigin[course], searchStartAngles[course], type == CourseTimerType_Button))
		{
			searchStartOrigin[course][2] -= 64.0; // Move the origin down so the eye position is directly on top of the button/zone.
			return;
		}
	}
	
	// Only update the CourseTimerType if a valid position is found.
	startType[course] = type;
}


static int GetStartBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusStart, 1);
}

static int GetStartButtonBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusStartButton, 1);
}

static int GetStartZoneBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusStartZone, 1);
}