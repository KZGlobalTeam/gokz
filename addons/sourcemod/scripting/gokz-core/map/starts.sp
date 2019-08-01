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
	char tempString[32];
	
	GetEntityClassname(entity, tempString, sizeof(tempString));
	if (!StrEqual("info_teleport_destination", tempString, false))
	{
		return;
	}
	
	if (GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString)) > 0)
	{
		if (StrEqual(GOKZ_START_NAME, tempString, false))
		{
			StoreStart(0, entity);
		}
		else if (MatchRegex(RE_BonusStart, tempString) > 0)
		{
			GetRegexSubString(RE_BonusStart, 1, tempString, sizeof(tempString));
			int course = StringToInt(tempString);
			if (course > 0 && course < GOKZ_MAX_COURSES)
			{
				StoreStart(course, entity);
			}
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

void OnClientPutInServer_MapStarts(int client)
{
	SetCustomStartPositionToMap(client, 0, true);
}

bool SetCustomStartPositionToMap(int client, int course, bool quiet = false)
{
	if (!startExists[course])
	{
		return false;
	}
	
	SetCustomStartPosition(client, startOrigin[course], startAngles[course], quiet);
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