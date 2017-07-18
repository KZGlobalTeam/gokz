/*
	Information Panel
	
	Centre information panel (hint text).
*/



// =========================  PUBLIC  ========================= //

void UpdateInfoPanel(int client)
{
	KZPlayer player = new KZPlayer(client);
	
	if (player.fake
		 || player.showingInfoPanel == ShowingInfoPanel_Disabled
		 || NothingEnabledInInfoPanel(player))
	{
		return;
	}
	
	if (player.alive)
	{
		PrintHintText(player.id, "%s", GetInfoPanel(player, player));
	}
	else
	{
		KZPlayer targetPlayer = new KZPlayer(player.observerTarget);
		if (targetPlayer.id != -1)
		{
			PrintHintText(player.id, "%s", GetInfoPanel(player, targetPlayer));
		}
	}
}



// =========================  LISTENERS  ========================= //

void OnPlayerRunCmd_InfoPanel(int client, int tickcount)
{
	if ((tickcount + client) % 12 == 0)
	{
		UpdateInfoPanel(client);
	}
}



// =========================  PRIVATE  ========================= //

static bool NothingEnabledInInfoPanel(KZPlayer player)
{
	bool noTimerText = player.timerText != TimerText_InfoPanel;
	bool noSpeedText = player.speedText != SpeedText_InfoPanel || player.paused;
	bool noKeys = player.showingKeys == ShowingKeys_Disabled
	 || player.showingKeys == ShowingKeys_Spectating && player.alive;
	return noTimerText && noSpeedText && noKeys;
}

static char[] GetInfoPanel(KZPlayer player, KZPlayer targetPlayer)
{
	char infoPanelText[320];
	FormatEx(infoPanelText, sizeof(infoPanelText), 
		"<font color='#4d4d4d'>%s%s%s", 
		GetTimeString(player, targetPlayer), 
		GetSpeedString(player, targetPlayer), 
		GetKeysString(player, targetPlayer));
	return infoPanelText;
}

static char[] GetTimeString(KZPlayer player, KZPlayer targetPlayer)
{
	char timeString[128];
	if (player.timerText != TimerText_InfoPanel)
	{
		timeString = "";
	}
	else if (targetPlayer.timerRunning)
	{
		switch (GetCurrentTimeType(targetPlayer.id))
		{
			case TimeType_Nub:
			{
				FormatEx(timeString, sizeof(timeString), 
					" <b>%T</b>: <font color='#ffdd99'>%s</font> %s\n", 
					"Info Panel Text - Time", player.id, 
					GOKZ_FormatTime(targetPlayer.currentTime, false), 
					GetPausedString(player, targetPlayer));
			}
			case TimeType_Pro:
			{
				FormatEx(timeString, sizeof(timeString), 
					" <b>%T</b>: <font color='#6699ff'>%s</font> %s\n", 
					"Info Panel Text - Time", player.id, 
					GOKZ_FormatTime(targetPlayer.currentTime, false), 
					GetPausedString(player, targetPlayer));
			}
		}
	}
	else
	{
		FormatEx(timeString, sizeof(timeString), 
			" <b>%T</b>: %T %s\n", 
			"Info Panel Text - Time", player.id, 
			"Info Panel Text - Stopped", player.id, 
			GetPausedString(player, targetPlayer));
	}
	return timeString;
}

static char[] GetPausedString(KZPlayer player, KZPlayer targetPlayer)
{
	char pausedString[64];
	if (targetPlayer.paused)
	{
		FormatEx(pausedString, sizeof(pausedString), 
			"(<font color='#999999'>%T</font>)", 
			"Info Panel Text - PAUSED", player.id);
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
	if (player.speedText != SpeedText_InfoPanel || targetPlayer.paused)
	{
		speedString = "";
	}
	else
	{
		if (targetPlayer.onGround || targetPlayer.onLadder || targetPlayer.noclipping)
		{
			FormatEx(speedString, sizeof(speedString), 
				" <b>%T</b>: <font color='#999999'>%.0f</font> u/s\n", 
				"Info Panel Text - Speed", player.id, 
				RoundFloat(targetPlayer.speed * 10) / 10.0);
		}
		else
		{
			FormatEx(speedString, sizeof(speedString), 
				" <b>%T</b>: <font color='#999999'>%.0f</font> %s\n", 
				"Info Panel Text - Speed", player.id, 
				RoundFloat(targetPlayer.speed * 10) / 10.0, 
				GetTakeoffString(targetPlayer));
		}
	}
	return speedString;
}

static char[] GetTakeoffString(KZPlayer targetPlayer)
{
	char takeoffString[64];
	if (targetPlayer.gokzHitPerf)
	{
		FormatEx(takeoffString, sizeof(takeoffString), 
			"(<font color='#03cc00'>%.0f</font>)", 
			RoundFloat(targetPlayer.gokzTakeoffSpeed * 10) / 10.0);
	}
	else
	{
		FormatEx(takeoffString, sizeof(takeoffString), 
			"(<font color='#999999'>%.0f</font>)", 
			RoundFloat(targetPlayer.gokzTakeoffSpeed * 10) / 10.0);
	}
	return takeoffString;
}

static char[] GetKeysString(KZPlayer player, KZPlayer targetPlayer)
{
	char keysString[64];
	if (player.showingKeys == ShowingKeys_Disabled)
	{
		keysString = "";
	}
	else if (player.showingKeys == ShowingKeys_Spectating && player.alive)
	{
		keysString = "";
	}
	else
	{
		FormatEx(keysString, sizeof(keysString), 
			" <b>%T</b>: <font color='#999999'>%c %c %c %c   %c %c</font>\n", 
			"Info Panel Text - Keys", player.id, 
			GetAString(targetPlayer), 
			GetWString(targetPlayer), 
			GetSString(targetPlayer), 
			GetDString(targetPlayer), 
			GetCrouchString(targetPlayer), 
			GetJumpString(targetPlayer));
	}
	return keysString;
}

static int GetWString(KZPlayer targetPlayer)
{
	if (targetPlayer.buttons & IN_FORWARD)
	{
		return 'W';
	}
	return '_';
}

static int GetAString(KZPlayer targetPlayer)
{
	if (targetPlayer.buttons & IN_MOVELEFT)
	{
		return 'A';
	}
	return '_';
}

static int GetSString(KZPlayer targetPlayer)
{
	if (targetPlayer.buttons & IN_BACK)
	{
		return 'S';
	}
	return '_';
}

static int GetDString(KZPlayer targetPlayer)
{
	if (targetPlayer.buttons & IN_MOVERIGHT)
	{
		return 'D';
	}
	return '_';
}

static int GetCrouchString(KZPlayer targetPlayer)
{
	if (targetPlayer.buttons & IN_DUCK)
	{
		return 'C';
	}
	return '_';
}

static int GetJumpString(KZPlayer targetPlayer)
{
	if (targetPlayer.buttons & IN_JUMP)
	{
		return 'J';
	}
	return '_';
} 