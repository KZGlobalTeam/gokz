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

void OnPlayerRunCmdPost_InfoPanel(int client, int cmdnum, HUDInfo info)
{
	int updateSpeed = 10;
	if (gB_FastUpdateRate[client])
	{
		// The hint text panel update speed depends on the client ping.
		// To optimize resource usage, we scale the update speed with it.
		// The fastest speed the client can get is around once every 2 ticks.
		updateSpeed = RoundToFloor(GetClientAvgLatency(client, NetFlow_Outgoing) / GetTickInterval());
	}
	if (cmdnum % updateSpeed == 0 || info.IsTakeoff)
	{
		UpdateInfoPanel(client, info);
	}
	infoPanelOnGroundLast[info.ID] = info.OnGround;
	infoPanelDuckPressedLast[info.ID] = info.Ducking;
}



// =====[ PRIVATE ]=====

static void UpdateInfoPanel(int client, HUDInfo info)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.Fake || !IsDrawingInfoPanel(player.ID))
	{
		return;
	}
	
	PrintCSGOHUDText(player.ID, GetInfoPanel(player, info));
}

static bool NothingEnabledInInfoPanel(KZPlayer player)
{
	bool noTimerText = player.TimerText != TimerText_InfoPanel;
	bool noSpeedText = player.SpeedText != SpeedText_InfoPanel || player.Paused;
	bool noKeys = player.ShowKeys == ShowKeys_Disabled
	 || player.ShowKeys == ShowKeys_Spectating && player.Alive;
	return noTimerText && noSpeedText && noKeys;
}

static char[] GetInfoPanel(KZPlayer player, HUDInfo info)
{
	char infoPanelText[320];
	FormatEx(infoPanelText, sizeof(infoPanelText), 
		"<font color='#ffffff08'>%s%s%s", 
		GetTimeString(player, info), 
		GetSpeedString(player, info), 
		GetKeysString(player, info));
	TrimString(infoPanelText);
	return infoPanelText;
}

static char[] GetTimeString(KZPlayer player, HUDInfo info)
{
	char timeString[128];
	if (player.TimerText != TimerText_InfoPanel)
	{
		timeString = "";
	}
	else if (info.TimerRunning)
	{
		if (player.GetHUDOption(HUDOption_TimerType) == TimerType_Enabled)
		{
			switch (info.TimeType)
			{
				case TimeType_Nub:
				{
					FormatEx(timeString, sizeof(timeString), 
						"%T: <font color='#ead18a'>%s</font> %s\n", 
						"Info Panel Text - Time", player.ID, 
						GOKZ_HUD_FormatTime(player.ID, info.Time), 
						GetPausedString(player, info));
				}
				case TimeType_Pro:
				{
					FormatEx(timeString, sizeof(timeString), 
						"%T: <font color='#b5d4ee'>%s</font> %s\n", 
						"Info Panel Text - Time", player.ID, 
						GOKZ_HUD_FormatTime(player.ID, info.Time), 
						GetPausedString(player, info));
				}
			}
		}
		else 
		{
			FormatEx(timeString, sizeof(timeString), 
				"%T: <font color='#ffffff'>%s</font> %s\n", 
				"Info Panel Text - Time", player.ID, 
				GOKZ_HUD_FormatTime(player.ID, info.Time), 
				GetPausedString(player, info));
		}
	}
	else
	{
		FormatEx(timeString, sizeof(timeString), 
			"%T: <font color='#ea4141'>%T</font> %s\n", 
			"Info Panel Text - Time", player.ID, 
			"Info Panel Text - Stopped", player.ID, 
			GetPausedString(player, info));
	}
	return timeString;
}

static char[] GetPausedString(KZPlayer player, HUDInfo info)
{
	char pausedString[64];
	if (info.Paused)
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

static char[] GetSpeedString(KZPlayer player, HUDInfo info)
{
	char speedString[128];
	if (player.SpeedText != SpeedText_InfoPanel || info.Paused)
	{
		speedString = "";
	}
	else
	{
		if (info.OnGround || info.OnLadder || info.Noclipping)
		{
			FormatEx(speedString, sizeof(speedString), 
				"%T: <font color='#ffffff'>%.0f</font> u/s\n", 
				"Info Panel Text - Speed", player.ID, 
				RoundToPowerOfTen(info.Speed, -2));
			infoPanelShowDuckString[info.ID] = false;
		}
		else
		{
			if (GOKZ_HUD_GetOption(player.ID, HUDOption_DeadstrafeColor) == DeadstrafeColor_Enabled
			&& Movement_GetVerticalVelocity(info.ID) > 0.0 && Movement_GetVerticalVelocity(info.ID) < 140.0)
			{
				FormatEx(speedString, sizeof(speedString), 
					"%T: <font color='#ff2020'>%.0f</font> %s\n", 
					"Info Panel Text - Speed", player.ID, 
					RoundToPowerOfTen(info.Speed, -2), 
					GetTakeoffString(info));
			}
			else
			{
				FormatEx(speedString, sizeof(speedString), 
					"%T: <font color='#ffffff'>%.0f</font> %s\n", 
					"Info Panel Text - Speed", player.ID, 
					RoundToPowerOfTen(info.Speed, -2), 
					GetTakeoffString(info));
			}
		}
	}
	return speedString;
}

static char[] GetTakeoffString(HUDInfo info)
{
	char takeoffString[96], duckString[32];
	
	if (infoPanelShowDuckString[info.ID]
		|| (infoPanelOnGroundLast[info.ID]
			&& !info.HitBhop 
			&& info.IsTakeoff
			&& info.Jumped
			&& info.Ducking
			&& (infoPanelDuckPressedLast[info.ID] || GOKZ_GetCoreOption(info.ID, Option_Mode) == Mode_Vanilla)))
	{
		duckString = " <font color='#71eeb8'>C</font>";
		infoPanelShowDuckString[info.ID] = true;
	}
	else
	{
		duckString = "";
		infoPanelShowDuckString[info.ID] = false;
	}

	if (info.HitJB)
	{
		FormatEx(takeoffString, sizeof(takeoffString), 
			"(<font color='#ffff20'>%.0f</font>)%s", 
			RoundToPowerOfTen(info.TakeoffSpeed, -2), 
			duckString);
	}
	else if (info.HitPerf)
	{
		FormatEx(takeoffString, sizeof(takeoffString), 
			"(<font color='#40ff40'>%.0f</font>)%s", 
			RoundToPowerOfTen(info.TakeoffSpeed, -2), 
			duckString);
	}
	else
	{
		FormatEx(takeoffString, sizeof(takeoffString), 
			"(<font color='#ffffff'>%.0f</font>)%s", 
			RoundToPowerOfTen(info.TakeoffSpeed, -2), 
			duckString);
	}
	return takeoffString;
}

static char[] GetKeysString(KZPlayer player, HUDInfo info)
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
		int buttons = info.Buttons;
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

// Credits to Franc1sco (https://github.com/Franc1sco/FixHintColorMessages)
void PrintCSGOHUDText(int client, const char[] format)
{
	char buff[HUD_MAX_HINT_SIZE];
	Format(buff, sizeof(buff), "</font>%s", format);

	for (int i = strlen(buff); i < sizeof(buff) - 1; i++)
	{
		buff[i] = ' ';
	}

	buff[sizeof(buff) - 1] = '\0';

	Protobuf pb = view_as<Protobuf>(StartMessageOne("TextMsg", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS));
	pb.SetInt("msg_dst", 4);
	pb.AddString("params", "#SFUI_ContractKillStart");
	pb.AddString("params", buff);
	pb.AddString("params", NULL_STRING);
	pb.AddString("params", NULL_STRING);
	pb.AddString("params", NULL_STRING);
	pb.AddString("params", NULL_STRING);

	EndMessage();
}