/*
    Hooks between specifically named end destinations and GOKZ
*/



static Regex RE_BonusEnd;
static bool endExists[GOKZ_MAX_COURSES];
static float endOrigin[GOKZ_MAX_COURSES][3];
static float endAngles[GOKZ_MAX_COURSES][3];



// =====[ EVENTS ]=====

void OnPluginStart_MapEnd()
{
	RE_BonusEnd = CompileRegex(GOKZ_BONUS_END_BUTTON_NAME_REGEX);
}

void OnEntitySpawned_MapEnd(int entity)
{
	char buffer[32];

	GetEntityClassname(entity, buffer, sizeof(buffer));
	if (!StrEqual("func_button", buffer, false))
	{
		return;
	}

	if (GetEntityName(entity, buffer, sizeof(buffer)) == 0)
	{
		return;
	}

	if (StrEqual(GOKZ_END_BUTTON_NAME, buffer, false))
	{
		StoreEnd(0, entity);
	}
	else
	{
		int course = GetEndBonusNumber(entity);
		if (GOKZ_IsValidCourse(course, true))
		{
			StoreEnd(course, entity);
		}
	}
}

void OnMapStart_MapEnd()
{
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		endExists[course] = false;
	}
}

bool GetMapEndPosition(int course, float origin[3], float angles[3])
{
	if (!endExists[course])
	{
		return false;
	}

	origin = endOrigin[course];
	angles = endAngles[course];

	return true;
}



// =====[ PRIVATE ]=====

static void StoreEnd(int course, int entity)
{
	float origin[3], angles[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);
	angles[2] = 0.0; // Roll should always be 0.0

	endExists[course] = true;
	endOrigin[course] = origin;
	endAngles[course] = angles;

	endOrigin[course][2] += 32.0;
}

static int GetEndBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusEnd, 1);
} 