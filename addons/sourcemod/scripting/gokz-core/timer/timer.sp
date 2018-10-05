/*
	Timer
	
	Used to record how long the player takes to complete map courses.
*/



#define TIMER_START_MIN_TICKS_ON_GROUND 4

static const char startSounds[MODE_COUNT][] = 
{
	"common/wpn_select.wav", 
	"buttons/button9.wav", 
	"buttons/button3.wav"
};

static const char endSounds[MODE_COUNT][] = 
{
	"common/wpn_select.wav", 
	"buttons/bell1.wav", 
	"buttons/button3.wav"
};

static const char falseEndSounds[MODE_COUNT][] = 
{
	"common/wpn_select.wav", 
	"buttons/button11.wav", 
	"buttons/button2.wav"
};

static const char stopSound[] = "buttons/button18.wav";

static bool timerRunning[MAXPLAYERS + 1];
static float currentTime[MAXPLAYERS + 1];
static int currentCourse[MAXPLAYERS + 1];
static bool hasStartedTimerThisMap[MAXPLAYERS + 1];
static bool hasEndedTimerThisMap[MAXPLAYERS + 1];
static float lastTimerEndTime[MAXPLAYERS + 1];
static float lastTimerFalseEndSoundTime[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

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
		 || (!Movement_GetOnGround(client) || !gB_OldOnGround[client] || GetGameTickCount() - Movement_GetLandingTick(client) <= TIMER_START_MIN_TICKS_ON_GROUND) && !allowOffGround
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
		if (!JustEndedTimer(client) && !JustPlayedTimerFalseEndSound(client)) {
			PlayTimerFalseEndSound(client);
		}
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



// =========================  LISTENERS  ========================= //

void SetupClientTimer(int client)
{
	timerRunning[client] = false;
	hasStartedTimerThisMap[client] = false;
	hasEndedTimerThisMap[client] = false;
	currentTime[client] = 0.0;
	lastTimerEndTime[client] = 0.0;
	lastTimerFalseEndSoundTime[client] = 0.0;
}

void OnPlayerRunCmd_Timer(int client)
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
			GOKZ_PrintToChat(client, true, "%t", "Time Stopped (Noclipped)");
		}
	}
}

void OnTeleportToStart_Timer(int client, bool customPos)
{
	if (GetCurrentMapPrefix() == MapPrefix_KZPro)
	{
		TimerStop(client, false);
	}
	if (GetOption(client, Option_AutoRestart) == AutoRestart_Enabled
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
			GOKZ_PrintToChat(client, true, "%t", "Time Stopped (Changed Mode)");
		}
	}
}

void OnRoundStart_Timer()
{
	TimerStopAll();
}



// =========================  PRIVATE  ========================= //

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

static bool JustPlayedTimerFalseEndSound(int client)
{
	return (GetGameTime() - lastTimerFalseEndSoundTime[client]) < 0.05;
}

static void PlayTimerStartSound(int client)
{
	EmitSoundToClient(client, startSounds[GetOption(client, Option_Mode)]);
	EmitSoundToClientSpectators(client, startSounds[GetOption(client, Option_Mode)]);
}

static void PlayTimerEndSound(int client)
{
	EmitSoundToClient(client, endSounds[GetOption(client, Option_Mode)]);
	EmitSoundToClientSpectators(client, endSounds[GetOption(client, Option_Mode)]);
}

static void PlayTimerFalseEndSound(int client)
{
	EmitSoundToClient(client, falseEndSounds[GetOption(client, Option_Mode)]);
	EmitSoundToClientSpectators(client, falseEndSounds[GetOption(client, Option_Mode)]);
	lastTimerFalseEndSoundTime[client] = GetGameTime();
}

static void PlayTimerStopSound(int client)
{
	EmitSoundToClient(client, stopSound);
	EmitSoundToClientSpectators(client, stopSound);
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
					gC_ModeNamesShort[GetOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Map (PRO)", 
					client, 
					GOKZ_FormatTime(currentTime[client]), 
					gC_ModeNamesShort[GetOption(client, Option_Mode)]);
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
					gC_ModeNamesShort[GetOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Bonus (PRO)", 
					client, 
					currentCourse[client], 
					GOKZ_FormatTime(currentTime[client]), 
					gC_ModeNamesShort[GetOption(client, Option_Mode)]);
			}
		}
	}
} 