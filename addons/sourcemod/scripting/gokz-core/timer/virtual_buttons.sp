/*	
	Virtual Buttons
	
	Lets players press buttons without looking.
*/



#define SIMPLEKZ_VIRTUAL_BUTTON_RADIUS 32.0 
#define KZTIMER_VIRTUAL_BUTTON_RADIUS 70.0

static float virtualStartOrigin[MAXPLAYERS + 1][3];
static float virtualEndOrigin[MAXPLAYERS + 1][3];

static bool hasVirtualStartPosition[MAXPLAYERS + 1];
static bool hasVirtualEndPosition[MAXPLAYERS + 1];

static int virtualStartCourse[MAXPLAYERS + 1];
static int virtualEndCourse[MAXPLAYERS + 1];

// =========================  PUBLIC  ========================= //

bool GetHasVirtualStartPosition(int client)
{
	return hasVirtualStartPosition[client];
}

bool GetHasVirtualEndPosition(int client)
{
	return hasVirtualEndPosition[client];
}

bool SetHasVirtualStartPosition(int client, bool value)
{
	hasVirtualStartPosition[client] = value;
}

bool SetHasVirtualEndPosition(int client, bool value)
{
	hasVirtualEndPosition[client] = value;
}

// =========================  LISTENERS  ========================= //

void OnPlayerRunCmd_VirtualButtons(int client, int buttons)
{
	if (buttons & IN_USE && !(gI_OldButtons[client] & IN_USE))
	{
		if (GetHasVirtualStartPosition(client) && InRangeOfStartButton(client))
		{
			TimerStart(client, virtualStartCourse[client]);
		}
		else if (GetHasVirtualEndPosition(client) && InRangeOfEndButton(client))
		{
			TimerEnd(client, virtualEndCourse[client]);
		}
	}
}

void OnStartButtonPress_VirtualButtons(int client, int course)
{
	Movement_GetOrigin(client, virtualStartOrigin[client]);
	virtualStartCourse[client] = course;
	hasVirtualStartPosition[client] = true;
}

void OnEndButtonPress_VirtualButtons(int client, int course)
{
	Movement_GetOrigin(client, virtualEndOrigin[client]);
	virtualEndCourse[client] = course;
	hasVirtualEndPosition[client] = true;
}



// =========================  PRIVATE  ========================= //

static bool InRangeOfStartButton(int client)
{
	float origin[3];
	Movement_GetOrigin(client, origin);
	float distanceToButton = GetVectorDistance(origin, virtualStartOrigin[client]);
	
	switch (GetOption(client, Option_Mode))
	{
		case Mode_SimpleKZ:return distanceToButton <= SIMPLEKZ_VIRTUAL_BUTTON_RADIUS;
		case Mode_KZTimer:return distanceToButton <= KZTIMER_VIRTUAL_BUTTON_RADIUS;
	}
	return false;
}

static bool InRangeOfEndButton(int client)
{
	float origin[3];
	Movement_GetOrigin(client, origin);
	float distanceToButton = GetVectorDistance(origin, virtualEndOrigin[client]);
	
	switch (GetOption(client, Option_Mode))
	{
		case Mode_SimpleKZ:return distanceToButton <= SIMPLEKZ_VIRTUAL_BUTTON_RADIUS;
		case Mode_KZTimer:return distanceToButton <= KZTIMER_VIRTUAL_BUTTON_RADIUS;
	}
	return false;
} 