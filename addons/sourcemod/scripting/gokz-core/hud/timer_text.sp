/*
	Timer Text
	
	Uses ShowSyncHudText to show current run time somewhere on the screen.
	
	This is updated every ~0.25s and whenever timer is started, stopped etc.
*/



static Handle timerHudSynchronizer;



// =========================  PUBLIC  ========================= //

void CreateHudSynchronizerTimerText()
{
	timerHudSynchronizer = CreateHudSynchronizer();
}



// =========================  LISTENERS  ========================= //

void OnPlayerRunCmd_TimerText(int client, int cmdnum)
{
	if (cmdnum % 32 == 0)
	{
		UpdateTimerText(client);
	}
}

void OnOptionChanged_TimerText(int client, Option option)
{
	if (option == Option_TimerText)
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



// =========================  PRIVATE  ========================= //

static void UpdateTimerText(int client)
{
	KZPlayer player = new KZPlayer(client);
	
	if (player.fake
		 || player.timerText != TimerText_Bottom && player.timerText != TimerText_Top)
	{
		return;
	}
	
	if (player.alive)
	{
		TimerTextShow(player, player);
	}
	else
	{
		KZPlayer targetPlayer = new KZPlayer(player.observerTarget);
		if (targetPlayer.id != -1 && !targetPlayer.fake)
		{
			TimerTextShow(player, targetPlayer);
		}
	}
}

static void ClearTimerText(int client)
{
	ClearSyncHud(client, timerHudSynchronizer);
}

static void TimerTextShow(KZPlayer player, KZPlayer targetPlayer)
{
	if (!targetPlayer.timerRunning)
	{
		return;
	}
	
	int colour[4]; // RGBA
	switch (GetCurrentTimeType(targetPlayer.id))
	{
		case TimeType_Nub:colour =  { 255, 221, 153, 0 };
		case TimeType_Pro:colour =  { 160, 205, 255, 0 };
	}
	
	switch (player.timerText)
	{
		case TimerText_Top:
		{
			SetHudTextParams(-1.0, 0.013, 2.5, colour[0], colour[1], colour[2], colour[3], 0, 0.0, 0.0, 0.0);
		}
		case TimerText_Bottom:
		{
			SetHudTextParams(-1.0, 0.957, 2.5, colour[0], colour[1], colour[2], colour[3], 0, 0.0, 0.0, 0.0);
		}
	}
	
	ShowSyncHudText(player.id, timerHudSynchronizer, GOKZ_FormatTime(targetPlayer.currentTime, false));
} 