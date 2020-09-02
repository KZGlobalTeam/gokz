/*
	Detects when players are in bunnyhop/timed ladder triggers and
	shouldn't be allowed to checkpoint.
*/



static float lastTrigMultiTouchTime[MAXPLAYERS + 1];
static float lastTrigTeleTouchTime[MAXPLAYERS + 1];
static float lastTouchGroundTime[MAXPLAYERS + 1];
static int triggerTouchCount[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool BhopTriggersJustTouched(int client)
{
	if (GetEngineTime() - lastTouchGroundTime[client] < GOKZ_BHOP_NO_CHECKPOINT_TIME
		&& GetEngineTime() - lastTrigMultiTouchTime[client] < GOKZ_BHOP_NO_CHECKPOINT_TIME)
	{
		return true;
	}
	
	return Movement_GetMovetype(client) == MOVETYPE_LADDER
		&& triggerTouchCount[client] > 0
		&& GetEngineTime() - lastTrigTeleTouchTime[client] < GOKZ_LADDER_NO_CHECKPOINT_TIME;
}



// =====[ EVENTS ]=====

void OnClientPutInServer_BhopTriggers(int client)
{
	triggerTouchCount[client] = 0;
}

void OnEntitySpawned_MapBhopTriggers(int entity)
{
	char tempString[32];
	
	GetEntityClassname(entity, tempString, sizeof(tempString));
	if (StrEqual("trigger_multiple", tempString))
	{
		SDKHook(entity, SDKHook_StartTouchPost, OnTrigMultTouchStart_MapBhopTriggers);
		SDKHook(entity, SDKHook_EndTouchPost, OnTrigMultTouchEnd_MapBhopTriggers);
	}
	else if (StrEqual("trigger_teleport", tempString))
	{
		SDKHook(entity, SDKHook_StartTouchPost, OnTrigTeleTouchStart_MapBhopTriggers);
		SDKHook(entity, SDKHook_EndTouchPost, OnTrigTeleTouchEnd_MapBhopTriggers);
	}
}

public void OnTrigMultTouchStart_MapBhopTriggers(int entity, int other)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	lastTrigMultiTouchTime[other] = GetEngineTime();
	triggerTouchCount[other]++;
}

public void OnTrigMultTouchEnd_MapBhopTriggers(int entity, int other)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	triggerTouchCount[other]--;
}

public void OnTrigTeleTouchStart_MapBhopTriggers(int entity, int other)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	lastTrigTeleTouchTime[other] = GetEngineTime();
	triggerTouchCount[other]++;
}

public void OnTrigTeleTouchEnd_MapBhopTriggers(int entity, int other)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	triggerTouchCount[other]--;
}

void OnStartTouchGround_MapBhopTriggers(int client)
{
	lastTouchGroundTime[client] = GetEngineTime();
}

void OnChangeMovetype_MapBhopTriggers(int client, MoveType newMovetype)
{
	if (newMovetype == MOVETYPE_LADDER)
	{
		lastTouchGroundTime[client] = GetEngineTime();
	}
} 