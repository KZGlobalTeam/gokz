/*
	Hooks between specifically named info_teleport_destinations and GOKZ.
*/



static Regex RE_BonusStart;
static bool startExists[GOKZ_MAX_COURSES];
static float startOrigin[GOKZ_MAX_COURSES][3];
static float startAngles[GOKZ_MAX_COURSES][3];



// =====[ EVENTS ]=====

void OnPluginStart_MapStarts()
{
	RE_BonusStart = CompileRegex(GOKZ_BONUS_START_NAME_REGEX);
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

void OnMapStart_MapStarts()
{
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		startExists[course] = false;
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

static int GetStartBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusStart, 1);
} 