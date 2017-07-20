/*
	Timer
	
	Used to record how long the player takes to complete map courses.
*/



#define MODE_VANILLA_SOUND_START "buttons/button9.wav"
#define MODE_VANILLA_SOUND_END "buttons/bell1.wav"
#define MODE_SIMPLEKZ_SOUND_START "buttons/button9.wav"
#define MODE_SIMPLEKZ_SOUND_END "buttons/bell1.wav"
#define MODE_KZTIMER_SOUND_START "buttons/button3.wav"
#define MODE_KZTIMER_SOUND_END "buttons/button3.wav"
#define SOUND_TIMER_STOP "buttons/button18.wav"

static bool timerRunning[MAXPLAYERS + 1];
static float currentTime[MAXPLAYERS + 1];
static int currentCourse[MAXPLAYERS + 1];
static bool hasStartedTimerThisMap[MAXPLAYERS + 1];
static bool hasEndedTimerThisMap[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

bool GetTimerRunning(int client)
{
	return timerRunning[client];
}

float GetCurrentTime(int client)
{
	return currentTime[client];
}

int GetCurrentCourse(int client)
{
	return currentCourse[client];
}

bool GetHasStartedTimerThisMap(int client)
{
	return hasStartedTimerThisMap[client];
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
		 || !Movement_GetOnGround(client) && !allowOffGround
		 || Movement_GetMoveType(client) != MOVETYPE_WALK
		 || timerRunning[client] && currentTime[client] < 0.1)
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
	if (!IsPlayerAlive(client)
		 || !timerRunning[client]
		 || course != currentCourse[client])
	{
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
	PlayTimerEndSound(client);
	
	// Print end timer message
	Call_GOKZ_OnTimerEndMessage(client, course, time, teleportsUsed, result);
	if (result == Plugin_Continue)
	{
		PrintEndTimeString(client);
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
}

void OnPlayerRunCmd_Timer(int client)
{
	if (IsPlayerAlive(client) && timerRunning[client] && !GetPaused(client))
	{
		currentTime[client] += GetTickInterval();
	}
}

void OnChangeMoveType_Timer(int client, MoveType newMoveType)
{
	if (newMoveType != MOVETYPE_WALK
		 && newMoveType != MOVETYPE_LADDER
		 && newMoveType != MOVETYPE_NONE)
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
		 && !customPos && hasStartedTimerThisMap[client])
	{
		TimerStart(client, currentCourse[client], true);
	}
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

static void PlayTimerStartSound(int client)
{
	switch (GetOption(client, Option_Mode))
	{
		case Mode_Vanilla:
		{
			EmitSoundToClient(client, MODE_VANILLA_SOUND_START);
			EmitSoundToClientSpectators(client, MODE_VANILLA_SOUND_START);
		}
		case Mode_SimpleKZ:
		{
			EmitSoundToClient(client, MODE_SIMPLEKZ_SOUND_START);
			EmitSoundToClientSpectators(client, MODE_SIMPLEKZ_SOUND_START);
		}
		case Mode_KZTimer:
		{
			EmitSoundToClient(client, MODE_KZTIMER_SOUND_START);
			EmitSoundToClientSpectators(client, MODE_KZTIMER_SOUND_START);
		}
	}
}

static void PlayTimerEndSound(int client)
{
	switch (GetOption(client, Option_Mode))
	{
		case Mode_Vanilla:
		{
			EmitSoundToClient(client, MODE_VANILLA_SOUND_END);
			EmitSoundToClientSpectators(client, MODE_VANILLA_SOUND_END);
		}
		case Mode_SimpleKZ:
		{
			EmitSoundToClient(client, MODE_SIMPLEKZ_SOUND_END);
			EmitSoundToClientSpectators(client, MODE_SIMPLEKZ_SOUND_END);
		}
		case Mode_KZTimer:
		{
			EmitSoundToClient(client, MODE_KZTIMER_SOUND_END);
			EmitSoundToClientSpectators(client, MODE_KZTIMER_SOUND_END);
		}
	}
}

static void PlayTimerStopSound(int client)
{
	EmitSoundToClient(client, SOUND_TIMER_STOP);
	EmitSoundToClientSpectators(client, SOUND_TIMER_STOP);
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