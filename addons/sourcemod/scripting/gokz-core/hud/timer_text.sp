/*
	Timer Text
	
	Uses ShowHudText to show current run time somewhere on the screen.
*/



// =========================  PUBLIC  ========================= //

void UpdateTimerText(int client)
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



// =========================  LISTENERS  ========================= //

void OnPlayerRunCmd_TimerText(int client, int cmdnum)
{
	if (cmdnum % 32 == 0)
	{
		UpdateTimerText(client);
	}
}



// =========================  PRIVATE  ========================= //

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
			SetHudTextParams(-1.0, 0.013, 0.5, colour[0], colour[1], colour[2], colour[3], 0, 0.0, 0.0, 0.0);
		}
		case TimerText_Bottom:
		{
			SetHudTextParams(-1.0, 0.957, 0.5, colour[0], colour[1], colour[2], colour[3], 0, 0.0, 0.0, 0.0);
		}
	}
	
	ShowHudText(player.id, 0, GOKZ_FormatTime(targetPlayer.currentTime, false));
} 