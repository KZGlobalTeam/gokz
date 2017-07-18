/*
	Bunnyhop Trigger Detection
	
	Detects when players are on bunnyhop triggers and
	shouldn't be allowed to checkpoint.
*/



#define BHOP_DETECTION_TIME 0.15 // Time after touching trigger_multiple to block checkpoints

static int justTouchedTrigMult[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

bool BhopTriggersJustTouched(int client)
{
	// If just touched trigger_multiple and landed within 0.2 seconds ago
	if ((justTouchedTrigMult[client] > 0)
		 && (GetGameTickCount() - Movement_GetLandingTick(client))
		 < (BHOP_DETECTION_TIME / GetTickInterval()))
	{
		return true;
	}
	return false;
}



// =========================  LISTENERS  ========================= //

void SetupClientBhopTriggers(int client)
{
	justTouchedTrigMult[client] = 0;
}

void OnTrigMultTouch_BhopTriggers(int activator)
{
	if (IsValidClient(activator))
	{
		justTouchedTrigMult[activator]++;
		CreateTimer(BHOP_DETECTION_TIME, TrigMultTouchDelayed, GetClientUserId(activator));
	}
}



// =========================  HANDLERS  ========================= //

public Action TrigMultTouchDelayed(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		if (justTouchedTrigMult[client] > 0)
		{
			justTouchedTrigMult[client]--;
		}
	}
	return Plugin_Continue;
} 