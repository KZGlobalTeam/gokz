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

public int PanelHandler_Menu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		gB_MenuShowing[param1] = false;
	}
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
	
	if (player.TimerText == TimerText_TPMenu)
	{
		// If there is no menu showing, or if the TP menu is currently showing;
		// and if player is spectating, or is alive with TP menu disabled and not paused
		
		// Note that we don't mind if player we're spectating is paused etc. as there are too
		// many variables to track whether we need to update the timer text for the spectator.
		
		if ((gB_MenuShowing[player.ID] || GetClientMenu(player.ID) == MenuSource_None)
			 && (player.ID != info.ID || player.TPMenu == TPMenu_Disabled && !player.Paused))
		{
			// Use a Panel if want to show ONLY timer text (not TP menu)
			// as it doesn't seem to be possible to display a Menu with no items.
			Panel panel = new Panel(null);
			panel.SetTitle(FormatTimerTextForMenu(player, info));
			int observerTarget = GetObserverTarget(player.ID);
			if (observerTarget != -1 && IsFakeClient(observerTarget)
				 && info.TimeType == TimeType_Nub)
			{
				char text[32];
				FormatEx(text, sizeof(text), "%t", "TP Menu - Spectator Teleports", info.CurrentTeleport);
				panel.DrawItem(text, ITEMDRAW_RAWLINE);
			}
			panel.Send(player.ID, PanelHandler_Menu, MENU_TIME_FOREVER);
			delete panel;
			gB_MenuShowing[player.ID] = true;
		}
	}
	else if (player.TimerText == TimerText_Top || player.TimerText == TimerText_Bottom)
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
				SetHudTextParams(-1.0, 0.07, 1.0, colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
			case TimerText_Bottom:
			{
				SetHudTextParams(-1.0, 0.9, 1.0, colour[0], colour[1], colour[2], colour[3], 0, 1.0, 0.0, 0.0);
			}
		}
		
		ShowSyncHudText(player.ID, timerHudSynchronizer, GOKZ_HUD_FormatTime(player.ID, info.Time));
	}
} 