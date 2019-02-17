/*	
	Uses HUD text to show current run time somewhere on the screen.
	
	This is manually refreshed whenever the players' timer is started, ended or
	stopped to improve responsiveness.
*/



static Handle timerHudSynchronizer;



// =====[ EVENTS ]=====

void OnPluginStart_TimerText()
{
	timerHudSynchronizer = CreateHudSynchronizer();
}

void OnPlayerRunCmdPost_TimerText(int client, int cmdnum)
{
	if (cmdnum % 6 == 3)
	{
		UpdateTimerText(client);
	}
}

void OnOptionChanged_TimerText(int client, HUDOption option)
{
	if (option == HUDOption_TimerText)
	{
		ClearTimerText(client);
		UpdateTimerText(client);
	}
}

void OnTimerStart_TimerText(int client)
{
	UpdateTimerText(client);
}

void OnTimerEnd_TimerText(int client)
{
	ClearTimerText(client);
}

void OnTimerStopped_TimerText(int client)
{
	ClearTimerText(client);
}



// =====[ PRIVATE ]=====

static void UpdateTimerText(int client)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.fake
		 || player.timerText != TimerText_Bottom && player.timerText != TimerText_Top)
	{
		return;
	}
	
	if (player.alive)
	{
		ShowTimerText(player, player);
	}
	else
	{
		KZPlayer targetPlayer = KZPlayer(player.observerTarget);
		if (targetPlayer.id != -1 && !targetPlayer.fake)
		{
			ShowTimerText(player, targetPlayer);
		}
	}
}

static void ClearTimerText(int client)
{
	ClearSyncHud(client, timerHudSynchronizer);
}

static void ShowTimerText(KZPlayer player, KZPlayer targetPlayer)
{
	if (!targetPlayer.timerRunning)
	{
		return;
	}
	
	int colour[4]; // RGBA
	switch (targetPlayer.timeType)
	{
		case TimeType_Nub:colour =  { 234, 209, 138, 0 };
		case TimeType_Pro:colour =  { 181, 212, 238, 0 };
	}
	
	switch (player.timerText)
	{
		case TimerText_Top:
		{
			SetHudTextParams(-1.0, 0.07, 1.0, colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
		}
		case TimerText_Bottom:
		{
			SetHudTextParams(-1.0, 0.9, 1.0, colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
		}
	}
	
	ShowSyncHudText(player.id, timerHudSynchronizer, GOKZ_FormatTime(targetPlayer.time));
} 