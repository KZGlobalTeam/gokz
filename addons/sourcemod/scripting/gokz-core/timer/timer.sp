static bool timerRunning[MAXPLAYERS + 1];
static float currentTime[MAXPLAYERS + 1];
static int currentCourse[MAXPLAYERS + 1];
static float lastEndTime[MAXPLAYERS + 1];
static float lastFalseEndTime[MAXPLAYERS + 1];
static float lastStartSoundTime[MAXPLAYERS + 1];
static int lastStartMode[MAXPLAYERS + 1];
static bool validTime[MAXPLAYERS + 1];


// =====[ PUBLIC ]=====

bool GetTimerRunning(int client)
{
	return timerRunning[client];
}

bool GetValidTimer(int client)
{
	return validTime[client];
}

float GetCurrentTime(int client)
{
	return currentTime[client];
}

void SetCurrentTime(int client, float time)
{
	currentTime[client] = time;
	// The timer should be running if time is not negative.
	timerRunning[client] = time >= 0.0;
}

int GetCurrentCourse(int client)
{
	return currentCourse[client];
}

void SetCurrentCourse(int client, int course)
{
	currentCourse[client] = course;
}

int GetCurrentTimeType(int client)
{
	if (GetTeleportCount(client) == 0)
	{
		return TimeType_Pro;
	}
	return TimeType_Nub;
}

bool TimerStart(int client, int course, bool allowMidair = false, bool playSound = true)
{
	if (!IsPlayerAlive(client)
		 || JustStartedTimer(client)
		 || JustTeleported(client)
		 || JustNoclipped(client)
		 || !IsPlayerValidMoveType(client)
		 || !allowMidair && (!Movement_GetOnGround(client) || JustLanded(client))
		 || allowMidair && !Movement_GetOnGround(client) && (!GOKZ_GetValidJump(client) || GOKZ_GetHitPerf(client))
		 || (GOKZ_GetTimerRunning(client) && GOKZ_GetCourse(client) != course))
	{
		return false;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTimerStart(client, course, result);
	if (result != Plugin_Continue)
	{
		return false;
	}

	// Prevent noclip exploit
	SetEntProp(client, Prop_Send, "m_CollisionGroup", GOKZ_COLLISION_GROUP_STANDARD);

	// Start Timer
	currentTime[client] = 0.0;
	timerRunning[client] = true;
	currentCourse[client] = course;
	lastStartMode[client] = GOKZ_GetCoreOption(client, Option_Mode);
	validTime[client] = true;
	if (playSound)
	{
		PlayTimerStartSound(client);
	}
	
	// Call Post Forward
	Call_GOKZ_OnTimerStart_Post(client, course);
	
	return true;
}

bool TimerEnd(int client, int course)
{
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	
	if (!timerRunning[client] || course != currentCourse[client])
	{
		PlayTimerFalseEndSound(client);
		lastFalseEndTime[client] = GetGameTime();
		return false;
	}
	
	float time = GetCurrentTime(client);
	int teleportsUsed = GetTeleportCount(client);
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTimerEnd(client, course, time, teleportsUsed, result);
	if (result != Plugin_Continue)
	{
		return false;
	}
	
	if (!validTime[client])
	{
		PlayTimerFalseEndSound(client);
		lastFalseEndTime[client] = GetGameTime();
		TimerStop(client, false);
		return false;
	}
	// End Timer
	timerRunning[client] = false;
	lastEndTime[client] = GetGameTime();
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
	
	return true;
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

void PlayTimerStartSound(int client)
{
	if (GetGameTime() - lastStartSoundTime[client] > GOKZ_TIMER_SOUND_COOLDOWN)
	{
		EmitSoundToClient(client, gC_ModeStartSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
		EmitSoundToClientSpectators(client, gC_ModeStartSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
		lastStartSoundTime[client] = GetGameTime();
	}
}

void InvalidateRun(int client)
{
	if (validTime[client])
	{
		validTime[client] = false;
		Call_GOKZ_OnRunInvalidated(client);
	}
}

// =====[ EVENTS ]=====

void OnClientPutInServer_Timer(int client)
{
	timerRunning[client] = false;
	currentTime[client] = 0.0;
	currentCourse[client] = 0;
	lastEndTime[client] = 0.0;
	lastFalseEndTime[client] = 0.0;
	lastStartSoundTime[client] = 0.0;
	lastStartMode[client] = MODE_COUNT; // So it won't equal any mode
}

void OnPlayerRunCmdPost_Timer(int client)
{
	if (IsPlayerAlive(client) && GetTimerRunning(client) && !GetPaused(client))
	{
		currentTime[client] += GetTickInterval();
	}
}

void OnChangeMovetype_Timer(int client, MoveType newMovetype)
{
	if (!IsValidMovetype(newMovetype))
	{
		if (TimerStop(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Timer Stopped (Noclipped)");
		}
	}
}

void OnTeleportToStart_Timer(int client)
{
	if (GetCurrentMapPrefix() == MapPrefix_KZPro)
	{
		TimerStop(client, false);
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
	return IsValidMovetype(Movement_GetMovetype(client));
}

static bool IsValidMovetype(MoveType movetype)
{
	return movetype == MOVETYPE_WALK
	 || movetype == MOVETYPE_LADDER
	 || movetype == MOVETYPE_NONE
	 || movetype == MOVETYPE_OBSERVER;
}

static bool JustTeleported(int client)
{
	return gB_OriginTeleported[client] || gB_VelocityTeleported[client]
	 || gI_CmdNum[client] - gI_TeleportCmdNum[client] <= GOKZ_TIMER_START_GROUND_TICKS;
}

static bool JustLanded(int client)
{
	return !gB_OldOnGround[client]
	 || gI_CmdNum[client] - Movement_GetLandingCmdNum(client) <= GOKZ_TIMER_START_NO_TELEPORT_TICKS;
}

static bool JustStartedTimer(int client)
{
	return timerRunning[client] && GetCurrentTime(client) < EPSILON;
}

static bool JustEndedTimer(int client)
{
	return GetGameTime() - lastEndTime[client] < 1.0;
}

static void PlayTimerEndSound(int client)
{
	EmitSoundToClient(client, gC_ModeEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
	EmitSoundToClientSpectators(client, gC_ModeEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
}

static void PlayTimerFalseEndSound(int client)
{
	if (!JustEndedTimer(client)
		 && (GetGameTime() - lastFalseEndTime[client]) > GOKZ_TIMER_SOUND_COOLDOWN)
	{
		EmitSoundToClient(client, gC_ModeFalseEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
		EmitSoundToClientSpectators(client, gC_ModeFalseEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
	}
}

static void PlayTimerStopSound(int client)
{
	EmitSoundToClient(client, GOKZ_SOUND_TIMER_STOP);
	EmitSoundToClientSpectators(client, GOKZ_SOUND_TIMER_STOP);
}

static void PrintEndTimeString(int client)
{
	if (GetCurrentCourse(client) == 0)
	{
		switch (GetCurrentTimeType(client))
		{
			case TimeType_Nub:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Map (NUB)", 
					client, 
					GOKZ_FormatTime(GetCurrentTime(client)), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Map (PRO)", 
					client, 
					GOKZ_FormatTime(GetCurrentTime(client)), 
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
					GOKZ_FormatTime(GetCurrentTime(client)), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Bonus (PRO)", 
					client, 
					currentCourse[client], 
					GOKZ_FormatTime(GetCurrentTime(client)), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
		}
	}
} 