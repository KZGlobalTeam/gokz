/*
	Most commonly referred to in the KZ community as timer tech.
	Lets players press 'virtual' start and end buttons without looking.
*/



static int beamSprite;
static int haloSprite;
static float lastUsePressTime[MAXPLAYERS + 1];
static int lastTeleportTick[MAXPLAYERS + 1];
static bool startedTimerLastTick[MAXPLAYERS + 1];
static bool onlyNaturalButtonPressed[MAXPLAYERS + 1];
static int startTimerButtonPressTick[MAXPLAYERS + 1];
static bool hasEndedTimerSincePressingUse[MAXPLAYERS + 1];
static bool hasTeleportedSincePressingUse[MAXPLAYERS + 1];
static bool hasVirtualStartButton[MAXPLAYERS + 1];
static bool hasVirtualEndButton[MAXPLAYERS + 1];
static bool wasInEndZone[MAXPLAYERS + 1];
static float virtualStartOrigin[MAXPLAYERS + 1][3];
static float virtualEndOrigin[MAXPLAYERS + 1][3];
static int virtualStartCourse[MAXPLAYERS + 1];
static int virtualEndCourse[MAXPLAYERS + 1];
static bool virtualButtonsLocked[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool GetHasVirtualStartButton(int client)
{
	return hasVirtualStartButton[client];
}

bool GetHasVirtualEndButton(int client)
{
	return hasVirtualEndButton[client];
}

bool ToggleVirtualButtonsLock(int client)
{
	virtualButtonsLocked[client] = !virtualButtonsLocked[client];
	return virtualButtonsLocked[client];
}

void LockVirtualButtons(int client)
{
	virtualButtonsLocked[client] = true;
}

int GetVirtualButtonPosition(int client, float position[3], bool isStart)
{
	if (isStart && hasVirtualStartButton[client])
	{
		position = virtualStartOrigin[client];
		return virtualStartCourse[client];
	}
	else if (!isStart && hasVirtualEndButton[client])
	{
		position = virtualEndOrigin[client];
		return virtualEndCourse[client];
	}
	
	return -1;
}

void SetVirtualButtonPosition(int client, float position[3], int course, bool isStart)
{
	if (isStart)
	{
		virtualStartCourse[client] = course;
		virtualStartOrigin[client] = position;
		hasVirtualStartButton[client] = true;
		
	}
	else
	{
		virtualEndCourse[client] = course;
		virtualEndOrigin[client] = position;
		hasVirtualEndButton[client] = true;
	}
}



// =====[ EVENTS ]=====

void OnMapStart_VirtualButtons()
{
	beamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	haloSprite = PrecacheModel("materials/sprites/glow01.vmt");
}

void OnClientPutInServer_VirtualButtons(int client)
{
	startedTimerLastTick[client] = false;
	hasVirtualEndButton[client] = false;
	hasVirtualStartButton[client] = false;
	virtualButtonsLocked[client] = false;
	onlyNaturalButtonPressed[client] = false;
	wasInEndZone[client] = false;
	startTimerButtonPressTick[client] = 0;
}

void OnStartButtonPress_VirtualButtons(int client, int course)
{
	if (!virtualButtonsLocked[client] &&
		lastTeleportTick[client] + GOKZ_TIMER_START_NO_TELEPORT_TICKS < GetGameTickCount())
	{
		Movement_GetOrigin(client, virtualStartOrigin[client]);
		virtualStartCourse[client] = course;
		hasVirtualStartButton[client] = true;
		startTimerButtonPressTick[client] = GetGameTickCount();
	}
}

void OnEndButtonPress_VirtualButtons(int client, int course)
{
	// Prevent setting end virtual button to where it would usually be unreachable
	if (IsPlayerStuck(client))
	{
		return;
	}
	
	if (!virtualButtonsLocked[client] &&
		lastTeleportTick[client] + GOKZ_TIMER_START_NO_TELEPORT_TICKS < GetGameTickCount())
	{
		Movement_GetOrigin(client, virtualEndOrigin[client]);
		virtualEndCourse[client] = course;
		hasVirtualEndButton[client] = true;
	}
}

void OnPlayerRunCmdPost_VirtualButtons(int client, int buttons, int cmdnum)
{
	CheckForAndHandleUsage(client, buttons);
	UpdateIndicators(client, cmdnum);
}

void OnCountedTeleport_VirtualButtons(int client)
{
	hasTeleportedSincePressingUse[client] = true;
}

void OnTeleport_DelayVirtualButtons(int client)
{
	lastTeleportTick[client] = GetGameTickCount();
}



// =====[ PRIVATE ]=====

static void CheckForAndHandleUsage(int client, int buttons)
{
	if (buttons & IN_USE && !(gI_OldButtons[client] & IN_USE))
	{
		lastUsePressTime[client] = GetGameTime();
		hasEndedTimerSincePressingUse[client] = false;
		hasTeleportedSincePressingUse[client] = false;
		onlyNaturalButtonPressed[client] = startTimerButtonPressTick[client] == GetGameTickCount();
	}
	
	bool useCheck = PassesUseCheck(client);
	
	// Start button
	if ((useCheck || GOKZ_GetCoreOption(client, Option_TimerButtonZoneType) == TimerButtonZoneType_BothZones)
		&& GetHasVirtualStartButton(client) && InRangeOfVirtualStart(client) && CanReachVirtualStart(client))
	{
		if (TimerStart(client, virtualStartCourse[client], .playSound = false))
		{
			startedTimerLastTick[client] = true;
			OnVirtualStartButtonPress_Teleports(client);
		}
	}
	else if (startedTimerLastTick[client])
	{
		// Without that check you get two sounds when pressing the natural timer button
		if (!onlyNaturalButtonPressed[client])
		{
			PlayTimerStartSound(client);
		}
		onlyNaturalButtonPressed[client] = false;
		startedTimerLastTick[client] = false;
	}
	
	// End button
	if ((useCheck || GOKZ_GetCoreOption(client, Option_TimerButtonZoneType) != TimerButtonZoneType_BothButtons)
		&& GetHasVirtualEndButton(client) && InRangeOfVirtualEnd(client) && CanReachVirtualEnd(client))
	{
		if (!wasInEndZone[client])
		{
			TimerEnd(client, virtualEndCourse[client]);
			hasEndedTimerSincePressingUse[client] = true; // False end counts as well
			wasInEndZone[client] = true;
		}
	}
	else
	{
		wasInEndZone[client] = false;
	}
}

static bool PassesUseCheck(int client)
{
	if (GetGameTime() - lastUsePressTime[client] < GOKZ_VIRTUAL_BUTTON_USE_DETECTION_TIME + EPSILON
		 && !hasEndedTimerSincePressingUse[client]
		 && !hasTeleportedSincePressingUse[client])
	{
		return true;
	}
	
	return false;
}

bool InRangeOfVirtualStart(int client)
{
	return InRangeOfButton(client, virtualStartOrigin[client]);
}

static bool InRangeOfVirtualEnd(int client)
{
	return InRangeOfButton(client, virtualEndOrigin[client]);
}

static bool InRangeOfButton(int client, const float buttonOrigin[3])
{
	float origin[3];
	Movement_GetOrigin(client, origin);
	float distanceToButton = GetVectorDistance(origin, buttonOrigin);
	return distanceToButton <= gF_ModeVirtualButtonRanges[GOKZ_GetCoreOption(client, Option_Mode)];
}

bool CanReachVirtualStart(int client)
{
	return CanReachButton(client, virtualStartOrigin[client]);
}

static bool CanReachVirtualEnd(int client)
{
	return CanReachButton(client, virtualEndOrigin[client]);
}

static bool CanReachButton(int client, const float buttonOrigin[3])
{
	float origin[3];
	Movement_GetOrigin(client, origin);
	Handle trace = TR_TraceRayFilterEx(origin, buttonOrigin, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayers);
	bool didHit = TR_DidHit(trace);
	delete trace;
	return !didHit;
}



// ===== [ INDICATOR ] =====

static void UpdateIndicators(int client, int cmdnum)
{
	if (cmdnum % 128 != 0 || !IsPlayerAlive(client)
		 || GOKZ_GetCoreOption(client, Option_VirtualButtonIndicators) == VirtualButtonIndicators_Disabled)
	{
		return;
	}
	
	if (hasVirtualStartButton[client])
	{
		DrawIndicator(client, virtualStartOrigin[client], { 0, 255, 0, 255 } );
	}
	
	if (hasVirtualEndButton[client])
	{
		DrawIndicator(client, virtualEndOrigin[client], { 255, 0, 0, 255 } );
	}
}

static void DrawIndicator(int client, const float origin[3], const int colour[4])
{
	float radius = gF_ModeVirtualButtonRanges[GOKZ_GetCoreOption(client, Option_Mode)];
	if (radius <= EPSILON) // Don't draw circle of radius 0
	{
		return;
	}
	
	float x, y, start[3], end[3];
	
	// Create the start position for the first part of the beam
	start[0] = origin[0] + radius;
	start[1] = origin[1];
	start[2] = origin[2];
	
	for (int i = 1; i <= 31; i++) // Circle is broken into 31 segments
	{
		float angle = 2 * PI / 31 * i;
		x = radius * Cosine(angle);
		y = radius * Sine(angle);
		
		end[0] = origin[0] + x;
		end[1] = origin[1] + y;
		end[2] = origin[2];
		
		TE_SetupBeamPoints(start, end, beamSprite, haloSprite, 0, 0, 0.97, 0.2, 0.2, 0, 0.0, colour, 0);
		TE_SendToClient(client);
		
		start[0] = end[0];
		start[1] = end[1];
		start[2] = end[2];
	}
}
