/*
	Displays information using hint text.
	
	This is manually refreshed whenever player has taken off so that they see
	their pre-speed as soon as possible, improving responsiveness.
*/



static bool infoPanelDuckPressedLast[MAXPLAYERS + 1];
static bool infoPanelOnGroundLast[MAXPLAYERS + 1];
static bool infoPanelShowDuckString[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool IsDrawingInfoPanel(int client)
{
	KZPlayer player = KZPlayer(client);
	return player.InfoPanel != InfoPanel_Disabled
	 && !NothingEnabledInInfoPanel(player);
}



// =====[ EVENTS ]=====

void OnPlayerRunCmdPost_InfoPanel(int client, int cmdnum)
{
	if (cmdnum % 12 == 0 || Movement_GetTakeoffCmdNum(client) == cmdnum)
	{
		UpdateInfoPanel(client);
	}
	infoPanelOnGroundLast[client] = Movement_GetOnGround(client);
	infoPanelDuckPressedLast[client] = Movement_GetDucking(client);
}



// =====[ PRIVATE ]=====

static void UpdateInfoPanel(int client)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.Fake || !IsDrawingInfoPanel(player.ID))
	{
		return;
	}
	
	if (player.Alive)
	{
		PrintHintText(player.ID, "%s", GetInfoPanel(player, player));
	}
	else
	{
		KZPlayer targetPlayer = KZPlayer(player.ObserverTarget);
		if (targetPlayer.ID != -1 && !targetPlayer.Fake)
		{
			PrintHintText(player.ID, "%s", GetInfoPanel(player, targetPlayer));
		}
	}
}

static bool NothingEnabledInInfoPanel(KZPlayer player)
{
	bool noTimerText = player.TimerText != TimerText_InfoPanel;
	bool noSpeedText = player.SpeedText != SpeedText_InfoPanel || player.Paused;
	bool noKeys = player.ShowKeys == ShowKeys_Disabled
	 || player.ShowKeys == ShowKeys_Spectating && player.Alive;
	return noTimerText && noSpeedText && noKeys;
}

static char[] GetInfoPanel(KZPlayer player, KZPlayer targetPlayer)
{
	char infoPanelText[320];
	FormatEx(infoPanelText, sizeof(infoPanelText), 
		"<font color='#ffffff08'>%s%s%s", 
		GetTimeString(player, targetPlayer), 
		GetSpeedString(player, targetPlayer), 
		GetKeysString(player, targetPlayer));
	TrimString(infoPanelText);
	return infoPanelText;
}

static char[] GetTimeString(KZPlayer player, KZPlayer targetPlayer)
{
	char timeString[128];
	if (player.TimerText != TimerText_InfoPanel)
	{
		timeString = "";
	}
	else if (targetPlayer.TimerRunning)
	{
		switch (targetPlayer.TimeType)
		{
			case TimeType_Nub:
			{
				FormatEx(timeString, sizeof(timeString), 
					"%T: <font color='#ead18a'>%s</font> %s\n", 
					"Info Panel Text - Time", player.ID, 
					GOKZ_HUD_FormatTime(player.ID, targetPlayer.Time), 
					GetPausedString(player, targetPlayer));
			}
			case TimeType_Pro:
			{
				FormatEx(timeString, sizeof(timeString), 
					"%T: <font color='#b5d4ee'>%s</font> %s\n", 
					"Info Panel Text - Time", player.ID, 
					GOKZ_HUD_FormatTime(player.ID, targetPlayer.Time), 
					GetPausedString(player, targetPlayer));
			}
		}
	}
	else
	{
		FormatEx(timeString, sizeof(timeString), 
			"%T: <font color='#ea4141'>%T</font> %s\n", 
			"Info Panel Text - Time", player.ID, 
			"Info Panel Text - Stopped", player.ID, 
			GetPausedString(player, targetPlayer));
	}
	return timeString;
}

static char[] GetPausedString(KZPlayer player, KZPlayer targetPlayer)
{
	char pausedString[64];
	if (targetPlayer.Paused)
	{
		FormatEx(pausedString, sizeof(pausedString), 
			"(<font color='#ffffff'>%T</font>)", 
			"Info Panel Text - PAUSED", player.ID);
	}
	else
	{
		pausedString = "";
	}
	return pausedString;
}

static char[] GetSpeedString(KZPlayer player, KZPlayer targetPlayer)
{
	char speedString[128];
	if (player.SpeedText != SpeedText_InfoPanel || targetPlayer.Paused)
	{
		speedString = "";
	}
	else
	{
		if (targetPlayer.OnGround || targetPlayer.OnLadder || targetPlayer.Noclipping)
		{
			FormatEx(speedString, sizeof(speedString), 
				"%T: <font color='#ffffff'>%.0f</font> u/s\n", 
				"Info Panel Text - Speed", player.ID, 
				RoundToPowerOfTen(targetPlayer.Speed, -2));
			infoPanelShowDuckString[targetPlayer.ID] = false;
		}
		else
		{
			FormatEx(speedString, sizeof(speedString), 
				"%T: <font color='#ffffff'>%.0f</font> %s\n", 
				"Info Panel Text - Speed", player.ID, 
				RoundToPowerOfTen(targetPlayer.Speed, -2), 
				GetTakeoffString(targetPlayer));
		}
	}
	return speedString;
}

static char[] GetTakeoffString(KZPlayer targetPlayer)
{
	char takeoffString[96], duckString[32];
	
	// The last line disables the crouch indicator for bhops
	if ((infoPanelShowDuckString[targetPlayer.ID]
			 || (infoPanelOnGroundLast[targetPlayer.ID]
				 && (infoPanelDuckPressedLast[targetPlayer.ID] || (GOKZ_GetCoreOption(targetPlayer.ID, Option_Mode) == Mode_Vanilla && Movement_GetDucking(targetPlayer.ID)))))
		 && Movement_GetTakeoffCmdNum(targetPlayer.ID) - Movement_GetLandingCmdNum(targetPlayer.ID) > HUD_MAX_BHOP_GROUND_TICKS
		 && targetPlayer.Jumped)
	{
		duckString = " <font color='#71eeb8'>C</font>";
		infoPanelShowDuckString[targetPlayer.ID] = true;
	}
	else
	{
		duckString = "";
		infoPanelShowDuckString[targetPlayer.ID] = false;
	}
	
	if (targetPlayer.GOKZHitPerf)
	{
		FormatEx(takeoffString, sizeof(takeoffString), 
			"(<font color='#40ff40'>%.0f</font>)%s", 
			RoundToPowerOfTen(targetPlayer.GOKZTakeoffSpeed, -2), 
			duckString);
	}
	else
	{
		FormatEx(takeoffString, sizeof(takeoffString), 
			"(<font color='#ffffff'>%.0f</font>)%s", 
			RoundToPowerOfTen(targetPlayer.GOKZTakeoffSpeed, -2), 
			duckString);
	}
	return takeoffString;
}

static char[] GetKeysString(KZPlayer player, KZPlayer targetPlayer)
{
	char keysString[64];
	if (player.ShowKeys == ShowKeys_Disabled)
	{
		keysString = "";
	}
	else if (player.ShowKeys == ShowKeys_Spectating && player.Alive)
	{
		keysString = "";
	}
	else
	{
		int buttons = targetPlayer.Buttons;
		FormatEx(keysString, sizeof(keysString), 
			"%T: <font color='#ffffff'>%c %c %c %c %c %c</font>\n", 
			"Info Panel Text - Keys", player.ID, 
			buttons & IN_MOVELEFT ? 'A' : '_', 
			buttons & IN_FORWARD ? 'W' : '_', 
			buttons & IN_BACK ? 'S' : '_', 
			buttons & IN_MOVERIGHT ? 'D' : '_', 
			buttons & IN_DUCK ? 'C' : '_', 
			buttons & IN_JUMP ? 'J' : '_');
	}
	return keysString;
}
