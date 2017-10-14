/*
	Commands
	
	Commands for player and admin use.
*/



static char radioCommands[][] = 
{
	"coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", 
	"fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", 
	"needbackup", "sectorclear", "inposition", "reportingin", "getout", "negative", 
	"enemydown", "compliment", "thanks", "cheer"
};



// =========================  PUBLIC  ========================= //

void CreateCommands()
{
	RegConsoleCmd("sm_menu", CommandMenu, "[KZ] Toggle the simple teleport menu.");
	RegConsoleCmd("sm_adv", CommandToggleAdvancedMenu, "[KZ] Toggle the advanced teleport menu.");
	RegConsoleCmd("sm_checkpoint", CommandMakeCheckpoint, "[KZ] Set a checkpoint.");
	RegConsoleCmd("sm_gocheck", CommandTeleportToCheckpoint, "[KZ] Teleport to your current checkpoint.");
	RegConsoleCmd("sm_prev", CommandPrevCheckpoint, "[KZ] Go back a checkpoint.");
	RegConsoleCmd("sm_next", CommandNextCheckpoint, "[KZ] Go forward a checkpoint.");
	RegConsoleCmd("sm_undo", CommandUndoTeleport, "[KZ] Undo teleport.");
	RegConsoleCmd("sm_start", CommandTeleportToStart, "[KZ] Teleport to the start of the map.");
	RegConsoleCmd("sm_restart", CommandTeleportToStart, "[KZ] Teleport to the start of the map.");
	RegConsoleCmd("sm_r", CommandTeleportToStart, "[KZ] Teleport to the start of the map.");
	RegConsoleCmd("sm_setstartpos", CommandSetStartPos, "[KZ] Set your current position as your custom start position.");
	RegConsoleCmd("sm_ssp", CommandSetStartPos, "[KZ] Set your current position as your custom start position.");
	RegConsoleCmd("sm_clearstartpos", CommandClearStartPos, "[KZ] Clear your custom start position.");
	RegConsoleCmd("sm_csp", CommandClearStartPos, "[KZ] Clear your custom start position.");
	RegConsoleCmd("sm_pause", CommandTogglePause, "[KZ] Toggle pausing your timer and stopping you in your position.");
	RegConsoleCmd("sm_resume", CommandTogglePause, "[KZ] Toggle pausing your timer and stopping you in your position.");
	RegConsoleCmd("sm_stop", CommandStopTimer, "[KZ] Stop your timer.");
	RegConsoleCmd("sm_stopsound", CommandStopSound, "[KZ] Stop all sounds e.g. map soundscapes (music).");
	RegConsoleCmd("sm_goto", CommandGoto, "[KZ] Teleport to another player. Usage: !goto <player>");
	RegConsoleCmd("sm_spec", CommandSpec, "[KZ] Spectate another player. Usage: !spec <player>");
	RegConsoleCmd("sm_specs", CommandSpecs, "[KZ] List currently spectating players in chat.");
	RegConsoleCmd("sm_speclist", CommandSpecs, "[KZ] List currently spectating players in chat.");
	RegConsoleCmd("sm_options", CommandOptions, "[KZ] Open up the options menu.");
	RegConsoleCmd("sm_hide", CommandToggleShowPlayers, "[KZ] Toggle hiding other players.");
	RegConsoleCmd("sm_panel", CommandToggleInfoPanel, "[KZ] Toggle visibility of the centre information panel.");
	RegConsoleCmd("sm_speed", CommandToggleSpeed, "[KZ] Toggle visibility of your speed and jump pre-speed.");
	RegConsoleCmd("sm_hideweapon", CommandToggleShowWeapon, "[KZ] Toggle visibility of your weapon.");
	RegConsoleCmd("sm_measure", CommandMeasureMenu, "[KZ] Open the measurement menu.");
	RegConsoleCmd("sm_pistol", CommandPistolMenu, "[KZ] Open the pistol selection menu.");
	RegConsoleCmd("sm_nc", CommandToggleNoclip, "[KZ] Toggle noclip.");
	RegConsoleCmd("+noclip", CommandEnableNoclip, "[KZ] Noclip on.");
	RegConsoleCmd("-noclip", CommandDisableNoclip, "[KZ] Noclip off.");
	RegConsoleCmd("sm_mode", CommandMode, "[KZ] Open the movement mode selection menu.");
	RegConsoleCmd("sm_vanilla", CommandVanilla, "[KZ] Switch to the Vanilla mode.");
	RegConsoleCmd("sm_vnl", CommandVanilla, "[KZ] Switch to the Vanilla mode.");
	RegConsoleCmd("sm_v", CommandVanilla, "[KZ] Switch to the Vanilla mode.");
	RegConsoleCmd("sm_simplekz", CommandSimpleKZ, "[KZ] Switch to the SimpleKZ mode.");
	RegConsoleCmd("sm_skz", CommandSimpleKZ, "[KZ] Switch to the SimpleKZ mode.");
	RegConsoleCmd("sm_s", CommandSimpleKZ, "[KZ] Switch to the SimpleKZ mode.");
	RegConsoleCmd("sm_kztimer", CommandKZTimer, "[KZ] Switch to the KZTimer mode.");
	RegConsoleCmd("sm_kzt", CommandKZTimer, "[KZ] Switch to the KZTimer mode.");
	RegConsoleCmd("sm_k", CommandKZTimer, "[KZ] Switch to the KZTimer mode.");
}

void CreateCommandListeners()
{
	AddCommandListener(CommandJoinTeam, "jointeam");
	for (int i = 0; i < sizeof(radioCommands); i++)
	{
		AddCommandListener(CommandBlock, radioCommands[i]);
	}
}



// =========================  COMMAND HANDLERS  ========================= //

public Action CommandBlock(int client, const char[] command, int argc)
{
	return Plugin_Handled;
}

public Action CommandJoinTeam(int client, const char[] command, int argc)
{
	char teamString[4];
	GetCmdArgString(teamString, sizeof(teamString));
	int team = StringToInt(teamString);
	JoinTeam(client, team);
	return Plugin_Handled;
}

public Action CommandMenu(int client, int args)
{
	if (GOKZ_GetOption(client, Option_ShowingTPMenu) != ShowingTPMenu_Disabled)
	{
		GOKZ_SetOption(client, Option_ShowingTPMenu, ShowingTPMenu_Disabled, true);
	}
	else
	{
		GOKZ_SetOption(client, Option_ShowingTPMenu, ShowingTPMenu_Simple, true);
	}
	return Plugin_Handled;
}

public Action CommandToggleAdvancedMenu(int client, int args)
{
	if (GOKZ_GetOption(client, Option_ShowingTPMenu) != ShowingTPMenu_Advanced)
	{
		GOKZ_SetOption(client, Option_ShowingTPMenu, ShowingTPMenu_Advanced, true);
	}
	else
	{
		GOKZ_SetOption(client, Option_ShowingTPMenu, ShowingTPMenu_Simple, true);
	}
	return Plugin_Handled;
}

public Action CommandMakeCheckpoint(int client, int args)
{
	GOKZ_MakeCheckpoint(client);
	UpdateTPMenu(client);
	return Plugin_Handled;
}

public Action CommandTeleportToCheckpoint(int client, int args)
{
	GOKZ_TeleportToCheckpoint(client);
	UpdateTPMenu(client);
	return Plugin_Handled;
}

public Action CommandPrevCheckpoint(int client, int args)
{
	GOKZ_PrevCheckpoint(client);
	UpdateTPMenu(client);
	return Plugin_Handled;
}

public Action CommandNextCheckpoint(int client, int args)
{
	GOKZ_NextCheckpoint(client);
	UpdateTPMenu(client);
	return Plugin_Handled;
}

public Action CommandUndoTeleport(int client, int args)
{
	GOKZ_UndoTeleport(client);
	UpdateTPMenu(client);
	return Plugin_Handled;
}

public Action CommandTeleportToStart(int client, int args)
{
	GOKZ_TeleportToStart(client);
	UpdateTPMenu(client);
	return Plugin_Handled;
}

public Action CommandSetStartPos(int client, int args)
{
	SetCustomStartPosition(client);
	UpdateTPMenu(client);
	return Plugin_Handled;
}

public Action CommandClearStartPos(int client, int args)
{
	ClearCustomStartPosition(client);
	UpdateTPMenu(client);
	return Plugin_Handled;
}

public Action CommandTogglePause(int client, int args)
{
	if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
	{
		JoinTeam(client, CS_TEAM_CT);
	}
	else
	{
		TogglePause(client);
	}
	UpdateTPMenu(client);
	return Plugin_Handled;
}

public Action CommandStopTimer(int client, int args)
{
	if (TimerStop(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Time Stopped");
	}
	return Plugin_Handled;
}

public Action CommandStopSound(int client, int args)
{
	StopSounds(client);
	return Plugin_Handled;
}

public Action CommandGoto(int client, int args)
{
	// If no arguments, display the goto menu
	if (args < 1)
	{
		DisplayGotoMenu(client);
	}
	// Otherwise try to teleport to the specified player
	else
	{
		char specifiedPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, specifiedPlayer, sizeof(specifiedPlayer));
		
		int target = FindTarget(client, specifiedPlayer, false, false);
		if (target != -1)
		{
			GotoPlayer(client, target);
		}
	}
	return Plugin_Handled;
}

public Action CommandSpec(int client, int args)
{
	// If no arguments, display the spec menu
	if (args < 1)
	{
		DisplaySpecMenu(client);
	}
	// Otherwise try to spectate the player
	else
	{
		char specifiedPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, specifiedPlayer, sizeof(specifiedPlayer));
		
		int target = FindTarget(client, specifiedPlayer, false, false);
		if (target != -1)
		{
			SpectatePlayer(client, target);
		}
	}
	return Plugin_Handled;
}

public Action CommandSpecs(int client, int args)
{
	int specs = 0;
	char specNames[1024];
	
	int target = IsPlayerAlive(client) ? client : GetObserverTarget(client);
	int targetSpecs = 0;
	char targetSpecNames[1024];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_SPECTATOR)
		{
			specs++;
			if (specs == 1)
			{
				FormatEx(specNames, sizeof(specNames), "{lime}%N", i);
			}
			else
			{
				Format(specNames, sizeof(specNames), "%s{grey}, {lime}%N", specNames, i);
			}
			
			if (target != -1 && GetObserverTarget(i) == target)
			{
				targetSpecs++;
				if (targetSpecs == 1)
				{
					FormatEx(targetSpecNames, sizeof(targetSpecNames), "{lime}%N", i);
				}
				else
				{
					Format(targetSpecNames, sizeof(targetSpecNames), "%s{grey}, {lime}%N", targetSpecNames, i);
				}
			}
		}
	}
	
	if (specs == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Spectator List (None)");
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "Spectator List", specs, specNames);
		if (targetSpecs == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "Target Spectator List (None)", target);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Target Spectator List", target, targetSpecs, targetSpecNames);
		}
	}
}

public Action CommandOptions(int client, int args)
{
	DisplayOptionsMenu(client);
	return Plugin_Handled;
}

public Action CommandToggleShowPlayers(int client, int args)
{
	CycleOption(client, Option_ShowingPlayers, true);
	return Plugin_Handled;
}

public Action CommandToggleInfoPanel(int client, int args)
{
	CycleOption(client, Option_ShowingInfoPanel, true);
	return Plugin_Handled;
}

public Action CommandToggleSpeed(int client, int args)
{
	int speedText = GOKZ_GetOption(client, Option_SpeedText);
	int infoPanel = GOKZ_GetOption(client, Option_ShowingInfoPanel);
	
	if (speedText == SpeedText_Disabled)
	{
		if (infoPanel == ShowingInfoPanel_Enabled)
		{
			GOKZ_SetOption(client, Option_SpeedText, SpeedText_InfoPanel, true);
		}
		else
		{
			GOKZ_SetOption(client, Option_SpeedText, SpeedText_Bottom, true);
		}
	}
	else if (infoPanel == ShowingInfoPanel_Disabled && speedText == SpeedText_InfoPanel)
	{
		GOKZ_SetOption(client, Option_SpeedText, SpeedText_Bottom, true);
	}
	else
	{
		GOKZ_SetOption(client, Option_SpeedText, SpeedText_Disabled, true);
	}
	return Plugin_Handled;
}

public Action CommandToggleShowWeapon(int client, int args)
{
	CycleOption(client, Option_ShowingWeapon, true);
	return Plugin_Handled;
}

public Action CommandMeasureMenu(int client, int args)
{
	DisplayMeasureMenu(client);
	return Plugin_Handled;
}

public Action CommandPistolMenu(int client, int args)
{
	DisplayPistolMenu(client);
	return Plugin_Handled;
}

public Action CommandToggleNoclip(int client, int args)
{
	ToggleNoclip(client);
	return Plugin_Handled;
}

public Action CommandEnableNoclip(int client, int args)
{
	Movement_SetMoveType(client, MOVETYPE_NOCLIP);
	return Plugin_Handled;
}

public Action CommandDisableNoclip(int client, int args)
{
	Movement_SetMoveType(client, MOVETYPE_WALK);
	return Plugin_Handled;
}

public Action CommandMode(int client, int args)
{
	DisplayModeMenu(client);
	return Plugin_Handled;
}

public Action CommandVanilla(int client, int args)
{
	SwitchToModeIfAvailable(client, Mode_Vanilla);
	return Plugin_Handled;
}

public Action CommandSimpleKZ(int client, int args)
{
	SwitchToModeIfAvailable(client, Mode_SimpleKZ);
	return Plugin_Handled;
}

public Action CommandKZTimer(int client, int args)
{
	SwitchToModeIfAvailable(client, Mode_KZTimer);
	return Plugin_Handled;
}



// =========================  PRIVATE  ========================= //

static void SwitchToModeIfAvailable(int client, int mode)
{
	if (!GOKZ_GetModeLoaded(mode))
	{
		GOKZ_PrintToChat(client, true, "%t", "Mode Not Available", gC_ModeNames[mode]);
	}
	else
	{
		SetOption(client, Option_Mode, mode, true);
	}
} 