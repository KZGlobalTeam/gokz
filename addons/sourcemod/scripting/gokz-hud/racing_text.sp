/*	
	Uses HUD text to show the race countdown and a start message.

	This is manually refreshed when a race starts to show the start message	as
	soon as possible, improving responsiveness.
*/



static Handle racingHudSynchronizer;
static float countdownStartTime[MAXPLAYERS + 1];



// =====[ EVENTS ]=====

void OnPluginStart_RacingText()
{
	racingHudSynchronizer = CreateHudSynchronizer();
}

void OnPlayerRunCmdPost_RacingText(int client, int cmdnum)
{
	int updateSpeed = gB_FastUpdateRate[client] ? 3 : 6;
	if (gB_GOKZRacing && cmdnum % updateSpeed == 2)
	{
		UpdateRacingText(client);
	}
}

void OnRaceInfoChanged_RacingText(int raceID, RaceInfo prop, int newValue)
{
	if (prop != RaceInfo_Status)
	{
		return;
	}

	if (newValue == RaceStatus_Countdown)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (GOKZ_RC_GetRaceID(client) == raceID)
			{
				countdownStartTime[client] = GetGameTime();
			}
		}
	}
	else if (newValue == RaceStatus_Aborting)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (GOKZ_RC_GetRaceID(client) == raceID)
			{
				ClearRacingText(client);
			}
		}
	}
	else if (newValue == RaceStatus_Started)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (GOKZ_RC_GetRaceID(client) == raceID)
			{
				UpdateRacingText(client);
			}
		}
	}
}



// =====[ PRIVATE ]=====

static void UpdateRacingText(int client)
{
	KZPlayer player = KZPlayer(client);

	if (player.Fake)
	{
		return;
	}

	if (player.Alive)
	{
		ShowRacingText(player, player);
	}
	else
	{
		KZPlayer targetPlayer = KZPlayer(player.ObserverTarget);
		if (targetPlayer.ID != -1 && !targetPlayer.Fake)
		{
			ShowRacingText(player, targetPlayer);
		}
	}
}

static void ClearRacingText(int client)
{
	ClearSyncHud(client, racingHudSynchronizer);
}

static void ShowRacingText(KZPlayer player, KZPlayer targetPlayer)
{
	if (GOKZ_RC_GetStatus(targetPlayer.ID) != RacerStatus_Racing)
	{
		return;
	}

	int raceStatus = GOKZ_RC_GetRaceInfo(GOKZ_RC_GetRaceID(targetPlayer.ID), RaceInfo_Status);
	if (raceStatus == RaceStatus_Countdown)
	{
		ShowCountdownText(player, targetPlayer);
	}
	else if (raceStatus == RaceStatus_Started)
	{
		ShowStartedText(player, targetPlayer);
	}
}

static void ShowCountdownText(KZPlayer player, KZPlayer targetPlayer)
{
	float timeToStart = (countdownStartTime[targetPlayer.ID] + RC_COUNTDOWN_TIME) - GetGameTime();
	int colour[4];
	GetCountdownColour(timeToStart, colour);

	SetHudTextParams(-1.0, 0.3, 1.0, colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
	ShowSyncHudText(player.ID, racingHudSynchronizer, "%t\n\n%d", "Get Ready", IntMax(RoundToCeil(timeToStart), 1));
}

static float[] GetCountdownColour(float timeToStart, int buffer[4])
{
	// From red to green
	if (timeToStart >= RC_COUNTDOWN_TIME)
	{
		buffer[0] = 255;
		buffer[1] = 0;
	}
	else if (timeToStart > RC_COUNTDOWN_TIME / 2.0)
	{
		buffer[0] = 255;
		buffer[1] = RoundFloat(-510.0 / RC_COUNTDOWN_TIME * timeToStart + 510.0);
	}
	else if (timeToStart > 0.0)
	{
		buffer[0] = RoundFloat(510.0 / RC_COUNTDOWN_TIME * timeToStart);
		buffer[1] = 255;
	}
	else
	{
		buffer[0] = 0;
		buffer[1] = 255;
	}

	buffer[2] = 0;
	buffer[3] = 255;
}

static void ShowStartedText(KZPlayer player, KZPlayer targetPlayer)
{
	if (targetPlayer.TimerRunning)
	{
		return;
	}

	SetHudTextParams(-1.0, 0.3, 1.0, 0, 255, 0, 255, 0, 1.0, 0.0, 0.0);
	ShowSyncHudText(player.ID, racingHudSynchronizer, "%t", "Go!");
} 