static bool timerRunning[MAXPLAYERS + 1];
static float currentTime[MAXPLAYERS + 1];
static int currentCourse[MAXPLAYERS + 1];
static bool hasStartedTimerThisMap[MAXPLAYERS + 1];
static bool hasEndedTimerThisMap[MAXPLAYERS + 1];
static float lastTimerEndTime[MAXPLAYERS + 1];
static float lastFalseEndTime[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool GetTimerRunning(int client)
{
	return timerRunning[client];
}

float GetCurrentTime(int client)
{
	return currentTime[client];
}

float SetCurrentTime(int client, float time)
{
	currentTime[client] = time;
}

int GetCurrentCourse(int client)
{
	return currentCourse[client];
}

bool GetHasStartedTimerThisMap(int client)
{
	return hasStartedTimerThisMap[client];
}

bool GetHasEndedTimerThisMap(int client)
{
	return hasEndedTimerThisMap[client];
}

int GetCurrentTimeType(int client)
{
	if (GetTeleportCount(client) == 0)
	{
		return TimeType_Pro;
	}
	return TimeType_Nub;
}

void TimerStart(int client, int course, bool allowOffGround = false)
{
	if (!IsPlayerAlive(client)
		 || (!Movement_GetOnGround(client) || !gB_OldOnGround[client] || GetGameTickCount() - Movement_GetLandingTick(client) <= GOKZ_TIMER_START_GROUND_TICKS) && !allowOffGround
		 || !IsPlayerValidMoveType(client)
		 || JustStartedTimer(client))
	{
		return;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTimerStart(client, course, result);
	if (result != Plugin_Continue)
	{
		return;
	}
	
	// Start Timer
	currentTime[client] = 0.0;
	timerRunning[client] = true;
	currentCourse[client] = course;
	hasStartedTimerThisMap[client] = true;
	PlayTimerStartSound(client);
	
	// Call Post Forward
	Call_GOKZ_OnTimerStart_Post(client, course);
}

void TimerEnd(int client, int course)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	if (!timerRunning[client] || course != currentCourse[client])
	{
		if (!JustEndedTimer(client) && !JustFalseEndedTimer(client))
		{
			PlayTimerFalseEndSound(client);
		}
		lastFalseEndTime[client] = GetGameTime();
		return;
	}
	
	float time = GetCurrentTime(client);
	int teleportsUsed = GetTeleportCount(client);
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTimerEnd(client, course, time, teleportsUsed, result);
	if (result != Plugin_Continue)
	{
		return;
	}
	
	// End Timer
	timerRunning[client] = false;
	hasEndedTimerThisMap[client] = true;
	lastTimerEndTime[client] = GetGameTime();
	PlayTimerEndSound(client);
	
	if (!IsFakeClient(client))
	{
		// Print end timer message
		Call_GOKZ_OnTimerEndMessage(client, course, time, teleportsUsed, result);
		if (result == Plugin_Continue)
		{
			PrintEndTimeString(client);
		}
	}
	
	// Call Post Forward
	Call_GOKZ_OnTimerEnd_Post(client, course, time, teleportsUsed);
}

bool TimerStop(int client, bool playSound = true)
{
	if (!timerRunning[client])
	{
		return false;
	}
	
	timerRunning[client] = false;
	if (playSound)
	{
		PlayTimerStopSound(client);
	}
	
	Call_GOKZ_OnTimerStopped(client);
	
	return true;
}

void TimerStopAll(bool playSound = true)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			TimerStop(client, playSound);
		}
	}
}



// =====[ EVENTS ]=====

void OnClientPutInServer_Timer(int client)
{
	timerRunning[client] = false;
	hasStartedTimerThisMap[client] = false;
	hasEndedTimerThisMap[client] = false;
	currentTime[client] = 0.0;
	lastTimerEndTime[client] = 0.0;
	lastFalseEndTime[client] = 0.0;
}

void OnPlayerRunCmdPost_Timer(int client)
{
	if (IsPlayerAlive(client) && GetTimerRunning(client) && !GetPaused(client))
	{
		currentTime[client] += GetTickInterval();
	}
}

void OnChangeMoveType_Timer(int client, MoveType newMoveType)
{
	if (!IsValidMoveType(newMoveType))
	{
		if (TimerStop(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Timer Stopped (Noclipped)");
		}
	}
}

void OnTeleportToStart_Timer(int client, bool customPos)
{
	if (GetCurrentMapPrefix() == MapPrefix_KZPro)
	{
		TimerStop(client, false);
	}
	if (GOKZ_GetCoreOption(client, Option_AutoRestart) == AutoRestart_Enabled
		 && !customPos && GetHasStartedTimerThisMap(client))
	{
		TimerStart(client, GetCurrentCourse(client), true);
	}
}

void OnClientDisconnect_Timer(int client)
{
	TimerStop(client);
}

void OnPlayerDeath_Timer(int client)
{
	TimerStop(client);
}

void OnOptionChanged_Timer(int client, Option option)
{
	if (option == Option_Mode)
	{
		if (TimerStop(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Timer Stopped (Changed Mode)");
		}
	}
}

void OnRoundStart_Timer()
{
	TimerStopAll();
}



// =====[ PRIVATE ]=====

static bool IsPlayerValidMoveType(int client)
{
	return IsValidMoveType(Movement_GetMoveType(client));
}

static bool IsValidMoveType(MoveType moveType)
{
	return moveType == MOVETYPE_WALK || moveType == MOVETYPE_LADDER || moveType == MOVETYPE_NONE;
}

static bool JustStartedTimer(int client)
{
	return timerRunning[client] && GetCurrentTime(client) < 0.05;
}

static bool JustEndedTimer(int client)
{
	return GetHasEndedTimerThisMap(client) && (GetGameTime() - lastTimerEndTime[client]) < 1.0;
}

static bool JustFalseEndedTimer(int client)
{
	return (GetGameTime() - lastFalseEndTime[client]) < 0.05;
}

static void PlayTimerStartSound(int client)
{
	EmitSoundToClient(client, gC_ModeStartSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
	EmitSoundToClientSpectators(client, gC_ModeStartSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
}

static void PlayTimerEndSound(int client)
{
	EmitSoundToClient(client, gC_ModeEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
	EmitSoundToClientSpectators(client, gC_ModeEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
}

static void PlayTimerFalseEndSound(int client)
{
	EmitSoundToClient(client, gC_ModeFalseEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
	EmitSoundToClientSpectators(client, gC_ModeFalseEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
}

static void PlayTimerStopSound(int client)
{
	EmitSoundToClient(client, GOKZ_SOUND_TIMER_STOP);
	EmitSoundToClientSpectators(client, GOKZ_SOUND_TIMER_STOP);
}

static void PrintEndTimeString(int client)
{
	if (currentCourse[client] == 0)
	{
		switch (GetCurrentTimeType(client))
		{
			case TimeType_Nub:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Map (NUB)", 
					client, 
					GOKZ_FormatTime(currentTime[client]), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Map (PRO)", 
					client, 
					GOKZ_FormatTime(currentTime[client]), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
		}
	}
	else
	{
		switch (GetCurrentTimeType(client))
		{
			case TimeType_Nub:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Bonus (NUB)", 
					client, 
					currentCourse[client], 
					GOKZ_FormatTime(currentTime[client]), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Bonus (PRO)", 
					client, 
					currentCourse[client], 
					GOKZ_FormatTime(currentTime[client]), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
		}
	}
} 