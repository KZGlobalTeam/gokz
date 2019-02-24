/*	
	Uses HUD text to show current run time somewhere on the screen.
	
	This is manually refreshed whenever the players' timer is started, ended or
	stopped to improve responsiveness.
*/



static Handle timerHudSynchronizer;



// =====[ PUBLIC ]=====

char[] FormatTimerTextForMenu(KZPlayer targetPlayer)
{
	char timerTextString[32];
	FormatEx(timerTextString, sizeof(timerTextString), 
		"%s %s", 
		gC_TimeTypeNames[targetPlayer.timeType], 
		GOKZ_FormatTime(targetPlayer.time));
	return timerTextString;
}



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

public int PanelHandler_Menu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		gB_MenuShowing[param1] = false;
	}
}



// =====[ PRIVATE ]=====

static void UpdateTimerText(int client)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.fake)
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
		if (player.id != targetPlayer.id)
		{
			CancelGOKZHUDMenu(player.id);
		}
		return;
	}
	
	if (player.timerText == TimerText_TPMenu)
	{
		// If there is no menu showing, or if the TP menu is currently showing;
		// and if player is spectating, or is alive with TP menu disabled and not paused
		
		// Note that we don't mind if player we're spectating is paused etc. as there are too
		// many variables to track whether we need to update the timer text for the spectator.
		
		if ((gB_MenuShowing[player.id] || GetClientMenu(player.id) == MenuSource_None)
			 && (player.id != targetPlayer.id || player.tpMenu == TPMenu_Disabled && !player.paused))
		{
			// Use a Panel if want to show ONLY timer text (not TP menu)
			// as it doesn't seem to be possible to display a Menu with no items.
			Panel panel = new Panel(null);
			panel.SetTitle(FormatTimerTextForMenu(targetPlayer));
			panel.Send(player.id, PanelHandler_Menu, MENU_TIME_FOREVER);
			delete panel;
			gB_MenuShowing[player.id] = true;
		}
	}
	else if (player.timerText == TimerText_Top || player.timerText == TimerText_Bottom)
	{
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
} 