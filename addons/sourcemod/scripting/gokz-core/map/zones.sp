/*
	Hooks between specifically named trigger_multiples and GOKZ.
*/



enum struct TouchedStartZone
{
	int entRef;
	int course;
	bool exitHandled;
}

static Regex RE_BonusStartZone;
static Regex RE_BonusEndZone;
static bool touchedGroundSinceTouchingStartZone[MAXPLAYERS + 1];
static ArrayList touchedStartZones[MAXPLAYERS + 1];
// Deferred so the command that leaves the zone isn't timed.
static int pendingStartCourse[MAXPLAYERS + 1] = { -1, ... };



// =====[ EVENTS ]=====

void OnPluginStart_MapZones()
{
	RE_BonusStartZone = CompileRegex(GOKZ_BONUS_START_ZONE_NAME_REGEX);
	RE_BonusEndZone = CompileRegex(GOKZ_BONUS_END_ZONE_NAME_REGEX);
}

void OnClientPutInServer_MapZones(int client)
{
	if (touchedStartZones[client] == null)
	{
		touchedStartZones[client] = new ArrayList(sizeof(TouchedStartZone));
	}
	else
	{
		touchedStartZones[client].Clear();
	}
	pendingStartCourse[client] = -1;
}

// The engine fires EndTouch once per frame, after all of the frame's commands.
void Hook_PlayerPostThink_MapZones(int client)
{
	if (touchedStartZones[client].Length == 0 || !IsPlayerAlive(client))
	{
		return;
	}

	float origin[3], mins[3], maxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
	GetEntPropVector(client, Prop_Data, "m_vecMins", mins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", maxs);

	for (int i = touchedStartZones[client].Length - 1; i >= 0; i--)
	{
		TouchedStartZone zone;
		touchedStartZones[client].GetArray(i, zone);

		int entity = EntRefToEntIndex(zone.entRef);
		if (entity == INVALID_ENT_REFERENCE)
		{
			touchedStartZones[client].Erase(i);
			continue;
		}

		bool inside = HullTouchesZone(entity, origin, mins, maxs);
		if (!zone.exitHandled && !inside)
		{
			zone.exitHandled = true;
			touchedStartZones[client].SetArray(i, zone);
			if (pendingStartCourse[client] == -1)
			{
				pendingStartCourse[client] = zone.course;
			}
		}
		else if (zone.exitHandled && inside)
		{
			// The engine never saw the exit, so it won't fire StartTouch.
			zone.exitHandled = false;
			touchedStartZones[client].SetArray(i, zone);
			ProcessStartZoneStartTouch(client, zone.course);
		}
	}
}

void OnPlayerRunCmd_MapZones(int client)
{
	ProcessPendingStart(client);
}

void OnStartTouchGround_MapZones(int client)
{
	touchedGroundSinceTouchingStartZone[client] = true;
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

	TrackStartZone(activator, caller, 0);
	ProcessStartZoneStartTouch(activator, 0);
}

public void OnStartZoneEndTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}

	ProcessPendingStart(activator);

	if (ShouldProcessEngineEndTouch(activator, caller))
	{
		ProcessStartZoneEndTouch(activator, 0);
	}
}

public void OnEndZoneStartTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}

	ProcessEndZoneStartTouch(activator, 0);
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

	TrackStartZone(activator, caller, course);
	ProcessStartZoneStartTouch(activator, course);
}

public void OnBonusStartZoneEndTouch(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}

	ProcessPendingStart(activator);

	int course = GetStartZoneBonusNumber(caller);
	if (!GOKZ_IsValidCourse(course, true))
	{
		return;
	}

	if (ShouldProcessEngineEndTouch(activator, caller))
	{
		ProcessStartZoneEndTouch(activator, course);
	}
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

	ProcessEndZoneStartTouch(activator, course);
}



// =====[ PRIVATE ]=====

static void TrackStartZone(int client, int entity, int course)
{
	int entRef = EntIndexToEntRef(entity);
	int index = touchedStartZones[client].FindValue(entRef, TouchedStartZone::entRef);
	if (index != -1)
	{
		touchedStartZones[client].Set(index, false, TouchedStartZone::exitHandled);
		return;
	}

	TouchedStartZone zone;
	zone.entRef = entRef;
	zone.course = course;
	touchedStartZones[client].PushArray(zone);
}

static void ProcessPendingStart(int client)
{
	if (pendingStartCourse[client] != -1)
	{
		ProcessStartZoneEndTouch(client, pendingStartCourse[client]);
		pendingStartCourse[client] = -1;
	}
}

// Returns whether the engine's EndTouch still needs processing.
static bool ShouldProcessEngineEndTouch(int client, int entity)
{
	int index = touchedStartZones[client].FindValue(EntIndexToEntRef(entity), TouchedStartZone::entRef);
	if (index == -1)
	{
		return true;
	}

	bool exitHandled = touchedStartZones[client].Get(index, TouchedStartZone::exitHandled);
	touchedStartZones[client].Erase(index);
	return !exitHandled;
}

static bool HullTouchesZone(int zone, const float origin[3], const float mins[3], const float maxs[3])
{
	// The engine stops touching disabled triggers.
	if (GetEntProp(zone, Prop_Data, "m_bDisabled"))
	{
		return false;
	}

	TR_ClipRayHullToEntity(origin, origin, mins, maxs, MASK_ALL, zone);
	return TR_DidHit();
}

static void ProcessStartZoneStartTouch(int client, int course)
{
	touchedGroundSinceTouchingStartZone[client] = Movement_GetOnGround(client);

	GOKZ_StopTimer(client, false);
	SetCurrentCourse(client, course);

	OnStartZoneStartTouch_Teleports(client, course);
}

static void ProcessStartZoneEndTouch(int client, int course)
{
	if (!touchedGroundSinceTouchingStartZone[client])
	{
		return;
	}

	GOKZ_StartTimer(client, course, true);
	GOKZ_ResetVirtualButtonPosition(client, true);
}

static void ProcessEndZoneStartTouch(int client, int course)
{
	GOKZ_EndTimer(client, course);
	GOKZ_ResetVirtualButtonPosition(client, false);
}

static int GetStartZoneBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusStartZone, 1);
}

static int GetEndZoneBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusEndZone, 1);
} 