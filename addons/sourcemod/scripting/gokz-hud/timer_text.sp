/*	
	Uses HUD text to show current run time somewhere on the screen.
	
	This is manually refreshed whenever the players' timer is started, ended or
	stopped to improve responsiveness.
*/



static Handle timerHudSynchronizer;



// =====[ PUBLIC ]=====

char[] FormatTimerTextForMenu(KZPlayer player, HUDInfo info)
{
	char timerTextString[32];
	if (info.TimerRunning)
	{
		if (player.GetHUDOption(HUDOption_TimerType) == TimerType_Enabled)
		{
			FormatEx(timerTextString, sizeof(timerTextString), 
				"%s %s", 
				gC_TimeTypeNames[info.TimeType], 
				GOKZ_HUD_FormatTime(player.ID, info.Time));
		}
		else
		{
			FormatEx(timerTextString, sizeof(timerTextString), 
				"%s", 
				GOKZ_HUD_FormatTime(player.ID, info.Time));
		}
		if (info.Paused)
		{
			Format(timerTextString, sizeof(timerTextString), "%s (%T)", timerTextString, "Info Panel Text - PAUSED", player.ID);
		}
	}
	return timerTextString;
}



// =====[ EVENTS ]=====

void OnPluginStart_TimerText()
{
	timerHudSynchronizer = CreateHudSynchronizer();
}

void OnPlayerRunCmdPost_TimerText(int client, int cmdnum, HUDInfo info)
{
	int updateSpeed = gB_FastUpdateRate[client] ? 3 : 6;
	if (cmdnum % updateSpeed == 1)
	{
		UpdateTimerText(client, info);
	}
}

void OnOptionChanged_TimerText(int client, HUDOption option)
{
	if (option == HUDOption_TimerText)
	{
		ClearTimerText(client);
	}
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

static void UpdateTimerText(int client, HUDInfo info)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.Fake)
	{
		return;
	}
	
	ShowTimerText(player, info);
}

static void ClearTimerText(int client)
{
	ClearSyncHud(client, timerHudSynchronizer);
}

static void ShowTimerText(KZPlayer player, HUDInfo info)
{
	if (!info.TimerRunning)
	{
		if (player.ID != info.ID)
		{
			CancelGOKZHUDMenu(player.ID);
		}
		return;
	}
	if (player.TimerText == TimerText_Top || player.TimerText == TimerText_Bottom)
	{
		int colour[4]; // RGBA
		if (player.GetHUDOption(HUDOption_TimerType) == TimerType_Enabled)
		{
			switch (info.TimeType)
			{
				case TimeType_Nub:colour =  { 234, 209, 138, 0 };
				case TimeType_Pro:colour =  { 181, 212, 238, 0 };
			}
		}
		else colour = { 255, 255, 255, 0};
		
		switch (player.TimerText)
		{
			case TimerText_Top:
			{
				SetHudTextParams(-1.0, 0.07, GetTextHoldTime(gB_FastUpdateRate[player.ID] ? 3 : 6), colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
			case TimerText_Bottom:
			{
				SetHudTextParams(-1.0, 0.9, GetTextHoldTime(gB_FastUpdateRate[player.ID] ? 3 : 6), colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
		}
		
		ShowSyncHudText(player.ID, timerHudSynchronizer, GOKZ_HUD_FormatTime(player.ID, info.Time));
	}
} 