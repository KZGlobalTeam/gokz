/*
	Bunnyhop Trigger Detection
	
	Detects when players are on bunnyhop triggers and
	shouldn't be allowed to checkpoint.
*/



#define BHOP_TRIG_DETECTION_TIME 0.15 // Time after touching trigger_multiple to block checkpoints

static float lastTrigMultiTouchTime[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

bool BhopTriggersJustTouched(int client)
{
	if (JustLanded(client)
		 && GetEngineTime() - lastTrigMultiTouchTime[client] < BHOP_TRIG_DETECTION_TIME)
	{
		return true;
	}
	return false;
}

static bool JustLanded(int client)
{
	// Includes safety check in case MovementAPI landing tick hasn't updated
	// which was found to be a problem allowing the player to checkpoint
	// at the exact time of landing.
	return (GetGameTickCount() - Movement_GetLandingTick(client)) < (BHOP_TRIG_DETECTION_TIME / GetTickInterval())
	 || Movement_GetTakeoffTick(client) > Movement_GetLandingTick(client);
}



// =========================  LISTENERS  ========================= //

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