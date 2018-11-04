/*
	Bunnyhop Trigger Detection
	
	Detects when players are in bunnyhop/timed ladder triggers and
	shouldn't be allowed to checkpoint.
*/



// Times after touching trigger_multiple to block checkpoints
#define BHOP_TRIG_DETECTION_TIME 0.15
#define LADDER_TRIG_DETECTION_TIME 1.5

static float lastTrigMultiTouchTime[MAXPLAYERS + 1];
static float lastTouchGroundTime[MAXPLAYERS + 1];
static float lastTouchLadderTime[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool BhopTriggersJustTouched(int client)
{
	if (Movement_GetMoveType(client) == MOVETYPE_LADDER)
	{
		return GetEngineTime() - lastTouchLadderTime[client] < LADDER_TRIG_DETECTION_TIME
		 && GetEngineTime() - lastTrigMultiTouchTime[client] < LADDER_TRIG_DETECTION_TIME;
	}
	else
	{
		return GetEngineTime() - lastTouchGroundTime[client] < BHOP_TRIG_DETECTION_TIME
		 && GetEngineTime() - lastTrigMultiTouchTime[client] < BHOP_TRIG_DETECTION_TIME;
	}
}



// =====[ LISTENERS ]=====

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