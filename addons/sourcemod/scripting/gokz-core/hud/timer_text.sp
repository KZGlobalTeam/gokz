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
		if (targetPlayer.id != -1)
		{
			TimerTextShow(player, targetPlayer);
		}
	}
}



// =========================  LISTENERS  ========================= //

void OnPlayerRunCmd_TimerText(int client, int tickcount)
{
	if ((tickcount + client) % 32 == 0)
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
	
	switch (player.timerText)
	{
		case TimerText_Top:
		{
			SetHudTextParams(-1.0, 0.013, 0.5, 255, 255, 255, 0, 0, 0.0, 0.0, 0.0);
		}
		case TimerText_Bottom:
		{
			SetHudTextParams(-1.0, 0.957, 0.5, 255, 255, 255, 0, 0, 0.0, 0.0, 0.0);
		}
	}
	
	ShowHudText(player.id, 0, GOKZ_FormatTime(targetPlayer.currentTime, false));
} 