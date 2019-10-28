/*
	Most commonly referred to in the KZ community as timer tech.
	Lets players press 'virtual' start and end buttons without looking.
*/



static bool hasVirtualStartButton[MAXPLAYERS + 1];
static bool hasVirtualEndButton[MAXPLAYERS + 1];
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

void LockVirtualButtons(int client)
{
	virtualButtonsLocked[client] = true;
}

void UnlockVirtualButtons(int client)
{
	virtualButtonsLocked[client] = false;
}



// =====[ EVENTS ]=====

void OnClientPutInServer_VirtualButtons(int client)
{
	hasVirtualEndButton[client] = false;
	hasVirtualStartButton[client] = false;
	virtualButtonsLocked[client] = false;
}

void OnStartButtonPress_VirtualButtons(int client, int course)
{
	if(!virtualButtonsLocked[client])
	{
		Movement_GetOrigin(client, virtualStartOrigin[client]);
		virtualStartCourse[client] = course;
		hasVirtualStartButton[client] = true;
	}
}

void OnEndButtonPress_VirtualButtons(int client, int course)
{
	// Prevent setting end virtual button to where it would usually be unreachable
	if (IsPlayerStuck(client))
	{
		return;
	}

	if(!virtualButtonsLocked[client])
	{
		Movement_GetOrigin(client, virtualEndOrigin[client]);
		virtualEndCourse[client] = course;
		hasVirtualEndButton[client] = true;
	}
}

void OnPlayerRunCmdPost_VirtualButtons(int client, int buttons)
{
	if (buttons & IN_USE && !(gI_OldButtons[client] & IN_USE))
	{
		if (GetHasVirtualStartButton(client) && InRangeOfVirtualStart(client) && CanReachVirtualStart(client))
		{
			if (GOKZ_StartTimer(client, virtualStartCourse[client]))
			{
				OnVirtualStartButtonPress_Teleports(client);
			}
		}
		else if (GetHasVirtualEndButton(client) && InRangeOfVirtualEnd(client) && CanReachVirtualEnd(client))
		{
			GOKZ_EndTimer(client, virtualEndCourse[client]);
		}
	}
}



// =====[ PRIVATE ]=====

static bool InRangeOfVirtualStart(int client)
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
	
	switch (GOKZ_GetCoreOption(client, Option_Mode))
	{
		case Mode_SimpleKZ:return distanceToButton <= GOKZ_SKZ_VIRTUAL_BUTTON_RADIUS;
		case Mode_KZTimer:return distanceToButton <= GOKZ_KZT_VIRTUAL_BUTTON_RADIUS;
	}
	return false;
}

static bool CanReachVirtualStart(int client)
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
