/*
	Hooks between specifically named end destinations and GOKZ
*/



static Regex RE_BonusEndButton;
static Regex RE_BonusEndZone;
static CourseTimerType endType[GOKZ_MAX_COURSES];
static float endOrigin[GOKZ_MAX_COURSES][3];
static float endAngles[GOKZ_MAX_COURSES][3];



// =====[ EVENTS ]=====

void OnPluginStart_MapEnd()
{
	RE_BonusEndButton = CompileRegex(GOKZ_BONUS_END_BUTTON_NAME_REGEX);
	RE_BonusEndZone = CompileRegex(GOKZ_BONUS_END_ZONE_NAME_REGEX);
}

void OnEntitySpawnedPost_MapEnd(int entity)
{
	char buffer[32];

	GetEntityClassname(entity, buffer, sizeof(buffer));
	
	if (StrEqual("trigger_multiple", buffer, false))
	{
		bool isEndZone;
		if (GetEntityName(entity, buffer, sizeof(buffer)) != 0)
		{
			if (StrEqual(GOKZ_END_ZONE_NAME, buffer, false))
			{
				isEndZone = true;
				StoreEnd(0, entity, CourseTimerType_ZoneNew);
			}
			else if (GetEndZoneBonusNumber(entity) != -1)
			{
				int course = GetEndZoneBonusNumber(entity);
				if (GOKZ_IsValidCourse(course, true))
				{
					isEndZone = true;
					StoreEnd(course, entity, CourseTimerType_ZoneNew);
				}
			}
		}
		if (!isEndZone)
		{
			TimerButtonTrigger trigger;
			if (IsTimerButtonTrigger(entity, trigger) && !trigger.isStartTimer)
			{
				StoreEnd(trigger.course, entity, CourseTimerType_ZoneLegacy);
			}
		}
	}
	else if (StrEqual("func_button", buffer, false))
	{
		bool isEndButton;
		if (GetEntityName(entity, buffer, sizeof(buffer)) != 0)
		{
			if (StrEqual(GOKZ_END_BUTTON_NAME, buffer, false))
			{
				isEndButton = true;
				StoreEnd(0, entity, CourseTimerType_Button);
			}
			else
			{
				int course = GetEndButtonBonusNumber(entity);
				if (GOKZ_IsValidCourse(course, true))
				{
					isEndButton = true;
					StoreEnd(course, entity, CourseTimerType_Button);
				}
			}
		}
		if (!isEndButton)
		{
			TimerButtonTrigger trigger;
			if (IsTimerButtonTrigger(entity, trigger) && !trigger.isStartTimer)
			{
				StoreEnd(trigger.course, entity, CourseTimerType_Button);
			}
		}
	}
}

void OnMapStart_MapEnd()
{
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		endType[course] = CourseTimerType_None;
	}
}

bool GetMapEndPosition(int course, float origin[3], float angles[3])
{
	if (endType[course] == CourseTimerType_None)
	{
		return false;
	}

	origin = endOrigin[course];
	angles = endAngles[course];

	return true;
}



// =====[ PRIVATE ]=====

static void StoreEnd(int course, int entity, CourseTimerType type)
{
	// If StoreEnd is called, then there is at least an end position (even though it might not be a valid one)
	if (endType[course] < CourseTimerType_Default)
	{
		endType[course] = CourseTimerType_Default;
	}

	// Real zone is always better than "fake" zones which are better than buttons
	// as the buttons found in a map with fake zones aren't meant to be visible.
	if (endType[course] >= type)
	{
		return;
	}

	float origin[3], distFromCenter[3];
	GetEntityPositions(entity, origin, endOrigin[course], endAngles[course], distFromCenter);
	
	// If it is a button or the center of the center of the zone is invalid
	if (type == CourseTimerType_Button || !IsSpawnValid(endOrigin[course]))
	{
		// Attempt with various positions around the entity, pick the first valid one.
		if (!FindValidPositionAroundTimerEntity(entity, endOrigin[course], endAngles[course], type == CourseTimerType_Button))
		{
			endOrigin[course][2] -= 64.0; // Move the origin down so the eye position is directly on top of the button/zone.
			return;
		}
	}
	
	// Only update the CourseTimerType if a valid position is found.
	endType[course] = type;
}

static int GetEndButtonBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusEndButton, 1);
}

static int GetEndZoneBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusEndZone, 1);
}
