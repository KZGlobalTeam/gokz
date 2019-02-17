/*
	Detects when players are in bunnyhop/timed ladder triggers and
	shouldn't be allowed to checkpoint.
*/



static float lastTrigMultiTouchTime[MAXPLAYERS + 1];
static float lastTouchGroundTime[MAXPLAYERS + 1];
static float lastTouchLadderTime[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool BhopTriggersJustTouched(int client)
{
	if (Movement_GetMoveType(client) == MOVETYPE_LADDER)
	{
		return GetEngineTime() - lastTouchLadderTime[client] < GOKZ_LADDER_NO_CHECKPOINT_TIME
		 && GetEngineTime() - lastTrigMultiTouchTime[client] < GOKZ_LADDER_NO_CHECKPOINT_TIME;
	}
	else
	{
		return GetEngineTime() - lastTouchGroundTime[client] < GOKZ_BHOP_NO_CHECKPOINT_TIME
		 && GetEngineTime() - lastTrigMultiTouchTime[client] < GOKZ_BHOP_NO_CHECKPOINT_TIME;
	}
}



// =====[ EVENTS ]=====

void OnEntitySpawned_MapBhopTriggers(int entity)
{
	char tempString[32];
	
	GetEntityClassname(entity, tempString, sizeof(tempString));
	if (!StrEqual("trigger_multiple", tempString))
	{
		return;
	}
	
	SDKHook(entity, SDKHook_StartTouchPost, OnTrigMultTouch_MapBhopTriggers);
}

public void OnTrigMultTouch_MapBhopTriggers(int entity, int other)
{
	if (!IsValidClient(other))
	{
		return;
	}
	
	lastTrigMultiTouchTime[other] = GetEngineTime();
}

void OnStartTouchGround_MapBhopTriggers(int client)
{
	lastTouchGroundTime[client] = GetEngineTime();
}

void OnChangeMoveType_MapBhopTriggers(int client, MoveType newMoveType)
{
	if (newMoveType == MOVETYPE_LADDER)
	{
		lastTouchLadderTime[client] = GetEngineTime();
	}
} 