/*
	Options
	
	Player options to customise their experience.
*/



static int options[OPTION_COUNT][MAXPLAYERS + 1];

static int optionCounts[OPTION_COUNT] = 
{
	MODE_COUNT, 
	STYLE_COUNT, 
	SHOWINGTPMENU_COUNT, 
	SHOWINGINFOPANEL_COUNT, 
	SHOWINGKEYS_COUNT, 
	SHOWINGPLAYERS_COUNT, 
	SHOWINGWEAPON_COUNT, 
	AUTORESTART_COUNT, 
	SLAYONEND_COUNT, 
	PISTOL_COUNT, 
	CHECKPOINTMESSAGES_COUNT, 
	CHECKPOINTSOUNDS_COUNT, 
	TELEPORTSOUNDS_COUNT, 
	ERRORSOUNDS_COUNT, 
	TIMERTEXT_COUNT, 
	SPEEDTEXT_COUNT, 
	JUMPBEAM_COUNT
};



// =========================  PUBLIC  ========================= //

int GetOption(int client, Option option)
{
	return options[option][client];
}

void SetOption(int client, Option option, int optionValue, bool printMessage = false)
{
	if (GetOption(client, option) == optionValue)
	{
		return;
	}
	
	if (option == Option_Mode && !GetModeLoaded(optionValue))
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Mode Not Available", optionValue);
		}
		SetToLoadedMode(client, printMessage);
	}
	
	options[option][client] = optionValue;
	if (printMessage)
	{
		PrintOptionChangeMessage(client, option);
	}
	
	Call_GOKZ_OnOptionChanged(client, option, optionValue);
}

void CycleOption(int client, Option option, bool printMessage = false)
{
	SetOption(client, option, (GetOption(client, option) + 1) % optionCounts[option], printMessage);
}



// =========================  LISTENERS  ========================= //

void SetupClientOptions(int client)
{
	SetDefaultOptions(client);
}



// =========================  PRIVATE  ========================= //

static void SetDefaultOptions(int client)
{
	SetOption(client, Option_Mode, GetConVarInt(gCV_DefaultMode));
	SetOption(client, Option_Style, Style_Normal);
	SetOption(client, Option_ShowingTPMenu, ShowingTPMenu_Enabled);
	SetOption(client, Option_ShowingInfoPanel, ShowingInfoPanel_Enabled);
	SetOption(client, Option_ShowingKeys, ShowingKeys_Spectating);
	SetOption(client, Option_ShowingPlayers, ShowingPlayers_Enabled);
	SetOption(client, Option_ShowingWeapon, ShowingWeapon_Enabled);
	SetOption(client, Option_AutoRestart, AutoRestart_Disabled);
	SetOption(client, Option_SlayOnEnd, SlayOnEnd_Disabled);
	SetOption(client, Option_Pistol, Pistol_USP);
	SetOption(client, Option_CheckpointMessages, CheckpointMessages_Disabled);
	SetOption(client, Option_CheckpointSounds, CheckpointSounds_Enabled);
	SetOption(client, Option_TeleportSounds, TeleportSounds_Enabled);
	SetOption(client, Option_ErrorSounds, ErrorSounds_Enabled);
	SetOption(client, Option_TimerText, TimerText_InfoPanel);
	SetOption(client, Option_SpeedText, SpeedText_InfoPanel);
	SetOption(client, Option_JumpBeam, JumpBeam_Disabled);
}

// Set client to a mode that is loaded
static void SetToLoadedMode(int client, bool printMessage = false)
{
	// Their mode is already loaded so don't change it
	if (GOKZ_GetModeLoaded(GetOption(client, Option_Mode)))
	{
		return;
	}
	
	// Find a mode that is loaded
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		if (GOKZ_GetModeLoaded(mode))
		{
			SetOption(client, Option_Mode, mode, printMessage);
		}
	}
}

static void PrintOptionChangeMessage(int client, Option option) {
	if (!IsClientInGame(client))
	{
		return;
	}
	
	// NOTE: Not all options have a message for when they are changed.
	switch (option)
	{
		case Option_Mode:
		{
			GOKZ_PrintToChat(client, true, "%t", "Switched Mode", gC_ModeNames[GetOption(client, Option_Mode)]);
		}
		case Option_ShowingTPMenu:
		{
			switch (GetOption(client, option))
			{
				case ShowingTPMenu_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Teleport Menu - Disable");
				}
				case ShowingTPMenu_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Teleport Menu - Enable");
				}
			}
		}
		case Option_ShowingInfoPanel:
		{
			switch (GetOption(client, option))
			{
				case ShowingInfoPanel_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Info Panel - Disable");
				}
				case ShowingInfoPanel_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Info Panel - Enable");
				}
			}
		}
		case Option_ShowingPlayers:
		{
			switch (GetOption(client, option))
			{
				case ShowingPlayers_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Players - Disable");
				}
				case ShowingPlayers_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Players - Enable");
				}
			}
		}
		case Option_ShowingWeapon:
		{
			switch (GetOption(client, option))
			{
				case ShowingWeapon_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Weapon - Disable");
				}
				case ShowingWeapon_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Show Weapon - Enable");
				}
			}
		}
		case Option_AutoRestart:
		{
			switch (GetOption(client, option))
			{
				case AutoRestart_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Auto Restart - Disable");
				}
				case AutoRestart_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Auto Restart - Enable");
				}
			}
		}
		case Option_SlayOnEnd:
		{
			switch (GetOption(client, option))
			{
				case SlayOnEnd_Disabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Slay On End - Disable");
				}
				case SlayOnEnd_Enabled:
				{
					GOKZ_PrintToChat(client, true, "%t", "Option - Slay On End - Enable");
				}
			}
		}
	}
} 