static bool paused[MAXPLAYERS + 1];
static bool pausedOnLadder[MAXPLAYERS + 1];
static float lastPauseTime[MAXPLAYERS + 1];
static bool hasPausedInThisRun[MAXPLAYERS + 1];
static float lastResumeTime[MAXPLAYERS + 1];
static bool hasResumedInThisRun[MAXPLAYERS + 1];
static float lastDuckValue[MAXPLAYERS + 1];
static float lastStaminaValue[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool GetPaused(int client)
{
	return paused[client];
}

void SetPausedOnLadder(int client, bool onLadder)
{
	pausedOnLadder[client] = onLadder;
}

void Pause(int client)
{
	if (!CanPause(client, true))
	{
		return;
	}

	// Call Pre Forward
	Action result;
	Call_GOKZ_OnPause(client, result);
	if (result != Plugin_Continue)
	{
		GOKZ_PrintToChat(client, true, "%t", "Can't Pause (Generic)");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	// Pause
	paused[client] = true;
	pausedOnLadder[client] = Movement_GetMovetype(client) == MOVETYPE_LADDER;
	lastDuckValue[client] = Movement_GetDuckSpeed(client);
	lastStaminaValue[client] = GetEntPropFloat(client, Prop_Send, "m_flStamina");
	Movement_SetVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
	Movement_SetMovetype(client, MOVETYPE_NONE);
	if (GetTimerRunning(client))
	{
		hasPausedInThisRun[client] = true;
		lastPauseTime[client] = GetEngineTime();
	}
	
	// Call Post Forward
	Call_GOKZ_OnPause_Post(client);
}

bool CanPause(int client, bool showError = false)
{
	if (paused[client])
	{
		return false;
	}
	
	if (GetTimerRunning(client))
	{
		if (hasResumedInThisRun[client]
			 && GetEngineTime() - lastResumeTime[client] < GOKZ_PAUSE_COOLDOWN)
		{
			if (showError)
			{
				GOKZ_PrintToChat(client, true, "%t", "Can't Pause (Just Resumed)");
				GOKZ_PlayErrorSound(client);
			}
			return false;
		}
		else if (!Movement_GetOnGround(client)
			 && !(Movement_GetSpeed(client) == 0 && Movement_GetVerticalVelocity(client) == 0))
		{
			if (showError)
			{
				GOKZ_PrintToChat(client, true, "%t", "Can't Pause (Midair)");
				GOKZ_PlayErrorSound(client);
			}
			return false;
		}
		else if (BhopTriggersJustTouched(client))
		{
			if (showError)
			{
				GOKZ_PrintToChat(client, true, "%t", "Can't Pause (Just Landed)");
				GOKZ_PlayErrorSound(client);
			}
			return false;
		}
		else if (AntiPauseTriggerIsTouched(client))
		{
			if (showError)
			{
				GOKZ_PrintToChat(client, true, "%t", "Can't Pause (Anti Pause Area)");
				GOKZ_PlayErrorSound(client);
			}
			return false;
		}
	}
	
	return true;
}

void Resume(int client, bool force = false)
{
	if (!paused[client])
	{
		return;
	}
	if (!force && !CanResume(client, true))
	{
		return;
	}

	// Call Pre Forward
	Action result;
	Call_GOKZ_OnResume(client, result);
	if (result != Plugin_Continue)
	{
		GOKZ_PrintToChat(client, true, "%t", "Can't Resume (Generic)");
		GOKZ_PlayErrorSound(client);
		return;
	}

	// Resume
	if (pausedOnLadder[client])
	{
		Movement_SetMovetype(client, MOVETYPE_LADDER);
	}
	else
	{
		Movement_SetMovetype(client, MOVETYPE_WALK);
	}
	
	// Prevent noclip exploit
	SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);
	paused[client] = false;
	if (GetTimerRunning(client))
	{
		hasResumedInThisRun[client] = true;
		lastResumeTime[client] = GetEngineTime();
	}
	Movement_SetDuckSpeed(client, lastDuckValue[client]);
	SetEntPropFloat(client, Prop_Send, "m_flStamina", lastStaminaValue[client]);
	
	// Call Post Forward
	Call_GOKZ_OnResume_Post(client);
}

bool CanResume(int client, bool showError = false)
{
	if (GetTimerRunning(client) && hasPausedInThisRun[client]
		 && GetEngineTime() - lastPauseTime[client] < GOKZ_PAUSE_COOLDOWN)
	{
		if (showError)
		{
			GOKZ_PrintToChat(client, true, "%t", "Can't Resume (Just Paused)");
			GOKZ_PlayErrorSound(client);
		}
		return false;
	}
	return true;
}

void TogglePause(int client)
{
	if (paused[client])
	{
		Resume(client);
	}
	else
	{
		Pause(client);
	}
}



// =====[ EVENTS ]=====

void OnClientPutInServer_Pause(int client)
{
	paused[client] = false;
}

void OnTimerStart_Pause(int client)
{
	hasPausedInThisRun[client] = false;
	hasResumedInThisRun[client] = false;
	Resume(client, true);
}

void OnChangeMovetype_Pause(int client, MoveType newMovetype)
{
	// Check if player has escaped MOVETYPE_NONE
	if (!paused[client] || newMovetype == MOVETYPE_NONE)
	{
		return;
	}
	
	// Player has escaped MOVETYPE_NONE, so resume
	paused[client] = false;
	if (GetTimerRunning(client))
	{
		hasResumedInThisRun[client] = true;
		lastResumeTime[client] = GetEngineTime();
	}
	
	// Call Post Forward
	Call_GOKZ_OnResume_Post(client);
}

void OnPlayerSpawn_Pause(int client)
{
	if (!paused[client])
	{
		return;
	}
	
	// Player has left paused state by spawning in, so resume
	paused[client] = false;
	if (GetTimerRunning(client))
	{
		hasResumedInThisRun[client] = true;
		lastResumeTime[client] = GetEngineTime();
	}
	
	Movement_SetDuckSpeed(client, lastDuckValue[client]);
	SetEntPropFloat(client, Prop_Send, "m_flStamina", lastStaminaValue[client]);
	
	// Call Post Forward
	Call_GOKZ_OnResume_Post(client);
}

void OnJoinTeam_Pause(int client, int team)
{
	// Only handle joining spectators. Joining other teams is handled by OnPlayerSpawn.
	if (team == CS_TEAM_SPECTATOR)
	{
		paused[client] = true;
		
		if (GetTimerRunning(client))
		{
			hasPausedInThisRun[client] = true;
			lastPauseTime[client] = GetEngineTime();
		}
		
		// Call Post Forward
		Call_GOKZ_OnPause_Post(client);
	}
} 