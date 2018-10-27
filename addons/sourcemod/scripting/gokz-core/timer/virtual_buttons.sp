/*	
	Virtual Buttons
	
	Lets players press 'virtual' start and end buttons without looking.
*/



#define SIMPLEKZ_VIRTUAL_BUTTON_RADIUS 32.0 
#define KZTIMER_VIRTUAL_BUTTON_RADIUS 70.0

static bool hasVirtualStartButton[MAXPLAYERS + 1];
static bool hasVirtualEndButton[MAXPLAYERS + 1];

static float virtualStartOrigin[MAXPLAYERS + 1][3];
static float virtualEndOrigin[MAXPLAYERS + 1][3];

static int virtualStartCourse[MAXPLAYERS + 1];
static int virtualEndCourse[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

bool GetHasVirtualStartButton(int client)
{
	return hasVirtualStartButton[client];
}

bool GetHasVirtualEndButton(int client)
{
	return hasVirtualEndButton[client];
}



// =========================  LISTENERS  ========================= //

void SetupClientVirtualButtons(int client)
{
	hasVirtualEndButton[client] = false;
	hasVirtualStartButton[client] = false;
}

void OnStartButtonPress_VirtualButtons(int client, int course)
{
	Movement_GetOrigin(client, virtualStartOrigin[client]);
	virtualStartCourse[client] = course;
	hasVirtualStartButton[client] = true;
}

void OnEndButtonPress_VirtualButtons(int client, int course)
{
	Movement_GetOrigin(client, virtualEndOrigin[client]);
	virtualEndCourse[client] = course;
	hasVirtualEndButton[client] = true;
}

void OnPlayerRunCmd_VirtualButtons(int client, int buttons)
{
	if (buttons & IN_USE && !(gI_OldButtons[client] & IN_USE))
	{
		if (GetHasVirtualStartButton(client) && InRangeOfVirtualStart(client) && CanReachVirtualStart(client))
		{
			TimerStart(client, virtualStartCourse[client]);
		}
		else if (GetHasVirtualEndButton(client) && InRangeOfVirtualEnd(client) && CanReachVirtualEnd(client))
		{
			TimerEnd(client, virtualEndCourse[client]);
		}
	}
}



// =========================  PRIVATE  ========================= //

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
		case Mode_SimpleKZ:return distanceToButton <= SIMPLEKZ_VIRTUAL_BUTTON_RADIUS;
		case Mode_KZTimer:return distanceToButton <= KZTIMER_VIRTUAL_BUTTON_RADIUS;
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